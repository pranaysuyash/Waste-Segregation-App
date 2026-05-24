import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import type { QueryDocumentSnapshot } from 'firebase-admin/firestore';
import { asiaSouth1 } from './helpers';

const ANALYTICS_COLLECTION = 'analytics_events';
const REPORT_COLLECTION = 'family_dashboard_reports';
const SNAPSHOT_EVENT_NAME = 'family_dashboard_snapshot';
const REPORT_VERSION = 1;
const BATCH_SIZE = 500;
const DAILY_RETENTION_DAYS = 90;
const ROLLING_WINDOWS = [7, 28] as const;

type ScopeType = 'global' | 'family';
type ReportType = 'daily' | 'rolling';

interface RawAnalyticsEventDoc {
  id: string;
  userId: string;
  eventName: string;
  timestampMillis: number;
  dayKey: string;
  familyId: string | null;
  dashboardState: string;
  hasFamily: boolean;
  currentUserRole: string | null;
  errorType: string | null;
  familyMemberCount: number | null;
  familyTotalClassifications: number | null;
  familyTotalPoints: number | null;
  familyCurrentStreak: number | null;
}

interface ScopeAccumulator {
  snapshotCount: number;
  loadedSnapshotCount: number;
  noFamilySnapshotCount: number;
  errorSnapshotCount: number;
  uniqueUsers: Set<string>;
  familyIds: Set<string>;
  stateCounts: Record<string, number>;
  roleCounts: Record<string, number>;
  familyMemberCountTotal: number;
  familyMemberCountSamples: number;
  familyTotalClassificationsTotal: number;
  familyTotalClassificationsSamples: number;
  familyTotalPointsTotal: number;
  familyTotalPointsSamples: number;
  familyCurrentStreakTotal: number;
  familyCurrentStreakSamples: number;
  userDayKeys: Map<string, Set<string>>;
  dayKeys: Set<string>;
}

interface AggregationState {
  latestDayKey: string | null;
  globalFamilyIds: Set<string>;
  scopeDayBuckets: Map<string, Map<string, ScopeAccumulator>>;
  scopeUserDays: Map<string, Map<string, Set<string>>>;
  scopeOrder: string[];
}

interface ReportWindow {
  windowDays: number;
  startDayKey: string;
  endDayKey: string;
}

interface FamilyDashboardReportDoc {
  reportVersion: number;
  scopeType: ScopeType;
  familyId: string | null;
  reportType: ReportType;
  windowDays: number;
  reportDate: string | null;
  windowStartDate: string | null;
  windowEndDate: string | null;
  generatedAtIso: string;
  generatedAtMillis: number;
  retentionDays: number;
  activeDays: number;
  snapshotCount: number;
  loadedSnapshotCount: number;
  noFamilySnapshotCount: number;
  errorSnapshotCount: number;
  familyParticipationRate: number;
  uniqueUsers: number;
  returningUsers: number;
  returnRate: number;
  uniqueFamilies: number;
  averageFamilyMemberCount: number;
  averageFamilyTotalClassifications: number;
  averageFamilyTotalPoints: number;
  averageFamilyCurrentStreak: number;
  stateCounts: Record<string, number>;
  roleCounts: Record<string, number>;
}

interface ReportPayload {
  docId: string;
  data: FamilyDashboardReportDoc;
}

const firestore = admin.firestore();

function encodeFamilyId(familyId: string): string {
  return encodeURIComponent(familyId);
}

function buildScopeKey(scopeType: ScopeType, familyId: string | null = null): string {
  return scopeType === 'global' ? 'global' : `family:${encodeFamilyId(familyId ?? '')}`;
}

function parseScopeKey(scopeKey: string): { scopeType: ScopeType; familyId: string | null } {
  if (scopeKey === 'global') {
    return { scopeType: 'global', familyId: null };
  }

  if (!scopeKey.startsWith('family:')) {
    return { scopeType: 'global', familyId: null };
  }

  const encoded = scopeKey.slice('family:'.length);
  return {
    scopeType: 'family',
    familyId: decodeURIComponent(encoded),
  };
}

function buildReportDocId(
  scopeType: ScopeType,
  reportType: ReportType,
  windowDays: number,
  dayKey: string | null = null,
  familyId: string | null = null,
): string {
  const scopePrefix = scopeType === 'global'
    ? 'global'
    : `family__${encodeFamilyId(familyId ?? '')}`;

  if (reportType === 'daily') {
    return `${scopePrefix}__daily__${dayKey ?? 'unknown'}`;
  }

  return `${scopePrefix}__rolling__${windowDays}d`;
}

function createAccumulator(): ScopeAccumulator {
  return {
    snapshotCount: 0,
    loadedSnapshotCount: 0,
    noFamilySnapshotCount: 0,
    errorSnapshotCount: 0,
    uniqueUsers: new Set<string>(),
    familyIds: new Set<string>(),
    stateCounts: {},
    roleCounts: {},
    familyMemberCountTotal: 0,
    familyMemberCountSamples: 0,
    familyTotalClassificationsTotal: 0,
    familyTotalClassificationsSamples: 0,
    familyTotalPointsTotal: 0,
    familyTotalPointsSamples: 0,
    familyCurrentStreakTotal: 0,
    familyCurrentStreakSamples: 0,
    userDayKeys: new Map<string, Set<string>>(),
    dayKeys: new Set<string>(),
  };
}

function getOrCreateDayBucket(
  scopeDayBuckets: Map<string, Map<string, ScopeAccumulator>>,
  scopeKey: string,
  dayKey: string,
): ScopeAccumulator {
  const scopeBucket = scopeDayBuckets.get(scopeKey) ?? new Map<string, ScopeAccumulator>();
  if (!scopeDayBuckets.has(scopeKey)) {
    scopeDayBuckets.set(scopeKey, scopeBucket);
  }

  const dayBucket = scopeBucket.get(dayKey) ?? createAccumulator();
  if (!scopeBucket.has(dayKey)) {
    scopeBucket.set(dayKey, dayBucket);
  }

  return dayBucket;
}

function getOrCreateUserDayMap(
  scopeUserDays: Map<string, Map<string, Set<string>>>,
  scopeKey: string,
): Map<string, Set<string>> {
  const existing = scopeUserDays.get(scopeKey);
  if (existing) {
    return existing;
  }

  const next = new Map<string, Set<string>>();
  scopeUserDays.set(scopeKey, next);
  return next;
}

function addToAccumulator(
  accumulator: ScopeAccumulator,
  event: RawAnalyticsEventDoc,
): void {
  accumulator.snapshotCount += 1;
  accumulator.uniqueUsers.add(event.userId);
  accumulator.dayKeys.add(event.dayKey);
  accumulator.stateCounts[event.dashboardState] =
    (accumulator.stateCounts[event.dashboardState] ?? 0) + 1;

  if (event.currentUserRole) {
    accumulator.roleCounts[event.currentUserRole] =
      (accumulator.roleCounts[event.currentUserRole] ?? 0) + 1;
  }

  if (event.hasFamily && event.familyId) {
    accumulator.loadedSnapshotCount += 1;
    accumulator.familyIds.add(event.familyId);
  } else {
    accumulator.noFamilySnapshotCount += 1;
  }

  if (event.errorType) {
    accumulator.errorSnapshotCount += 1;
  }

  if (event.familyMemberCount != null) {
    accumulator.familyMemberCountTotal += event.familyMemberCount;
    accumulator.familyMemberCountSamples += 1;
  }

  if (event.familyTotalClassifications != null) {
    accumulator.familyTotalClassificationsTotal += event.familyTotalClassifications;
    accumulator.familyTotalClassificationsSamples += 1;
  }

  if (event.familyTotalPoints != null) {
    accumulator.familyTotalPointsTotal += event.familyTotalPoints;
    accumulator.familyTotalPointsSamples += 1;
  }

  if (event.familyCurrentStreak != null) {
    accumulator.familyCurrentStreakTotal += event.familyCurrentStreak;
    accumulator.familyCurrentStreakSamples += 1;
  }
}

function addUserDay(scopeUserDays: Map<string, Map<string, Set<string>>>, scopeKey: string, userId: string, dayKey: string): void {
  const userMap = getOrCreateUserDayMap(scopeUserDays, scopeKey);
  const days = userMap.get(userId) ?? new Set<string>();
  days.add(dayKey);
  userMap.set(userId, days);
}

function parseSnapshotEvent(data: Record<string, unknown>, id: string): RawAnalyticsEventDoc | null {
  if (data.eventName !== SNAPSHOT_EVENT_NAME) {
    return null;
  }

  const userId = typeof data.userId === 'string' ? data.userId : null;
  if (!userId) {
    return null;
  }

  const timestampMillis = resolveTimestampMillis(data);
  if (timestampMillis == null) {
    return null;
  }

  const parameters = data.parameters && typeof data.parameters === 'object'
    ? data.parameters as Record<string, unknown>
    : {};

  const familyId = typeof parameters.family_id === 'string' && parameters.family_id.trim().length > 0
    ? parameters.family_id
    : null;
  const dashboardState = typeof parameters.dashboard_state === 'string'
    ? parameters.dashboard_state
    : 'unknown';
  const currentUserRole = typeof parameters.current_user_role === 'string'
    ? parameters.current_user_role
    : null;
  const errorType = typeof parameters.error_type === 'string'
    ? parameters.error_type
    : null;

  return {
    id,
    userId,
    eventName: SNAPSHOT_EVENT_NAME,
    timestampMillis,
    dayKey: toDayKey(timestampMillis),
    familyId,
    dashboardState,
    hasFamily: Boolean(parameters.has_family),
    currentUserRole,
    errorType,
    familyMemberCount: asNumber(parameters.family_member_count),
    familyTotalClassifications: asNumber(parameters.family_total_classifications),
    familyTotalPoints: asNumber(parameters.family_total_points),
    familyCurrentStreak: asNumber(parameters.family_current_streak),
  };
}

function resolveTimestampMillis(data: Record<string, unknown>): number | null {
  const millis = data.timestampMillis;
  if (typeof millis === 'number' && Number.isFinite(millis)) {
    return millis;
  }

  const timestampUtc = data.timestampUtc;
  if (typeof timestampUtc === 'string') {
    const parsedUtc = Date.parse(timestampUtc);
    if (Number.isFinite(parsedUtc)) {
      return parsedUtc;
    }
  }

  const timestamp = data.timestamp;
  if (typeof timestamp === 'string') {
    const parsed = Date.parse(timestamp);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }

  return null;
}

function asNumber(value: unknown): number | null {
  return typeof value === 'number' && Number.isFinite(value) ? value : null;
}

function toDayKey(timestampMillis: number): string {
  return new Date(timestampMillis).toISOString().slice(0, 10);
}

function compareDayKeys(a: string, b: string): number {
  return a.localeCompare(b);
}

function addDays(dayKey: string, offsetDays: number): string {
  const date = new Date(`${dayKey}T00:00:00.000Z`);
  date.setUTCDate(date.getUTCDate() + offsetDays);
  return date.toISOString().slice(0, 10);
}

function buildWindow(anchorDayKey: string, windowDays: number): ReportWindow {
  const endDayKey = anchorDayKey;
  const startDayKey = addDays(anchorDayKey, -(windowDays - 1));
  return {
    windowDays,
    startDayKey,
    endDayKey,
  };
}

function inWindow(dayKey: string, window: ReportWindow): boolean {
  return compareDayKeys(dayKey, window.startDayKey) >= 0 && compareDayKeys(dayKey, window.endDayKey) <= 0;
}

function mergeAccumulators(accumulators: ScopeAccumulator[]): ScopeAccumulator {
  const merged = createAccumulator();

  for (const accumulator of accumulators) {
    merged.snapshotCount += accumulator.snapshotCount;
    merged.loadedSnapshotCount += accumulator.loadedSnapshotCount;
    merged.noFamilySnapshotCount += accumulator.noFamilySnapshotCount;
    merged.errorSnapshotCount += accumulator.errorSnapshotCount;
    accumulator.uniqueUsers.forEach((userId) => merged.uniqueUsers.add(userId));
    accumulator.familyIds.forEach((familyId) => merged.familyIds.add(familyId));
    accumulator.dayKeys.forEach((dayKey) => merged.dayKeys.add(dayKey));

    for (const [state, count] of Object.entries(accumulator.stateCounts)) {
      merged.stateCounts[state] = (merged.stateCounts[state] ?? 0) + count;
    }

    for (const [role, count] of Object.entries(accumulator.roleCounts)) {
      merged.roleCounts[role] = (merged.roleCounts[role] ?? 0) + count;
    }

    merged.familyMemberCountTotal += accumulator.familyMemberCountTotal;
    merged.familyMemberCountSamples += accumulator.familyMemberCountSamples;
    merged.familyTotalClassificationsTotal += accumulator.familyTotalClassificationsTotal;
    merged.familyTotalClassificationsSamples += accumulator.familyTotalClassificationsSamples;
    merged.familyTotalPointsTotal += accumulator.familyTotalPointsTotal;
    merged.familyTotalPointsSamples += accumulator.familyTotalPointsSamples;
    merged.familyCurrentStreakTotal += accumulator.familyCurrentStreakTotal;
    merged.familyCurrentStreakSamples += accumulator.familyCurrentStreakSamples;
  }

  return merged;
}

function countReturningUsers(userDayMap: Map<string, Set<string>>, window: ReportWindow): number {
  let returningUsers = 0;

  for (const days of userDayMap.values()) {
    let dayCount = 0;
    for (const dayKey of days) {
      if (inWindow(dayKey, window)) {
        dayCount += 1;
        if (dayCount > 1) {
          returningUsers += 1;
          break;
        }
      }
    }
  }

  return returningUsers;
}

function average(total: number, samples: number): number {
  return samples > 0 ? total / samples : 0;
}

function buildReportDoc(
  scopeKey: string,
  reportType: ReportType,
  window: ReportWindow,
  bucketMap: Map<string, ScopeAccumulator>,
  userDayMap: Map<string, Set<string>>,
  globalFamilyIds: Set<string>,
  generatedAt: Date,
): FamilyDashboardReportDoc {
  const { scopeType, familyId } = parseScopeKey(scopeKey);
  const dayKeys = Array.from(bucketMap.entries())
    .filter(([dayKey, bucket]) => window.windowDays === 1
      ? dayKey === window.endDayKey
      : inWindow(dayKey, window) && bucket.snapshotCount > 0)
    .map(([dayKey]) => dayKey)
    .sort(compareDayKeys);

  const selectedBuckets = dayKeys
    .map((dayKey) => bucketMap.get(dayKey))
    .filter((bucket): bucket is ScopeAccumulator => Boolean(bucket));
  const merged = mergeAccumulators(selectedBuckets);

  const snapshotCount = merged.snapshotCount;
  const loadedSnapshotCount = merged.loadedSnapshotCount;
  const noFamilySnapshotCount = scopeType === 'global' ? merged.noFamilySnapshotCount : 0;
  const errorSnapshotCount = merged.errorSnapshotCount;
  const uniqueUsers = merged.uniqueUsers.size;
  const returningUsers = reportType === 'daily' ? 0 : countReturningUsers(userDayMap, window);
  const returnRate = uniqueUsers > 0 ? returningUsers / uniqueUsers : 0;
  const uniqueFamilies = scopeType === 'global'
    ? merged.familyIds.size
    : familyId != null && snapshotCount > 0
      ? 1
      : 0;
  const familyParticipationRate = snapshotCount > 0
    ? (scopeType === 'global' ? loadedSnapshotCount / snapshotCount : 1)
    : 0;

  return {
    reportVersion: REPORT_VERSION,
    scopeType,
    familyId,
    reportType,
    windowDays: window.windowDays,
    reportDate: reportType === 'daily' ? window.endDayKey : null,
    windowStartDate: window.startDayKey,
    windowEndDate: window.endDayKey,
    generatedAtIso: generatedAt.toISOString(),
    generatedAtMillis: generatedAt.getTime(),
    retentionDays: DAILY_RETENTION_DAYS,
    activeDays: dayKeys.length,
    snapshotCount,
    loadedSnapshotCount,
    noFamilySnapshotCount,
    errorSnapshotCount,
    familyParticipationRate,
    uniqueUsers,
    returningUsers,
    returnRate,
    uniqueFamilies,
    averageFamilyMemberCount: average(merged.familyMemberCountTotal, merged.familyMemberCountSamples),
    averageFamilyTotalClassifications: average(
      merged.familyTotalClassificationsTotal,
      merged.familyTotalClassificationsSamples,
    ),
    averageFamilyTotalPoints: average(
      merged.familyTotalPointsTotal,
      merged.familyTotalPointsSamples,
    ),
    averageFamilyCurrentStreak: average(
      merged.familyCurrentStreakTotal,
      merged.familyCurrentStreakSamples,
    ),
    stateCounts: merged.stateCounts,
    roleCounts: merged.roleCounts,
  };
}

function buildReportsFromAggregation(state: AggregationState, generatedAt = new Date()): ReportPayload[] {
  const payloads: ReportPayload[] = [];
  for (const scopeKey of state.scopeOrder) {
    const dayBucketMap = state.scopeDayBuckets.get(scopeKey);
    const userDayMap = state.scopeUserDays.get(scopeKey);
    if (!dayBucketMap || !userDayMap || dayBucketMap.size === 0) {
      continue;
    }

    const sortedDays = Array.from(dayBucketMap.keys()).sort(compareDayKeys);
    for (const dayKey of sortedDays) {
      const window = buildWindow(dayKey, 1);
      const doc = buildReportDoc(
        scopeKey,
        'daily',
        window,
        dayBucketMap,
        userDayMap,
        state.globalFamilyIds,
        generatedAt,
      );
      payloads.push({
        docId: buildReportDocId(doc.scopeType, 'daily', 1, dayKey, doc.familyId),
        data: doc,
      });
    }

    if (state.latestDayKey) {
      for (const windowDays of ROLLING_WINDOWS) {
        const window = buildWindow(state.latestDayKey, windowDays);
        const doc = buildReportDoc(
          scopeKey,
          'rolling',
          window,
          dayBucketMap,
          userDayMap,
          state.globalFamilyIds,
          generatedAt,
        );
        payloads.push({
          docId: buildReportDocId(doc.scopeType, 'rolling', windowDays, null, doc.familyId),
          data: doc,
        });
      }
    }
  }

  return payloads;
}

async function fetchAllSnapshotEvents(): Promise<RawAnalyticsEventDoc[]> {
  const events: RawAnalyticsEventDoc[] = [];
  let lastDoc: QueryDocumentSnapshot | null = null;

  while (true) {
    let query = firestore
      .collection(ANALYTICS_COLLECTION)
      .where('eventName', '==', SNAPSHOT_EVENT_NAME)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(BATCH_SIZE);

    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snapshot = await query.get();
    if (snapshot.empty) {
      break;
    }

    for (const doc of snapshot.docs) {
      const parsed = parseSnapshotEvent(doc.data() as Record<string, unknown>, doc.id);
      if (parsed) {
        events.push(parsed);
      }
    }

    lastDoc = snapshot.docs[snapshot.docs.length - 1] ?? null;
    if (snapshot.size < BATCH_SIZE) {
      break;
    }
  }

  return events;
}

function aggregateSnapshotEvents(events: RawAnalyticsEventDoc[]): AggregationState {
  const state: AggregationState = {
    latestDayKey: null,
    globalFamilyIds: new Set<string>(),
    scopeDayBuckets: new Map<string, Map<string, ScopeAccumulator>>(),
    scopeUserDays: new Map<string, Map<string, Set<string>>>(),
    scopeOrder: ['global'],
  };

  for (const event of events) {
    if (!state.latestDayKey || compareDayKeys(event.dayKey, state.latestDayKey) > 0) {
      state.latestDayKey = event.dayKey;
    }

    const globalScopeKey = buildScopeKey('global');
    const globalBucket = getOrCreateDayBucket(state.scopeDayBuckets, globalScopeKey, event.dayKey);
    addToAccumulator(globalBucket, event);
    addUserDay(state.scopeUserDays, globalScopeKey, event.userId, event.dayKey);

    if (event.familyId) {
      state.globalFamilyIds.add(event.familyId);
      const familyScopeKey = buildScopeKey('family', event.familyId);
      if (!state.scopeOrder.includes(familyScopeKey)) {
        state.scopeOrder.push(familyScopeKey);
      }
      const familyBucket = getOrCreateDayBucket(state.scopeDayBuckets, familyScopeKey, event.dayKey);
      addToAccumulator(familyBucket, event);
      addUserDay(state.scopeUserDays, familyScopeKey, event.userId, event.dayKey);
    }
  }

  return state;
}

async function persistReports(payloads: ReportPayload[]): Promise<void> {
  for (const payload of payloads) {
    const shouldDelete = payload.data.snapshotCount === 0;
    const docRef = firestore.collection(REPORT_COLLECTION).doc(payload.docId);
    if (shouldDelete) {
      await docRef.delete().catch(() => undefined);
      continue;
    }
    await docRef.set(payload.data, { merge: false });
  }
}

async function cleanupStaleDailyReports(cutoffDayKey: string): Promise<number> {
  let deleted = 0;
  let lastDoc: QueryDocumentSnapshot | null = null;

  while (true) {
    let query = firestore
      .collection(REPORT_COLLECTION)
      .where('reportType', '==', 'daily')
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(BATCH_SIZE);

    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snapshot = await query.get();
    if (snapshot.empty) {
      break;
    }

    const staleDocs = snapshot.docs.filter((doc: any) => {
      const reportDate = doc.get('reportDate');
      return typeof reportDate === 'string' && compareDayKeys(reportDate, cutoffDayKey) < 0;
    });

    if (staleDocs.length > 0) {
      const batch = firestore.batch();
      staleDocs.forEach((doc: any) => batch.delete(doc.ref));
      await batch.commit();
      deleted += staleDocs.length;
    }

    lastDoc = snapshot.docs[snapshot.docs.length - 1] ?? null;
    if (snapshot.size < BATCH_SIZE) {
      break;
    }
  }

  return deleted;
}

async function cleanupAllFamilyDashboardReports(): Promise<number> {
  let deleted = 0;
  let lastDoc: QueryDocumentSnapshot | null = null;

  while (true) {
    let query = firestore
      .collection(REPORT_COLLECTION)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(BATCH_SIZE);

    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snapshot = await query.get();
    if (snapshot.empty) {
      break;
    }

    const batch = firestore.batch();
    snapshot.docs.forEach((doc: QueryDocumentSnapshot) => batch.delete(doc.ref));
    await batch.commit();
    deleted += snapshot.size;

    lastDoc = snapshot.docs[snapshot.docs.length - 1] ?? null;
    if (snapshot.size < BATCH_SIZE) {
      break;
    }
  }

  return deleted;
}

async function rebuildFamilyDashboardAnalytics(): Promise<{ eventCount: number; payloadCount: number; latestDayKey: string | null; deletedDailyDocs: number }> {
  const events = await fetchAllSnapshotEvents();
  if (events.length === 0) {
    return {
      eventCount: 0,
      payloadCount: 0,
      latestDayKey: null,
      deletedDailyDocs: await cleanupAllFamilyDashboardReports(),
    };
  }

  const aggregation = aggregateSnapshotEvents(events);
  const payloads = buildReportsFromAggregation(aggregation, new Date());
  await persistReports(payloads);

  const latestDayKey = aggregation.latestDayKey ?? events[events.length - 1]?.dayKey ?? null;
  const cutoffDayKey = latestDayKey ? addDays(latestDayKey, -(DAILY_RETENTION_DAYS - 1)) : '9999-12-31';
  const deletedDailyDocs = await cleanupStaleDailyReports(cutoffDayKey);

  return {
    eventCount: events.length,
    payloadCount: payloads.length,
    latestDayKey,
    deletedDailyDocs,
  };
}

export const aggregateFamilyDashboardAnalytics = asiaSouth1
  .pubsub
  .schedule('0 2 * * *')
  .timeZone('UTC')
  .onRun(async () => {
    const startedAt = Date.now();
    const result = await rebuildFamilyDashboardAnalytics();

    functions.logger.info('Family dashboard analytics report rebuilt', {
      eventCount: result.eventCount,
      payloadCount: result.payloadCount,
      latestDayKey: result.latestDayKey,
      deletedDailyDocs: result.deletedDailyDocs,
      durationMs: Date.now() - startedAt,
    });
  });

export const __testables = {
  buildScopeKey,
  parseScopeKey,
  buildReportDocId,
  aggregateSnapshotEvents,
  buildReportsFromAggregation,
  rebuildFamilyDashboardAnalytics,
  addDays,
  buildWindow,
};
