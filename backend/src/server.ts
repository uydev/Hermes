import Fastify, { type FastifyInstance } from 'fastify';
import cors from '@fastify/cors';

export type BuildOptions = {
  logger?: boolean;
};

export function buildApp(opts: BuildOptions = {}): FastifyInstance {
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

  return app;
}
