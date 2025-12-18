import { type FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { type Env } from '../env';
import jwt from 'jsonwebtoken';
import crypto from 'node:crypto';

const GuestAuthRequestSchema = z.object({
  displayName: z.string().trim().min(1).max(64),
  room: z
    .string()
    .trim()
    .min(1)
    .max(64)
    .regex(/^[a-zA-Z0-9_-]+$/, 'room must be URL-safe (letters, numbers, _ or -)'),
  desiredRole: z.enum(['host', 'participant']).optional(),
});

type GuestAuthRequest = z.infer<typeof GuestAuthRequestSchema>;

function requireJwtSecret(env: Env): string {
  const secret = env.HERMES_JWT_SECRET;
  if (!secret || secret.trim().length < 16) {
    throw new Error(
      'Server misconfigured: HERMES_JWT_SECRET must be set (min 16 chars) to issue guest tokens.',
    );
  }
  return secret;
}

export const authRoutes: FastifyPluginAsync<{ env: Env }> = async (app, opts) => {
  app.post('/auth/guest', async (req, reply) => {
    const parsed = GuestAuthRequestSchema.safeParse(req.body);
    if (!parsed.success) {
      return reply.status(400).send({
        error: 'BAD_REQUEST',
        message: 'Invalid request body.',
        issues: parsed.error.issues.map((i) => ({ path: i.path, message: i.message })),
      });
    }

    const body: GuestAuthRequest = parsed.data;
    const role = body.desiredRole ?? 'participant';

    // Stable identity for the duration of the guest session.
    const identity = crypto.randomUUID();

    const secret = requireJwtSecret(opts.env);

    const issuedAt = Math.floor(Date.now() / 1000);
    const expiresInSeconds = 60 * 60; // 60 minutes (MVP default)
    const expiresAt = issuedAt + expiresInSeconds;

    const token = jwt.sign(
      {
        displayName: body.displayName,
        room: body.room,
        role,
      },
      secret,
      {
        algorithm: 'HS256',
        issuer: 'hermes-backend',
        audience: 'hermes-client',
        subject: identity,
        expiresIn: expiresInSeconds,
      },
    );

    return reply.status(200).send({
      token,
      expiresAt,
      expiresInSeconds,
      identity,
      displayName: body.displayName,
      room: body.room,
      role,
    });
  });
};
