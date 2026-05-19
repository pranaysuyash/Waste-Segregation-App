const test = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const request = require('supertest');
const admin = require('firebase-admin');
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

function makeAppFromHandler(handler) {
  const app = express();
  app.use(express.json());
  app.all('*', (req, res) => handler(req, res));
  return app;
}

function stubVerifyIdToken(impl) {
  const authObj = admin.auth();
  const originalVerify = authObj.verifyIdToken;
  authObj.verifyIdToken = impl;
  return () => {
    authObj.verifyIdToken = originalVerify;
  };
}

test.afterEach(() => {
  resetEnv();
});

test('generateDisposal blocks unauthenticated POST when auth required', async () => {
  process.env.DISPOSAL_API_REQUIRE_AUTH = 'true';
  process.env.ALLOW_ANONYMOUS_DISPOSAL = 'false';

  const app = makeAppFromHandler(functionsModule.generateDisposal);

  const res = await request(app)
    .post('/')
    .send({ materialId: 'm-1', material: 'paper' });

  assert.equal(res.status, 401);
  assert.match(res.body.error, /Bearer token required/);
});

test('generateDisposal blocks invalid bearer token when auth required', async () => {
  process.env.DISPOSAL_API_REQUIRE_AUTH = 'true';
  process.env.ALLOW_ANONYMOUS_DISPOSAL = 'false';

  const restoreAuth = stubVerifyIdToken(async () => {
    throw new Error('bad token');
  });
  const app = makeAppFromHandler(functionsModule.generateDisposal);

  const res = await request(app)
    .post('/')
    .set('Authorization', 'Bearer invalid.token')
    .send({ materialId: 'm-2', material: 'plastic' });

  restoreAuth();
  assert.equal(res.status, 401);
  assert.match(res.body.error, /invalid token/);
});

test('testOpenAI returns 403 when diagnostics are disabled', async () => {
  process.env.ENABLE_DIAGNOSTIC_ENDPOINTS = 'false';

  const app = makeAppFromHandler(functionsModule.testOpenAI);
  const res = await request(app).get('/');

  assert.equal(res.status, 403);
  assert.equal(res.body.error, 'Diagnostics disabled');
});

test('testOpenAI returns 403 for non-admin token when diagnostics enabled', async () => {
  process.env.ENABLE_DIAGNOSTIC_ENDPOINTS = 'true';

  const restoreAuth = stubVerifyIdToken(async () => ({ uid: 'u1', admin: false }));
  const app = makeAppFromHandler(functionsModule.testOpenAI);

  const res = await request(app)
    .get('/')
    .set('Authorization', 'Bearer valid.nonadmin.token');

  restoreAuth();
  assert.equal(res.status, 403);
  assert.equal(res.body.error, 'Forbidden: admin token required');
});

test('generateDisposal allows authenticated request to reach method guard', async () => {
  process.env.DISPOSAL_API_REQUIRE_AUTH = 'true';
  process.env.ALLOW_ANONYMOUS_DISPOSAL = 'false';

  const restoreAuth = stubVerifyIdToken(async () => ({ uid: 'u-auth' }));
  const app = makeAppFromHandler(functionsModule.generateDisposal);

  const res = await request(app)
    .get('/')
    .set('Authorization', 'Bearer valid.user.token');

  restoreAuth();
  assert.equal(res.status, 405);
  assert.equal(res.body.error, 'Method not allowed');
});

test('testOpenAI returns minimal success payload for admin token when enabled', async () => {
  process.env.ENABLE_DIAGNOSTIC_ENDPOINTS = 'true';
  process.env.OPENAI_API_KEY = 'test-key';

  const restoreAuth = stubVerifyIdToken(async () => ({ uid: 'admin-1', admin: true }));
  const app = makeAppFromHandler(functionsModule.testOpenAI);

  const res = await request(app)
    .get('/')
    .set('Authorization', 'Bearer valid.admin.token');

  restoreAuth();
  assert.equal(res.status, 200);
  assert.equal(res.body.status, 'ok');
  assert.equal(res.body.openaiConfigured, true);
  assert.ok(typeof res.body.timestamp === 'string' && res.body.timestamp.length > 0);
  assert.equal('keySource' in res.body, false);
  assert.equal('keyLength' in res.body, false);
});
