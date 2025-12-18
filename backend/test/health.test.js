const test = require('node:test');
const assert = require('node:assert/strict');

const { buildApp } = require('../dist/server');

test('GET /health returns ok', async () => {
  const app = buildApp({ logger: false });
  const res = await app.inject({ method: 'GET', url: '/health' });

  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.json(), { ok: true });

  await app.close();
});
