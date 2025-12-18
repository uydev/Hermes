import { type FastifyPluginAsync } from 'fastify';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import { type Env } from '../env';
import { getBearerToken, verifyHermesToken } from '../auth/hermesAuth';

function requireLiveKitConfig(env: Env): { url: string; apiKey: string; apiSecret: string } {
  const url = env.LIVEKIT_URL;
  const apiKey = env.LIVEKIT_API_KEY;
  const apiSecret = env.LIVEKIT_API_SECRET;

  if (!url) throw new Error('Server misconfigured: LIVEKIT_URL must be set');
  if (!apiKey) throw new Error('Server misconfigured: LIVEKIT_API_KEY must be set');
  if (!apiSecret) throw new Error('Server misconfigured: LIVEKIT_API_SECRET must be set');

  return { url, apiKey, apiSecret };
}

const RoomsJoinRequestSchema = z
  .object({
    // MVP: client can omit; we default to the room in the Hermes JWT.
    room: z.string().trim().min(1).max(64).optional(),
  })
  .optional();

export const roomsRoutes: FastifyPluginAsync<{ env: Env }> = async (app, opts) => {
  app.post('/rooms/join', async (req, reply) => {
    const token = getBearerToken(req.headers.authorization);
    if (!token) {
      return reply.status(401).send({
        error: 'UNAUTHORIZED',
        message: 'Missing Authorization: Bearer <token> header.',
      });
    }

    let claims;
    try {
      claims = verifyHermesToken(token, opts.env);
    } catch {
      return reply.status(401).send({
        error: 'UNAUTHORIZED',
        message: 'Invalid or expired Hermes token.',
      });
    }

    const parsedBody = RoomsJoinRequestSchema.safeParse(req.body);
    if (!parsedBody.success) {
      return reply.status(400).send({
        error: 'BAD_REQUEST',
        message: 'Invalid request body.',
        issues: parsedBody.error.issues.map((i) => ({ path: i.path, message: i.message })),
      });
    }

    const { url, apiKey, apiSecret } = requireLiveKitConfig(opts.env);
    const room = parsedBody.data?.room ?? claims.room;

    // Permissions will evolve; MVP defaults are generous.
    const canPublish = true;
    const canSubscribe = true;

    const now = Math.floor(Date.now() / 1000);
    const expiresInSeconds = 60 * 60;

    // LiveKit Access Token (JWT)
    // - iss: API key
    // - sub: participant identity
    // - name: display name
    // - video grants: room join + perms
    const liveKitToken = jwt.sign(
      {
        name: claims.displayName,
        video: {
          room,
          roomJoin: true,
          canPublish,
          canSubscribe,
        },
      },
      apiSecret,
      {
        algorithm: 'HS256',
        issuer: apiKey,
        subject: claims.sub,
        expiresIn: expiresInSeconds,
      },
    );

    return reply.status(200).send({
      liveKitUrl: url,
      liveKitToken,
      expiresInSeconds,
      identity: claims.sub,
      displayName: claims.displayName,
      room,
      role: claims.role,
    });
  });
};
