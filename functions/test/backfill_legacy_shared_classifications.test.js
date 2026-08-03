'use strict';

const { test } = require('node:test');
const assert = require('node:assert');

const {
  validateLegacyDoc,
} = require('../lib/backfill_legacy_shared_classifications.js');

// Canonical payload produced by SharedWasteClassification.toJson() (mirrors the
// rules `validateSharedClassificationCreate` allowlist).
function canonicalLegacyDoc(overrides = {}) {
  return {
    id: 'shared-doc-1',
    classification: { category: 'dry', confidence: 0.92 },
    sharedBy: 'user-123',
    sharedByDisplayName: 'Anita',
    sharedByPhotoUrl: 'https://example.com/photo.jpg',
    sharedAt: '2026-05-01T10:00:00.000',
    familyId: 'family-456',
    reactions: [],
    comments: [],
    location: null,
    isVisible: true,
    familyTags: [],
    ...overrides,
  };
}

test('accepts a canonical legacy document', () => {
  const result = validateLegacyDoc(canonicalLegacyDoc());
  assert.strictEqual(result.ok, true);
});

test('rejects non-object input (undefined/null/primitive)', () => {
  assert.deepStrictEqual(validateLegacyDoc(undefined), {
    ok: false,
    reason: 'not-an-object',
  });
  assert.deepStrictEqual(validateLegacyDoc(null), {
    ok: false,
    reason: 'not-an-object',
  });
  assert.deepStrictEqual(validateLegacyDoc('a-string'), {
    ok: false,
    reason: 'not-an-object',
  });
});

test('rejects missing required field', () => {
  const data = canonicalLegacyDoc();
  delete data.familyId;
  const result = validateLegacyDoc(data);
  assert.strictEqual(result.ok, false);
  assert.strictEqual(result.reason, 'missing-familyId');
});

test('rejects every required field individually', () => {
  const required = [
    'id',
    'classification',
    'sharedBy',
    'sharedByDisplayName',
    'sharedAt',
    'familyId',
  ];
  for (const field of required) {
    const data = canonicalLegacyDoc();
    delete data[field];
    const result = validateLegacyDoc(data);
    assert.strictEqual(result.ok, false, `should reject missing ${field}`);
    assert.strictEqual(result.reason, `missing-${field}`);
  }
});

test('rejects unexpected extra fields', () => {
  const data = canonicalLegacyDoc({ adminReviewerId: 'admin-1' });
  const result = validateLegacyDoc(data);
  assert.strictEqual(result.ok, false);
  assert.strictEqual(result.reason, 'unexpected-field-adminReviewerId');
});

test('rejects empty sharedBy / sharedByDisplayName / familyId', () => {
  for (const field of ['sharedBy', 'sharedByDisplayName', 'familyId']) {
    assert.deepStrictEqual(validateLegacyDoc(canonicalLegacyDoc({ [field]: '' })), {
      ok: false,
      reason: `empty-or-non-string-${field}`,
    });
    assert.deepStrictEqual(
      validateLegacyDoc(canonicalLegacyDoc({ [field]: '   ' })),
      { ok: false, reason: `empty-or-non-string-${field}` },
    );
    assert.deepStrictEqual(
      validateLegacyDoc(canonicalLegacyDoc({ [field]: 42 })),
      { ok: false, reason: `empty-or-non-string-${field}` },
    );
  }
});

test('accepts optional fields when present', () => {
  const data = canonicalLegacyDoc({
    sharedByPhotoUrl: null,
    location: { lat: 12.97, lng: 77.59 },
    reactions: [{ userId: 'u2', type: 'like' }],
    comments: [{ userId: 'u2', text: 'nice' }],
    isVisible: false,
    familyTags: ['kitchen', 'society-a'],
  });
  const result = validateLegacyDoc(data);
  assert.strictEqual(result.ok, true);
});

test('accepts classification regardless of shape (key-presence validation)', () => {
  // The rules-level shape check is a Firestore rules concern; the backfill
  // validator only enforces key presence + non-empty string fields.
  const data = canonicalLegacyDoc({ classification: 'dry-waste' });
  const result = validateLegacyDoc(data);
  assert.strictEqual(result.ok, true);
});
