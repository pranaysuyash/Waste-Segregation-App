const test = require('node:test');
const assert = require('node:assert/strict');
const { __testables } = require('../lib/ops_hardening.js');

const { buildThresholdAlerts } = __testables;

test('buildThresholdAlerts: emits expected alerts when thresholds breached', () => {
  process.env.OPS_ALERT_CLAIMS_FALLBACK_THRESHOLD = '2';
  process.env.OPS_ALERT_APPCHECK_MISSING_THRESHOLD = '1';
  process.env.OPS_ALERT_CLASSIFY_RATE_LIMITED_THRESHOLD = '3';
  process.env.OPS_ALERT_REFUND_RATE_THRESHOLD = '0.20';

  const alerts = buildThresholdAlerts({
    counters: {
      spendUserTokens_claims_fallback: 3,
      appcheck_missing: 2,
      classifyImage_rate_limited: 5,
    },
    refundRate: 0.25,
  });

  const types = alerts.map((a) => a.alertType).sort();
  assert.deepEqual(types, [
    'appcheck_missing_spike',
    'claims_fallback_spike',
    'classify_rate_limit_spike',
    'refund_rate_spike',
  ]);

  delete process.env.OPS_ALERT_CLAIMS_FALLBACK_THRESHOLD;
  delete process.env.OPS_ALERT_APPCHECK_MISSING_THRESHOLD;
  delete process.env.OPS_ALERT_CLASSIFY_RATE_LIMITED_THRESHOLD;
  delete process.env.OPS_ALERT_REFUND_RATE_THRESHOLD;
});

test('buildThresholdAlerts: returns empty list when all metrics below thresholds', () => {
  const alerts = buildThresholdAlerts({
    counters: {
      spendUserTokens_claims_fallback: 0,
      appcheck_missing: 0,
      classifyImage_rate_limited: 0,
    },
    refundRate: 0,
  });

  assert.equal(alerts.length, 0);
});
