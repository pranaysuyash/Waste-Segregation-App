const test = require('node:test');
const assert = require('node:assert/strict');
const functions = require('firebase-functions');

const functionsModule = require('../lib/index.js');
const { __testables } = functionsModule;

const originalEnv = {
  FUNCTIONS_EMULATOR: process.env.FUNCTIONS_EMULATOR,
  HERMES_FORCE_PROD_GUARDRAILS: process.env.HERMES_FORCE_PROD_GUARDRAILS,
  REQUIRE_APPCHECK_CALLABLE: process.env.REQUIRE_APPCHECK_CALLABLE,
  REQUIRE_APPCHECK_HTTP: process.env.REQUIRE_APPCHECK_HTTP,
  ALLOW_INSECURE_FUNCTIONS_BOOT: process.env.ALLOW_INSECURE_FUNCTIONS_BOOT,
};

test.afterEach(() => {
  process.env.FUNCTIONS_EMULATOR = originalEnv.FUNCTIONS_EMULATOR;
  process.env.HERMES_FORCE_PROD_GUARDRAILS = originalEnv.HERMES_FORCE_PROD_GUARDRAILS;
  process.env.REQUIRE_APPCHECK_CALLABLE = originalEnv.REQUIRE_APPCHECK_CALLABLE;
  process.env.REQUIRE_APPCHECK_HTTP = originalEnv.REQUIRE_APPCHECK_HTTP;
  process.env.ALLOW_INSECURE_FUNCTIONS_BOOT = originalEnv.ALLOW_INSECURE_FUNCTIONS_BOOT;
});

// Contract note: validateAppCheckProductionGuardrails is fail-open — it logs a
// warning and lets Functions boot with App Check unenforced. It does NOT throw,
// so a mis-configured deployment degrades with a visible log line instead of a
// crash loop. This test locks in the documented behavior; a future fail-closed
// decision would change the implementation AND this assertion together.
test('validateAppCheckProductionGuardrails warns (does not throw) when production guardrails are missing', () => {
  const originalWarn = functions.logger.warn;
  const warnings = [];
  functions.logger.warn = (msg) => {
    warnings.push(msg);
  };

  try {
    process.env.FUNCTIONS_EMULATOR = 'false';
    process.env.HERMES_FORCE_PROD_GUARDRAILS = 'true';
    delete process.env.REQUIRE_APPCHECK_CALLABLE;
    delete process.env.REQUIRE_APPCHECK_HTTP;
    delete process.env.ALLOW_INSECURE_FUNCTIONS_BOOT;

    assert.doesNotThrow(() => __testables.validateAppCheckProductionGuardrails());
    assert.ok(
      warnings.some((w) => /App Check production guardrail/i.test(String(w))),
      'expected a warning mentioning App Check production guardrail',
    );
  } finally {
    functions.logger.warn = originalWarn;
  }
});

test('validateAppCheckProductionGuardrails passes when both App Check toggles are enabled', () => {
  process.env.FUNCTIONS_EMULATOR = 'false';
  process.env.HERMES_FORCE_PROD_GUARDRAILS = 'true';
  process.env.REQUIRE_APPCHECK_CALLABLE = 'true';
  process.env.REQUIRE_APPCHECK_HTTP = 'true';

  assert.doesNotThrow(() => __testables.validateAppCheckProductionGuardrails());
});
