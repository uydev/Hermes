import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const EnvSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).optional(),
  PORT: z
    .string()
    .optional()
    .transform((v) => (v ? Number(v) : 3001))
    .refine((v) => Number.isFinite(v) && v > 0 && v < 65536, 'PORT must be a valid TCP port'),

  // Used to sign Hermes guest JWTs (MVP auth)
  HERMES_JWT_SECRET: z.string().min(16).optional(),

  // LiveKit token signing (set when you reach Phase 2)
  LIVEKIT_URL: z.string().url().optional(),
  LIVEKIT_API_KEY: z.string().min(1).optional(),
  LIVEKIT_API_SECRET: z.string().min(1).optional(),
});

export type Env = z.infer<typeof EnvSchema>;

export function loadEnv(): Env {
  const parsed = EnvSchema.safeParse(process.env);
  if (!parsed.success) {
    const msg = parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('\n');
    throw new Error(`Invalid environment variables:\n${msg}`);
  }
  return parsed.data;
}
