const test = require('node:test');
const assert = require('node:assert/strict');

const functionsModule = require('../lib/index.js');

const originalEnv = { ...process.env };

function resetEnv() {
  for (const key of Object.keys(process.env)) {
    if (!(key in originalEnv)) {
      delete process.env[key];
    }
  }
  for (const [key, value] of Object.entries(originalEnv)) {
    process.env[key] = value;
  }
}

test.afterEach(() => {
  resetEnv();
});

test('getOpenAiApiKey prefers OPENAI_API_KEY over OPENAI_KEY', () => {
  process.env.OPENAI_API_KEY = 'primary-key';
  process.env.OPENAI_KEY = 'secondary-key';

  const resolved = functionsModule.getOpenAiApiKey();
  assert.equal(resolved, 'primary-key');
});

test('getOpenAiApiKey falls back to OPENAI_KEY when OPENAI_API_KEY missing', () => {
  delete process.env.OPENAI_API_KEY;
  process.env.OPENAI_KEY = 'secondary-key';

  const resolved = functionsModule.getOpenAiApiKey();
  assert.equal(resolved, 'secondary-key');
});

test('getOpenAiApiKey returns undefined when no env key is present', () => {
  delete process.env.OPENAI_API_KEY;
  delete process.env.OPENAI_KEY;

  const resolved = functionsModule.getOpenAiApiKey();
  assert.equal(resolved, undefined);
});
