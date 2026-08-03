/**
 * Backfill script: migrate legacy top-level `shared_classifications` documents
 * into `families/{familyId}/shared_classifications/` (C-07 pre-launch safety net).
 *
 * Background: C-07 moved shared classifications from a top-level collection to a
 * `families/{familyId}/` subcollection so Firestore rules can enforce family
 * membership (read/create/update/delete all gate on `isFamilyMemberById`).
 * Any document written before the move at the old top-level path is now
 * unreachable by the app (rules deny reads at that path) and would be orphaned.
 * This script re-parents those documents under the correct family subcollection.
 *
 * Safety properties:
 * - **Copy-first:** the source document is NOT deleted unless `--delete-source`
 *   is passed. Default behaviour preserves the source as a backup.
 * - **Idempotent:** re-running is safe. A document whose target path already
 *   exists is skipped and reported (no overwrite, no duplicate).
 * - **Rules-conformant:** only documents that satisfy the `validateSharedClassificationCreate`
 *   contract from `firestore.rules` are migrated; invalid ones are reported, not
 *   written.
 * - **Family existence check:** if the referenced `families/{familyId}` doc does
 *   not exist, the item is still migrated (data preservation) but recorded in
 *   `missingFamilyIds` so the operator can investigate — a migrated doc under a
 *   missing family would be invisible to clients until the family is restored.
 *
 * Usage (run from `functions/` after `npm run build`):
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json \
 *     node lib/backfill_legacy_shared_classifications.js \
 *       --project <project-id> [--dry-run] [--delete-source] [--limit <n>]
 *
 * Or via the npm alias:
 *   npm run backfill:shared-classifications -- --project <project-id> --dry-run
 *
 * Flags:
 *   --project <id>     GCP project id (required unless GOOGLE_CLOUD_PROJECT set)
 *   --dry-run          Validate + report only; write nothing.
 *   --delete-source    Delete the legacy top-level doc after a successful copy.
 *   --limit <n>        Only process the first n legacy docs (testing convenience).
 */

import * as admin from 'firebase-admin';

// Mirrors the collection names in lib/services/firestore_schema_registry.dart.
const LEGACY_COLLECTION = 'shared_classifications';
const FAMILIES_COLLECTION = 'families';
const SHARED_SUBCOLLECTION = 'shared_classifications';

// Mirrors `validateSharedClassificationCreate` in firestore.rules (C-07).
// The legacy docs were produced by SharedWasteClassification.toJson(), so the
// canonical payload surface is exactly the rules allowlist.
const REQUIRED_FIELDS = [
  'id',
  'classification',
  'sharedBy',
  'sharedByDisplayName',
  'sharedAt',
  'familyId',
] as const;

const ALLOWED_FIELDS = new Set<string>([
  ...REQUIRED_FIELDS,
  'sharedByPhotoUrl',
  'reactions',
  'comments',
  'location',
  'isVisible',
  'familyTags',
]);

/** Non-empty string fields required by the rules contract. */
const NON_EMPTY_STRING_FIELDS = [
  'sharedBy',
  'sharedByDisplayName',
  'familyId',
] as const;

export type ValidationResult =
  | { ok: true }
  | { ok: false; reason: string };

/**
 * Validates a legacy document against the `validateSharedClassificationCreate`
 * contract. Kept as a pure function so it is unit-testable without the emulator.
 */
export function validateLegacyDoc(
  data: Record<string, unknown> | undefined | null,
): ValidationResult {
  if (!data || typeof data !== 'object') {
    return { ok: false, reason: 'not-an-object' };
  }
  for (const field of REQUIRED_FIELDS) {
    if (!(field in data)) {
      return { ok: false, reason: `missing-${field}` };
    }
  }
  for (const key of Object.keys(data)) {
    if (!ALLOWED_FIELDS.has(key)) {
      return { ok: false, reason: `unexpected-field-${key}` };
    }
  }
  for (const field of NON_EMPTY_STRING_FIELDS) {
    const value = data[field];
    if (typeof value !== 'string' || value.trim().length === 0) {
      return { ok: false, reason: `empty-or-non-string-${field}` };
    }
  }
  return { ok: true };
}

export interface BackfillSummary {
  scanned: number;
  migrated: number;
  skippedExisting: number;
  skippedInvalid: number;
  deletedSource: number;
  /** Family ids referenced by migrated docs whose family doc does not exist. */
  missingFamilyIds: string[];
  /** Stable legacy doc ids that failed validation, with the reason. */
  invalidDocIds: Array<{ id: string; reason: string }>;
}

export interface BackfillOptions {
  projectId?: string;
  dryRun: boolean;
  deleteSource: boolean;
  limit?: number;
}

function parseArgs(argv: string[]): BackfillOptions {
  const options: BackfillOptions = { dryRun: false, deleteSource: false };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    switch (arg) {
      case '--project':
        options.projectId = argv[++i];
        break;
      case '--dry-run':
        options.dryRun = true;
        break;
      case '--delete-source':
        options.deleteSource = true;
        break;
      case '--limit': {
        const raw = Number(argv[++i]);
        options.limit = Number.isFinite(raw) && raw > 0 ? Math.floor(raw) : undefined;
        break;
      }
      case '--help':
      case '-h':
        console.log(
          'Usage: node lib/backfill_legacy_shared_classifications.js ' +
            '--project <id> [--dry-run] [--delete-source] [--limit <n>]',
        );
        process.exit(0);
      default:
        console.error(`Unknown argument: ${arg}`);
        process.exit(2);
    }
  }
  return options;
}

async function runBackfill(
  db: admin.firestore.Firestore,
  options: BackfillOptions,
): Promise<BackfillSummary> {
  const summary: BackfillSummary = {
    scanned: 0,
    migrated: 0,
    skippedExisting: 0,
    skippedInvalid: 0,
    deletedSource: 0,
    missingFamilyIds: [],
    invalidDocIds: [],
  };

  // Write batches are capped to stay well under Firestore's 500-write limit.
  // A single mutable `batch` is reassigned to a fresh instance after every
  // commit: firebase-admin's WriteBatch throws on any write to an already-
  // committed batch, so the committed instance must never be reused.
  const BATCH_LIMIT = 400;
  let batch = db.batch();
  let pendingWrites = 0;

  const flush = async () => {
    if (pendingWrites === 0) return;
    if (!options.dryRun) {
      await batch.commit();
    }
    batch = db.batch();
    pendingWrites = 0;
  };

  const enqueueWrite = (write: () => void) => {
    write();
    pendingWrites++;
  };

  const legacyRef = db.collection(LEGACY_COLLECTION);
  let query: admin.firestore.Query = legacyRef;
  if (options.limit !== undefined) {
    query = query.limit(options.limit);
  }

  const snapshot = await query.get();
  summary.scanned = snapshot.size;
  console.log(`Scanned ${summary.scanned} legacy ${LEGACY_COLLECTION} doc(s).`);

  for (const doc of snapshot.docs) {
    const data = doc.data() as Record<string, unknown> | undefined;

    const validation = validateLegacyDoc(data);
    if (!validation.ok) {
      summary.skippedInvalid++;
      summary.invalidDocIds.push({ id: doc.id, reason: validation.reason });
      console.warn(`  SKIP invalid ${doc.id}: ${validation.reason}`);
      continue;
    }
    // validateLegacyDoc(ok) guarantees a non-null object, but TS cannot narrow
    // through the function call — assert the checked shape explicitly.
    const docData = data as Record<string, unknown>;

    const familyId = docData.familyId as string;
    const targetRef = db
      .collection(FAMILIES_COLLECTION)
      .doc(familyId)
      .collection(SHARED_SUBCOLLECTION)
      .doc(doc.id);

    // Idempotency: never overwrite an existing migrated doc.
    const targetSnap = await targetRef.get();
    if (targetSnap.exists) {
      summary.skippedExisting++;
      console.log(`  SKIP existing ${targetRef.path} (already migrated).`);
      continue;
    }

    // Family existence check (informational; still migrate to preserve data).
    const familySnap = await db.collection(FAMILIES_COLLECTION).doc(familyId).get();
    if (!familySnap.exists && !summary.missingFamilyIds.includes(familyId)) {
      summary.missingFamilyIds.push(familyId);
      console.warn(
        `  WARN family doc missing for ${familyId} — migrated item will be ` +
          `invisible until the family is restored.`,
      );
    }

    // Copy the canonical payload verbatim (already rules-conformant).
    const payload: Record<string, unknown> = {};
    for (const key of ALLOWED_FIELDS) {
      if (key in docData) payload[key] = docData[key];
    }

    enqueueWrite(() => {
      targetRef.set(payload);
    });
    summary.migrated++;

    if (options.deleteSource) {
      enqueueWrite(() => {
        doc.ref.delete();
      });
      summary.deletedSource++;
    }

    console.log(`  MIGRATE ${doc.id} -> ${targetRef.path}`);
    if (pendingWrites >= BATCH_LIMIT) {
      await flush();
    }
  }

  await flush();

  if (options.dryRun) {
    console.log('(dry-run) No writes were performed.');
  }
  return summary;
}

async function main(): Promise<void> {
  const options = parseArgs(process.argv.slice(2));

  if (!options.projectId && !process.env.GOOGLE_CLOUD_PROJECT) {
    console.error(
      'Missing project id: pass --project <id> or set GOOGLE_CLOUD_PROJECT.',
    );
    process.exit(1);
  }

  admin.initializeApp({
    projectId: options.projectId ?? process.env.GOOGLE_CLOUD_PROJECT,
  });
  const db = admin.firestore();

  console.log(
    `Backfill start: project=${options.projectId ?? process.env.GOOGLE_CLOUD_PROJECT} ` +
      `dryRun=${options.dryRun} deleteSource=${options.deleteSource}`,
  );

  const summary = await runBackfill(db, options);

  console.log('\n=== Summary ===');
  console.log(JSON.stringify(summary, null, 2));

  if (summary.invalidDocIds.length > 0 || summary.skippedExisting > 0) {
    // Migrated successfully, but review the SKIP lines above for anything that
    // needs operator attention before deleting sources.
    console.log('Backfill complete — some documents were skipped (see SKIP lines).');
  } else {
    console.log('Backfill complete.');
  }
}

// Runnable as a standalone script; safe to import for unit tests.
// eslint-disable-next-line @typescript-eslint/no-require-imports
if (require.main === module) {
  main().catch((error: unknown) => {
    console.error('Backfill failed:', error);
    process.exit(1);
  });
}
