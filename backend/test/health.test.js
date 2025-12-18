const test = require('node:test');
const assert = require('node:assert/strict');

const { buildApp } = require('../dist/server');
const { loadEnv } = require('../dist/env');

test('GET /health returns ok', async () => {
  // Loads from backend/.env (dotenv) if present, otherwise from process.env.
  const env = loadEnv();
  const app = buildApp({ logger: false, env });
  const res = await app.inject({ method: 'GET', url: '/health' });

  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.json(), { ok: true });

  await app.close();
});
