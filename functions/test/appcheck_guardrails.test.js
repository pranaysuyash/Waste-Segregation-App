const test = require('node:test');
const assert = require('node:assert/strict');

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

test('validateAppCheckProductionGuardrails throws when production guardrails are missing', () => {
  process.env.FUNCTIONS_EMULATOR = 'false';
  process.env.HERMES_FORCE_PROD_GUARDRAILS = 'true';
  delete process.env.REQUIRE_APPCHECK_CALLABLE;
  delete process.env.REQUIRE_APPCHECK_HTTP;
  delete process.env.ALLOW_INSECURE_FUNCTIONS_BOOT;

  assert.throws(
    () => __testables.validateAppCheckProductionGuardrails(),
    /App Check production guardrail violation/i,
  );
});

test('validateAppCheckProductionGuardrails passes when both App Check toggles are enabled', () => {
  process.env.FUNCTIONS_EMULATOR = 'false';
  process.env.HERMES_FORCE_PROD_GUARDRAILS = 'true';
  process.env.REQUIRE_APPCHECK_CALLABLE = 'true';
  process.env.REQUIRE_APPCHECK_HTTP = 'true';

  assert.doesNotThrow(() => __testables.validateAppCheckProductionGuardrails());
});
