import Fastify, { type FastifyInstance } from 'fastify';
import cors from '@fastify/cors';
import { loadEnv, type Env } from './env';
import { authRoutes } from './routes/auth';
import { roomsRoutes } from './routes/rooms';

export type BuildOptions = {
  logger?: boolean;
  env?: Env;
};

export function buildApp(opts: BuildOptions = {}): FastifyInstance {
  const env = opts.env ?? loadEnv();
  const app = Fastify({
    logger: opts.logger ?? true,
  });

  app.register(cors, {
    origin: true,
    credentials: true,
  });

  app.get('/health', async () => {
    return { ok: true };
  });

  app.register(authRoutes, { env });
  app.register(roomsRoutes, { env });

  return app;
}
