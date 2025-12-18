const test = require('node:test');
const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');

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

test('POST /auth/guest issues a Hermes JWT', async () => {
  const env = makeEnv();
  const app = buildApp({ logger: false, env });

  const res = await app.inject({
    method: 'POST',
    url: '/auth/guest',
    payload: {
      displayName: 'Ada',
      room: 'demo-room',
      desiredRole: 'host',
    },
  });

  assert.equal(res.statusCode, 200);
  const body = res.json();

  assert.ok(body.token);
  assert.equal(body.displayName, 'Ada');
  assert.equal(body.room, 'demo-room');
  assert.equal(body.role, 'host');
  assert.ok(body.identity);
  assert.ok(body.expiresAt);

  const verified = jwt.verify(body.token, env.HERMES_JWT_SECRET, {
    issuer: 'hermes-backend',
    audience: 'hermes-client',
  });

  assert.equal(verified.sub, body.identity);
  assert.equal(verified.displayName, 'Ada');
  assert.equal(verified.room, 'demo-room');
  assert.equal(verified.role, 'host');

  await app.close();
});

test('POST /auth/guest rejects invalid room codes', async () => {
  const app = buildApp({ logger: false, env: makeEnv() });

  const res = await app.inject({
    method: 'POST',
    url: '/auth/guest',
    payload: {
      displayName: 'Ada',
      room: 'bad room',
    },
  });

  assert.equal(res.statusCode, 400);
  const body = res.json();
  assert.equal(body.error, 'BAD_REQUEST');

  await app.close();
});
