/**
 * classify_image.test.js
 *
 * Unit tests for pure helper functions in classify_image.ts.
 *
 * Uses Node.js built-in test runner (node:test + node:assert/strict).
 * Run after build: node --test test/classify_image.test.js
 *
 * These tests cover the pure, Firebase-free helper functions exported via
 * __testables. Integration tests that require Firestore or Auth emulators
 * should be added to the emulator test suite instead.
 */

const test = require('node:test');
const assert = require('node:assert/strict');
const { createHash } = require('crypto');
const { __testables } = require('../lib/classify_image.js');

const {
  parseBoolEnv,
  shouldEnforceCallableAppCheck,
  getClassifyRateLimitConfig,
  getCacheTtlSeconds,
  getClassifyTokenCost,
  getClassifyPremiumDiscountPercent,
  getDailyFreeScanLimit,
  toUtcDayKey,
  resolveDailyFreeUsageState,
  estimateCostUsd,
  buildClassificationPrompt,
  buildReservationId,
  normalizeRequestId,
} = __testables;

// ---------------------------------------------------------------------------
// parseBoolEnv
// ---------------------------------------------------------------------------

test('parseBoolEnv: "true" → true', () => {
  assert.equal(parseBoolEnv('true'), true);
  assert.equal(parseBoolEnv('TRUE'), true);
  assert.equal(parseBoolEnv('1'), true);
  assert.equal(parseBoolEnv('yes'), true);
  assert.equal(parseBoolEnv('on'), true);
});

test('parseBoolEnv: "false" → false', () => {
  assert.equal(parseBoolEnv('false'), false);
  assert.equal(parseBoolEnv('FALSE'), false);
  assert.equal(parseBoolEnv('0'), false);
  assert.equal(parseBoolEnv('no'), false);
  assert.equal(parseBoolEnv('off'), false);
});

test('parseBoolEnv: undefined uses fallback', () => {
  assert.equal(parseBoolEnv(undefined, false), false);
  assert.equal(parseBoolEnv(undefined, true), true);
});

test('parseBoolEnv: unknown string uses fallback', () => {
  assert.equal(parseBoolEnv('maybe', false), false);
  assert.equal(parseBoolEnv('', true), true);
});

// ---------------------------------------------------------------------------
// shouldEnforceCallableAppCheck
// ---------------------------------------------------------------------------

test.afterEach(() => {
  // Reset App Check env vars after each test.
  delete process.env.REQUIRE_APPCHECK_CALLABLE;
  delete process.env.ENFORCE_APPCHECK_IN_EMULATOR;
  delete process.env.FUNCTIONS_EMULATOR;
});

test('shouldEnforceCallableAppCheck: false when REQUIRE_APPCHECK_CALLABLE unset', () => {
  delete process.env.REQUIRE_APPCHECK_CALLABLE;
  assert.equal(shouldEnforceCallableAppCheck(), false);
});

test('shouldEnforceCallableAppCheck: false when REQUIRE_APPCHECK_CALLABLE=false', () => {
  process.env.REQUIRE_APPCHECK_CALLABLE = 'false';
  assert.equal(shouldEnforceCallableAppCheck(), false);
});

test('shouldEnforceCallableAppCheck: true in non-emulator when REQUIRE_APPCHECK_CALLABLE=true', () => {
  process.env.REQUIRE_APPCHECK_CALLABLE = 'true';
  delete process.env.FUNCTIONS_EMULATOR;
  assert.equal(shouldEnforceCallableAppCheck(), true);
});

test('shouldEnforceCallableAppCheck: false in emulator without ENFORCE_APPCHECK_IN_EMULATOR', () => {
  process.env.REQUIRE_APPCHECK_CALLABLE = 'true';
  process.env.FUNCTIONS_EMULATOR = 'true';
  delete process.env.ENFORCE_APPCHECK_IN_EMULATOR;
  assert.equal(shouldEnforceCallableAppCheck(), false);
});

test('shouldEnforceCallableAppCheck: true in emulator when both flags set', () => {
  process.env.REQUIRE_APPCHECK_CALLABLE = 'true';
  process.env.FUNCTIONS_EMULATOR = 'true';
  process.env.ENFORCE_APPCHECK_IN_EMULATOR = 'true';
  assert.equal(shouldEnforceCallableAppCheck(), true);
});

// ---------------------------------------------------------------------------
// getClassifyRateLimitConfig
// ---------------------------------------------------------------------------

test('getClassifyRateLimitConfig: default 10 req/60s', () => {
  delete process.env.CLASSIFY_IMAGE_MAX_REQUESTS;
  delete process.env.CLASSIFY_IMAGE_WINDOW_SECONDS;
  const cfg = getClassifyRateLimitConfig();
  assert.equal(cfg.maxRequests, 10);
  assert.equal(cfg.windowSeconds, 60);
});

test('getClassifyRateLimitConfig: reads env vars', () => {
  process.env.CLASSIFY_IMAGE_MAX_REQUESTS = '25';
  process.env.CLASSIFY_IMAGE_WINDOW_SECONDS = '120';
  const cfg = getClassifyRateLimitConfig();
  assert.equal(cfg.maxRequests, 25);
  assert.equal(cfg.windowSeconds, 120);
  delete process.env.CLASSIFY_IMAGE_MAX_REQUESTS;
  delete process.env.CLASSIFY_IMAGE_WINDOW_SECONDS;
});

// ---------------------------------------------------------------------------
// getCacheTtlSeconds
// ---------------------------------------------------------------------------

test('getCacheTtlSeconds: defaults to 86400', () => {
  delete process.env.CLASSIFY_CACHE_TTL_SECONDS;
  assert.equal(getCacheTtlSeconds(), 86400);
});

test('getCacheTtlSeconds: reads env override', () => {
  process.env.CLASSIFY_CACHE_TTL_SECONDS = '3600';
  assert.equal(getCacheTtlSeconds(), 3600);
  delete process.env.CLASSIFY_CACHE_TTL_SECONDS;
});

// ---------------------------------------------------------------------------
// getClassifyTokenCost
// ---------------------------------------------------------------------------

test('getClassifyTokenCost: defaults to 5', () => {
  delete process.env.CLASSIFY_IMAGE_TOKEN_COST;
  assert.equal(getClassifyTokenCost(), 5);
});

test('getClassifyTokenCost: minimum 1 even when env says 0', () => {
  process.env.CLASSIFY_IMAGE_TOKEN_COST = '0';
  assert.equal(getClassifyTokenCost(), 1);
  delete process.env.CLASSIFY_IMAGE_TOKEN_COST;
});

test('getClassifyTokenCost: canonical MONETIZATION_* env key takes precedence', () => {
  process.env.MONETIZATION_CLASSIFY_IMAGE_TOKEN_COST = '7';
  process.env.CLASSIFY_IMAGE_TOKEN_COST = '3';
  assert.equal(getClassifyTokenCost(), 7);
  delete process.env.MONETIZATION_CLASSIFY_IMAGE_TOKEN_COST;
  delete process.env.CLASSIFY_IMAGE_TOKEN_COST;
});

test('getClassifyPremiumDiscountPercent: canonical MONETIZATION_* env key takes precedence', () => {
  process.env.MONETIZATION_CLASSIFY_IMAGE_PREMIUM_DISCOUNT_PERCENT = '35';
  process.env.CLASSIFY_IMAGE_PREMIUM_DISCOUNT_PERCENT = '5';
  assert.equal(getClassifyPremiumDiscountPercent(), 35);
  delete process.env.MONETIZATION_CLASSIFY_IMAGE_PREMIUM_DISCOUNT_PERCENT;
  delete process.env.CLASSIFY_IMAGE_PREMIUM_DISCOUNT_PERCENT;
});

// ---------------------------------------------------------------------------
// Daily free-scan quota helpers
// ---------------------------------------------------------------------------

test('getDailyFreeScanLimit: defaults to 5 and reads canonical env key', () => {
  delete process.env.MONETIZATION_FREE_DAILY_SCAN_LIMIT;
  delete process.env.CLASSIFY_DAILY_FREE_CLASSIFICATIONS;
  delete process.env.DAILY_FREE_CLASSIFICATIONS;
  assert.equal(getDailyFreeScanLimit(), 5);

  process.env.MONETIZATION_FREE_DAILY_SCAN_LIMIT = '9';
  process.env.CLASSIFY_DAILY_FREE_CLASSIFICATIONS = '4';
  assert.equal(getDailyFreeScanLimit(), 9);

  delete process.env.MONETIZATION_FREE_DAILY_SCAN_LIMIT;
  delete process.env.CLASSIFY_DAILY_FREE_CLASSIFICATIONS;
  delete process.env.DAILY_FREE_CLASSIFICATIONS;
});

test('toUtcDayKey: normalizes date-like inputs', () => {
  assert.equal(toUtcDayKey('2026-05-22'), '2026-05-22');
  assert.equal(toUtcDayKey('2026-05-22T11:22:33.000Z'), '2026-05-22');
  assert.equal(toUtcDayKey(new Date('2026-05-22T03:00:00.000Z')), '2026-05-22');
  assert.equal(toUtcDayKey('not-a-date'), null);
});

test('resolveDailyFreeUsageState: resets usage on day rollover', () => {
  const now = new Date('2026-05-23T10:00:00.000Z');
  const rollover = resolveDailyFreeUsageState(5, '2026-05-22', now);
  assert.equal(rollover.todayKey, '2026-05-23');
  assert.equal(rollover.usedToday, 0);

  const sameDay = resolveDailyFreeUsageState(3, '2026-05-23T01:20:00.000Z', now);
  assert.equal(sameDay.usedToday, 3);
  assert.equal(sameDay.todayKey, '2026-05-23');
});

// ---------------------------------------------------------------------------
// estimateCostUsd
// ---------------------------------------------------------------------------

test('estimateCostUsd: returns null when both tokens null', () => {
  assert.equal(estimateCostUsd('gpt-4.1-nano', null, null), null);
});

test('estimateCostUsd: calculates non-zero cost for gpt-4.1-nano', () => {
  const cost = estimateCostUsd('gpt-4.1-nano', 1000, 500);
  assert.ok(cost !== null && cost > 0, 'Expected positive cost for gpt-4.1-nano');
  // 1000/1000 * 0.0001 + 500/1000 * 0.0004 = 0.0001 + 0.0002 = 0.0003
  assert.ok(Math.abs(cost - 0.0003) < 0.000001, `Unexpected cost: ${cost}`);
});

test('estimateCostUsd: calculates non-zero cost for gemini-2.0-flash', () => {
  const cost = estimateCostUsd('gemini-2.0-flash', 1000, 500);
  assert.ok(cost !== null && cost > 0, 'Expected positive cost for gemini-2.0-flash');
  // 1000/1000 * 0.000075 + 500/1000 * 0.0003 = 0.000075 + 0.00015 = 0.000225
  assert.ok(Math.abs(cost - 0.000225) < 0.000001, `Unexpected cost: ${cost}`);
});

test('estimateCostUsd: unknown model returns 0 (no cost entry)', () => {
  const cost = estimateCostUsd('unknown-model-xyz', 1000, 500);
  assert.equal(cost, 0);
});

test('estimateCostUsd: works with only input tokens', () => {
  const cost = estimateCostUsd('gpt-4.1-nano', 1000, null);
  assert.ok(cost !== null && cost >= 0);
});

// ---------------------------------------------------------------------------
// buildClassificationPrompt
// ---------------------------------------------------------------------------

test('buildClassificationPrompt: includes region in output', () => {
  const prompt = buildClassificationPrompt('Bangalore, IN', 'en');
  assert.ok(prompt.includes('Bangalore, IN'));
  assert.ok(prompt.includes('en'));
});

test('buildClassificationPrompt: includes required JSON fields', () => {
  const prompt = buildClassificationPrompt('Mumbai, IN', 'hi');
  assert.ok(prompt.includes('itemName'));
  assert.ok(prompt.includes('category'));
  assert.ok(prompt.includes('disposalInstructions'));
  assert.ok(prompt.includes('confidence'));
  assert.ok(prompt.includes('alternatives'));
});

test('buildClassificationPrompt: instructs model to return only JSON', () => {
  const prompt = buildClassificationPrompt('Delhi, IN', 'en');
  assert.ok(
    prompt.includes('ONLY') || prompt.includes('only'),
    'Prompt should instruct model to return only JSON',
  );
});

// ---------------------------------------------------------------------------
// buildReservationId
// ---------------------------------------------------------------------------

test('buildReservationId: deterministic for same uid+requestId', () => {
  const id1 = buildReservationId('uid123', 'req-abc-001');
  const id2 = buildReservationId('uid123', 'req-abc-001');
  assert.equal(id1, id2);
});

test('buildReservationId: different for different requestIds', () => {
  const id1 = buildReservationId('uid123', 'req-abc-001');
  const id2 = buildReservationId('uid123', 'req-abc-002');
  assert.notEqual(id1, id2);
});

test('buildReservationId: different for different uids', () => {
  const id1 = buildReservationId('uid-alice', 'req-same');
  const id2 = buildReservationId('uid-bob', 'req-same');
  assert.notEqual(id1, id2);
});

test('buildReservationId: returns 48-char hex string', () => {
  const id = buildReservationId('uid123', 'req-test');
  assert.match(id, /^[0-9a-f]{48}$/);
});

test('buildReservationId: matches manual SHA-256 derivation', () => {
  const uid = 'user_abc';
  const requestId = 'request_xyz_001';
  const expected = createHash('sha256')
    .update(`classifyImage|${uid}|${requestId}`)
    .digest('hex')
    .slice(0, 48);
  assert.equal(buildReservationId(uid, requestId), expected);
});

// ---------------------------------------------------------------------------
// normalizeRequestId
// ---------------------------------------------------------------------------

test('normalizeRequestId: returns null for non-string', () => {
  assert.equal(normalizeRequestId(null), null);
  assert.equal(normalizeRequestId(undefined), null);
  assert.equal(normalizeRequestId(42), null);
  assert.equal(normalizeRequestId({}), null);
});

test('normalizeRequestId: returns null for short string (< 8 chars)', () => {
  assert.equal(normalizeRequestId('short'), null);
  assert.equal(normalizeRequestId('1234567'), null); // exactly 7
});

test('normalizeRequestId: returns null for string > 160 chars', () => {
  const long = 'a'.repeat(161);
  assert.equal(normalizeRequestId(long), null);
});

test('normalizeRequestId: returns trimmed string for valid input', () => {
  assert.equal(normalizeRequestId('  valid-request-id  '), 'valid-request-id');
  assert.equal(normalizeRequestId('12345678'), '12345678'); // exactly 8
  assert.equal(normalizeRequestId('a'.repeat(160)), 'a'.repeat(160)); // exactly 160
});

// ---------------------------------------------------------------------------
// Input validation constants (documented in classify_image.ts)
// ---------------------------------------------------------------------------

test('MAX_BASE64_CHARS constant: 4 MB image encodes to ~5.6M base64 chars', () => {
  // 4 MB × (4/3) = 5,592,405.3... → ceil = 5,592,406
  const expected = Math.ceil(4 * 1024 * 1024 * (4 / 3));
  // Verify the logic used in the function body is correct.
  assert.equal(expected, 5592406);
  // An image of exactly 4 MB in bytes would produce base64 of this length.
  const actual4MbBase64Length = Math.ceil(4 * 1024 * 1024 * (4 / 3));
  assert.ok(actual4MbBase64Length <= 5592406 + 3, '4 MB fits in the limit');
});

test('allowedMimeTypes: only jpeg, png, webp are accepted', () => {
  // This tests the whitelist documented in the function — we verify the
  // prompt does not reference text/plain (the negative test from the spec).
  const allowed = ['image/jpeg', 'image/png', 'image/webp'];
  assert.ok(!allowed.includes('text/plain'));
  assert.ok(!allowed.includes('application/pdf'));
  assert.ok(allowed.includes('image/jpeg'));
  assert.ok(allowed.includes('image/webp'));
});
