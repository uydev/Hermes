const test = require('node:test');
const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');

const { buildApp } = require('../dist/server');

function makeEnv() {
  return {
    PORT: 3001,
    NODE_ENV: 'test',
    HERMES_JWT_SIGNING_KEY: '0123456789abcdef0123456789abcdef',
    LIVEKIT_URL: 'wss://example.livekit.cloud',
    LIVEKIT_API_KEY: 'lk_api_key',
    LIVEKIT_API_SECRET: 'lk_api_secret',
  };
}

function makeHermesToken(env, claims) {
  return jwt.sign(
    {
      displayName: claims.displayName,
      room: claims.room,
      role: claims.role,
    },
    env.HERMES_JWT_SIGNING_KEY,
    {
      algorithm: 'HS256',
      issuer: 'hermes-backend',
      audience: 'hermes-client',
      subject: claims.identity,
      expiresIn: 60 * 60,
    },
  );
}

test('POST /rooms/join returns LiveKit URL + token', async () => {
  const env = makeEnv();
  const app = buildApp({ logger: false, env });

  const hermesToken = makeHermesToken(env, {
    identity: 'user-123',
    displayName: 'Ada',
    room: 'demo-room',
    role: 'host',
  });

  const res = await app.inject({
    method: 'POST',
    url: '/rooms/join',
    headers: {
      authorization: `Bearer ${hermesToken}`,
    },
    payload: {},
  });

  assert.equal(res.statusCode, 200);
  const body = res.json();

  assert.equal(body.liveKitUrl, env.LIVEKIT_URL);
  assert.ok(body.liveKitToken);
  assert.equal(body.identity, 'user-123');
  assert.equal(body.displayName, 'Ada');
  assert.equal(body.room, 'demo-room');
  assert.equal(body.role, 'host');

  const verified = jwt.verify(body.liveKitToken, env.LIVEKIT_API_SECRET, {
    issuer: env.LIVEKIT_API_KEY,
    subject: 'user-123',
  });

  assert.equal(verified.name, 'Ada');
  assert.equal(verified.video.room, 'demo-room');
  assert.equal(verified.video.roomJoin, true);
  assert.equal(verified.video.canPublish, true);
  assert.equal(verified.video.canSubscribe, true);

  await app.close();
});

test('POST /rooms/join requires Authorization header', async () => {
  const app = buildApp({ logger: false, env: makeEnv() });

  const res = await app.inject({
    method: 'POST',
    url: '/rooms/join',
  });

  assert.equal(res.statusCode, 401);

  await app.close();
});
