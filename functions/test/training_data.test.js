const test = require('node:test');
const assert = require('node:assert/strict');
const { __testables } = require('../lib/training_data.js');

test('detectSensitiveTextInNotes flags email phone and address-like patterns', () => {
  const findings = __testables.detectSensitiveTextInNotes(
    'Call +1 415 555 1234, email me@home.com, near MG Road street block B.',
  );
  assert.ok(findings.includes('email_like_text'));
  assert.ok(findings.includes('phone_like_text'));
  assert.ok(findings.includes('address_like_text'));
});

test('likelySensitiveFromSignals returns needs_redaction for risky signals', () => {
  const result = __testables.likelySensitiveFromSignals({
    category: 'Medical Waste',
    subcategory: 'Prescription bottle',
    barcodePresent: true,
    hasPotentialText: true,
  });
  assert.equal(result.redactionStatus, 'needs_redaction');
  assert.equal(result.reviewStatus, 'needs_redaction');
  assert.ok(result.flags.length >= 2);
});

test('shouldCleanupCandidate only returns true for aged deleted or rejected rows', () => {
  const now = Date.now();
  const oldMillis = now - (35 * 24 * 60 * 60 * 1000);
  const freshMillis = now - (1 * 24 * 60 * 60 * 1000);

  const mkTs = (millis) => ({ toMillis: () => millis });

  assert.equal(
    __testables.shouldCleanupCandidate(
      { review: { status: 'deleted' }, updatedAt: mkTs(oldMillis) },
      now - (30 * 24 * 60 * 60 * 1000),
    ),
    true,
  );
  assert.equal(
    __testables.shouldCleanupCandidate(
      { review: { status: 'rejected' }, updatedAt: mkTs(oldMillis) },
      now - (30 * 24 * 60 * 60 * 1000),
    ),
    true,
  );
  assert.equal(
    __testables.shouldCleanupCandidate(
      { review: { status: 'approved' }, updatedAt: mkTs(oldMillis) },
      now - (30 * 24 * 60 * 60 * 1000),
    ),
    false,
  );
  assert.equal(
    __testables.shouldCleanupCandidate(
      { review: { status: 'deleted' }, updatedAt: mkTs(freshMillis) },
      now - (30 * 24 * 60 * 60 * 1000),
    ),
    false,
  );
});

test('resolveAuthoritativeLabel cascades reviewer ground truth over user correction over raw prediction', () => {
  const gt = resolveAuthoritativeLabel({
    candidateId: 'c_001',
    reviewStatus: null,
    labelState: null,
    modelPrediction: { category: 'Dry Waste', itemName: 'plastic bottle', material: 'PET', provider: 'openai', model: 'gpt-4.1-nano' },
    userFeedback: { correctedCategory: 'Recyclable Waste', correctedItemName: 'PET bottle' },
    reviewerVerified: { groundTruth: { category: 'Dry Waste', itemName: 'PET bottle' } },
    imageContentHash: null,
    imageStoragePath: null,
    classificationId: null,
    consentPolicyVersion: null,
    reviewer: null,
    createdAt: null,
  });
  assert.equal(gt.category, 'Dry Waste');
  assert.equal(gt.itemName, 'PET bottle');
  assert.equal(gt.material, 'PET');
  assert.equal(gt.provider, 'openai');
});

test('resolveAuthoritativeLabel uses user correction when no reviewer ground truth', () => {
  const gt = resolveAuthoritativeLabel({
    candidateId: 'c_002',
    reviewStatus: null,
    labelState: null,
    modelPrediction: { category: 'Wet Waste', itemName: 'food scrap' },
    userFeedback: { correctedCategory: 'Dry Waste', correctedItemName: 'coconut shell' },
    reviewerVerified: null,
    imageContentHash: null,
    imageStoragePath: null,
    classificationId: null,
    consentPolicyVersion: null,
    reviewer: null,
    createdAt: null,
  });
  assert.equal(gt.category, 'Dry Waste');
  assert.equal(gt.itemName, 'coconut shell');
});

test('resolveAuthoritativeLabel falls back to raw prediction when no correction or review', () => {
  const gt = resolveAuthoritativeLabel({
    candidateId: 'c_003',
    reviewStatus: null,
    labelState: null,
    modelPrediction: { category: 'Hazardous Waste', itemName: 'battery', confidence: 0.89 },
    userFeedback: null,
    reviewerVerified: null,
    imageContentHash: null,
    imageStoragePath: null,
    classificationId: null,
    consentPolicyVersion: null,
    reviewer: null,
    createdAt: null,
  });
  assert.equal(gt.category, 'Hazardous Waste');
  assert.equal(gt.itemName, 'battery');
  assert.equal(gt.confidence, 0.89);
});

test('resolveAuthoritativeLabel uses labelState for source when available', () => {
  const gt = resolveAuthoritativeLabel({
    candidateId: 'c_004',
    reviewStatus: 'approved',
    labelState: 'golden',
    modelPrediction: { category: 'Medical Waste', itemName: 'syringe' },
    userFeedback: null,
    reviewerVerified: null,
    imageContentHash: null,
    imageStoragePath: null,
    classificationId: null,
    consentPolicyVersion: null,
    reviewer: null,
    createdAt: null,
  });
  assert.equal(gt.labelSource, 'golden');
});

test('buildManifestRow returns null for missing candidateId', () => {
  const row = buildManifestRow({}, null, null, null, 'v1');
  assert.equal(row, null);
});

test('buildManifestRow produces correct shape with full data', () => {
  const row = buildManifestRow(
    {
      candidateId: 'c_005',
      classificationId: 'cls_abc',
      modelPrediction: { category: 'Dry Waste', itemName: 'can', provider: 'gemini' },
      image: { contentHash: 'abc123', storagePath: 'training/review/2026/05/c_005.jpg' },
      review: { status: 'golden', reviewer: 'admin_1' },
      consent: { policyVersion: 'training-data-v1' },
      createdAt: { _seconds: 1716364800 },
    },
    { category: 'Dry Waste', itemName: 'can', provider: 'gemini' },
    null,
    null,
    'v2026-05-22',
  );
  assert.notEqual(row, null);
  assert.equal(row.candidateId, 'c_005');
  assert.equal(row.category, 'Dry Waste');
  assert.equal(row.labelSource, 'golden');
  assert.equal(row.provenance.classificationId, 'cls_abc');
  assert.equal(row.datasetVersion, 'v2026-05-22');
  assert.equal(row.imageHash, 'abc123');
});

test('buildManifestRow merges labelState from training_labels', () => {
  const row = buildManifestRow(
    {
      candidateId: 'c_006',
      review: { status: 'approved' },
      modelPrediction: { category: 'Wet Waste' },
    },
    { category: 'Wet Waste' },
    null,
    null,
    'v1',
  );
  assert.equal(row.labelSource, 'approved');
});

function resolveAuthoritativeLabel(input) {
  return __testables.resolveAuthoritativeLabel(input);
}

function buildManifestRow(cand, raw, userCorr, rev, version) {
  return __testables.buildManifestRow(cand, raw, userCorr, rev, version);
}

test('isAdminContext enforces admin in production and allows emulator override', () => {
  const prevEmulator = process.env.FUNCTIONS_EMULATOR;
  const prevOverride = process.env.ALLOW_TRAINING_REVIEW_NON_ADMIN;

  process.env.FUNCTIONS_EMULATOR = 'false';
  process.env.ALLOW_TRAINING_REVIEW_NON_ADMIN = 'true';
  assert.equal(
    __testables.isAdminContext({ auth: { token: { admin: false } } }),
    false,
  );
  assert.equal(
    __testables.isAdminContext({ auth: { token: { admin: true } } }),
    true,
  );

  process.env.FUNCTIONS_EMULATOR = 'true';
  process.env.ALLOW_TRAINING_REVIEW_NON_ADMIN = 'true';
  assert.equal(
    __testables.isAdminContext({ auth: { token: { admin: false } } }),
    true,
  );

  process.env.FUNCTIONS_EMULATOR = prevEmulator;
  process.env.ALLOW_TRAINING_REVIEW_NON_ADMIN = prevOverride;
});
