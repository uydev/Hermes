const test = require('node:test');
const assert = require('node:assert/strict');

const { buildApp } = require('../dist/server');

function makeEnv() {
  return {
    PORT: 3001,
    NODE_ENV: 'test',
    HERMES_JWT_SECRET: '0123456789abcdef0123456789abcdef',
    LIVEKIT_URL: undefined,
    LIVEKIT_API_KEY: undefined,
    LIVEKIT_API_SECRET: undefined,
  };
}

test('GET /health returns ok', async () => {
  const app = buildApp({ logger: false, env: makeEnv() });
  const res = await app.inject({ method: 'GET', url: '/health' });

  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.json(), { ok: true });

  await app.close();
});
