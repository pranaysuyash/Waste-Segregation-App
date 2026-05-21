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
