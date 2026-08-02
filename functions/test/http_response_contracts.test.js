const test = require('node:test');
const assert = require('node:assert/strict');
const {
  respondWithApiError,
  respondWithApiSuccess,
} = require('../lib/helpers');

const makeResponse = () => {
  const state = {
    headers: Object.create(null),
    statusCode: null,
    payload: null,
  };

  const response = {
    setHeader: (key, value) => {
      state.headers[key] = value;
    },
    status: (code) => {
      state.statusCode = code;
      return response;
    },
    json: (body) => {
      state.payload = body;
    },
    __state: state,
  };

  return response;
};

test('respondWithApiSuccess emits canonical success envelope', async () => {
  const response = makeResponse();
  const payload = { status: 'ok', timestamp: '2026-01-01T00:00:00.000Z' };
  respondWithApiSuccess(response, 200, payload);

  assert.equal(response.__state.statusCode, 200);
  assert.equal(response.__state.payload.success, true);
  assert.equal(response.__state.payload.data.status, 'ok');
  assert.equal(response.__state.payload.data.timestamp, payload.timestamp);
  assert.equal(typeof response.__state.payload.request_id, 'string');
  assert.equal(response.__state.payload.version, 'v1');
  assert.equal(typeof response.__state.payload.timestamp, 'string');
  assert.equal(response.__state.headers['x-request-id'], response.__state.payload.request_id);
  assert.equal(response.__state.headers['x-api-version'], 'v1');
});

test('respondWithApiError emits canonical failure envelope and rate-limit headers', async () => {
  const response = makeResponse();
  const details = {
    reason: 'token expired',
    attempts: 3,
    debug: { nested: 'ignore' },
  };

  respondWithApiError(response, 429, 'RATE_LIMITED', 'Too many requests', details, 12);

  assert.equal(response.__state.statusCode, 429);
  assert.equal(response.__state.payload.success, false);
  assert.equal(response.__state.payload.error.code, 'RATE_LIMITED');
  assert.equal(response.__state.payload.error.message, 'Too many requests');
  assert.equal(response.__state.payload.error.retry_after_seconds, 12);
  assert.equal(response.__state.payload.error.details.reason, 'token expired');
  assert.equal(response.__state.payload.error.details.attempts, 3);
  assert.equal(response.__state.headers['Retry-After'], '12');
  assert.equal(response.__state.headers['X-RateLimit-Remaining'], '0');
  assert.equal(response.__state.headers['X-RateLimit-Limit'], '');
  assert.equal(response.__state.headers['X-RateLimit-Reset'], '12');
  assert.equal(response.__state.headers['x-request-id'], response.__state.payload.request_id);
  assert.equal(response.__state.headers['x-api-version'], 'v1');
  assert.equal(response.__state.payload.error.details.debug, undefined);
});
