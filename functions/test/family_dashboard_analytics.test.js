const test = require('node:test');
const assert = require('node:assert/strict');
const admin = require('firebase-admin');

if (admin.apps.length === 0) {
  admin.initializeApp({ projectId: 'family-dashboard-analytics-test' });
}

const {
  __testables,
} = require('../lib/family_dashboard_analytics.js');

function makeEvent({
  id,
  userId,
  timestampMillis,
  familyId = null,
  dashboardState = 'loaded',
  hasFamily = true,
  currentUserRole = 'member',
  errorType = null,
  familyMemberCount = null,
  familyTotalClassifications = null,
  familyTotalPoints = null,
  familyCurrentStreak = null,
}) {
  return {
    id,
    userId,
    eventName: 'family_dashboard_snapshot',
    timestampMillis,
    dayKey: new Date(timestampMillis).toISOString().slice(0, 10),
    familyId,
    dashboardState,
    hasFamily,
    currentUserRole,
    errorType,
    familyMemberCount,
    familyTotalClassifications,
    familyTotalPoints,
    familyCurrentStreak,
  };
}

test('buildReportDocId encodes global and family scopes', () => {
  assert.equal(
    __testables.buildReportDocId('global', 'daily', 1, '2026-05-24', null),
    'global__daily__2026-05-24',
  );
  assert.equal(
    __testables.buildReportDocId('global', 'rolling', 7, null, null),
    'global__rolling__7d',
  );
  assert.equal(
    __testables.buildReportDocId('family', 'daily', 1, '2026-05-24', 'Family A/B'),
    'family__Family%20A%2FB__daily__2026-05-24',
  );
  assert.equal(
    __testables.buildReportDocId('family', 'rolling', 28, null, 'Family A/B'),
    'family__Family%20A%2FB__rolling__28d',
  );
});

test('aggregateSnapshotEvents builds global and per-family scopes with latest day tracking', () => {
  const events = [
    makeEvent({
      id: 'e1',
      userId: 'user_1',
      timestampMillis: Date.parse('2026-05-23T10:00:00.000Z'),
      familyId: 'family_1',
      familyMemberCount: 2,
      familyTotalClassifications: 18,
      familyTotalPoints: 120,
      familyCurrentStreak: 6,
    }),
    makeEvent({
      id: 'e2',
      userId: 'user_1',
      timestampMillis: Date.parse('2026-05-24T09:00:00.000Z'),
      familyId: 'family_1',
      currentUserRole: 'admin',
      familyMemberCount: 2,
      familyTotalClassifications: 22,
      familyTotalPoints: 135,
      familyCurrentStreak: 7,
    }),
    makeEvent({
      id: 'e3',
      userId: 'user_2',
      timestampMillis: Date.parse('2026-05-24T11:00:00.000Z'),
      familyId: null,
      hasFamily: false,
      currentUserRole: 'member',
      dashboardState: 'no_family',
      errorType: 'missing_family',
    }),
  ];

  const state = __testables.aggregateSnapshotEvents(events);

  assert.equal(state.latestDayKey, '2026-05-24');
  assert.deepEqual(state.scopeOrder, ['global', 'family:family_1']);
  assert.deepEqual(Array.from(state.globalFamilyIds).sort(), ['family_1']);

  const globalDayBucket = state.scopeDayBuckets.get('global').get('2026-05-24');
  assert.equal(globalDayBucket.snapshotCount, 2);
  assert.equal(globalDayBucket.loadedSnapshotCount, 1);
  assert.equal(globalDayBucket.noFamilySnapshotCount, 1);
  assert.equal(globalDayBucket.errorSnapshotCount, 1);

  const familyDayBucket = state.scopeDayBuckets.get('family:family_1').get('2026-05-24');
  assert.equal(familyDayBucket.snapshotCount, 1);
  assert.equal(familyDayBucket.loadedSnapshotCount, 1);
  assert.equal(familyDayBucket.noFamilySnapshotCount, 0);
  assert.equal(familyDayBucket.familyMemberCountTotal, 2);
});

test('buildReportsFromAggregation emits daily and rolling report payloads', () => {
  const events = [
    makeEvent({
      id: 'e1',
      userId: 'user_1',
      timestampMillis: Date.parse('2026-05-23T10:00:00.000Z'),
      familyId: 'family_1',
      currentUserRole: 'member',
      familyMemberCount: 2,
      familyTotalClassifications: 18,
      familyTotalPoints: 120,
      familyCurrentStreak: 6,
    }),
    makeEvent({
      id: 'e2',
      userId: 'user_1',
      timestampMillis: Date.parse('2026-05-24T09:00:00.000Z'),
      familyId: 'family_1',
      currentUserRole: 'admin',
      familyMemberCount: 2,
      familyTotalClassifications: 22,
      familyTotalPoints: 135,
      familyCurrentStreak: 7,
    }),
    makeEvent({
      id: 'e3',
      userId: 'user_2',
      timestampMillis: Date.parse('2026-05-24T11:00:00.000Z'),
      familyId: null,
      hasFamily: false,
      currentUserRole: 'member',
      dashboardState: 'no_family',
    }),
  ];

  const state = __testables.aggregateSnapshotEvents(events);
  const payloads = __testables.buildReportsFromAggregation(state, new Date('2026-05-25T00:00:00.000Z'));

  const docIds = payloads.map((payload) => payload.docId).sort();
  assert.deepEqual(docIds, [
    'family__family_1__daily__2026-05-23',
    'family__family_1__daily__2026-05-24',
    'family__family_1__rolling__28d',
    'family__family_1__rolling__7d',
    'global__daily__2026-05-23',
    'global__daily__2026-05-24',
    'global__rolling__28d',
    'global__rolling__7d',
  ]);

  const globalRolling7 = payloads.find((payload) => payload.docId === 'global__rolling__7d').data;
  assert.equal(globalRolling7.scopeType, 'global');
  assert.equal(globalRolling7.reportType, 'rolling');
  assert.equal(globalRolling7.windowDays, 7);
  assert.equal(globalRolling7.snapshotCount, 3);
  assert.equal(globalRolling7.loadedSnapshotCount, 2);
  assert.equal(globalRolling7.noFamilySnapshotCount, 1);
  assert.equal(globalRolling7.uniqueUsers, 2);
  assert.equal(globalRolling7.uniqueFamilies, 1);
  assert.equal(globalRolling7.familyParticipationRate, 2 / 3);
  assert.equal(globalRolling7.averageFamilyMemberCount, 2);
  assert.equal(globalRolling7.averageFamilyTotalClassifications, 20);
  assert.equal(globalRolling7.averageFamilyTotalPoints, 127.5);
  assert.equal(globalRolling7.averageFamilyCurrentStreak, 6.5);
  assert.equal(globalRolling7.stateCounts.loaded, 2);
  assert.equal(globalRolling7.stateCounts.no_family, 1);
  assert.equal(globalRolling7.roleCounts.member, 2);
  assert.equal(globalRolling7.roleCounts.admin, 1);

  const familyDaily = payloads.find((payload) => payload.docId === 'family__family_1__daily__2026-05-24').data;
  assert.equal(familyDaily.scopeType, 'family');
  assert.equal(familyDaily.familyId, 'family_1');
  assert.equal(familyDaily.snapshotCount, 1);
  assert.equal(familyDaily.familyParticipationRate, 1);
  assert.equal(familyDaily.noFamilySnapshotCount, 0);
  assert.equal(familyDaily.uniqueFamilies, 1);
  assert.equal(familyDaily.averageFamilyTotalPoints, 135);
  assert.equal(familyDaily.retentionDays, 90);
});

test('buildWindow and addDays keep retention windows aligned', () => {
  assert.equal(__testables.addDays('2026-05-24', -89), '2026-02-24');
  assert.deepEqual(__testables.buildWindow('2026-05-24', 7), {
    windowDays: 7,
    startDayKey: '2026-05-18',
    endDayKey: '2026-05-24',
  });
});
