import { loadEnv } from './env';
import { buildApp } from './server';

async function main() {
  const env = loadEnv();

  const app = buildApp({
    logger: env.NODE_ENV !== 'test',
  });

  await app.listen({
    port: env.PORT,
    host: '0.0.0.0',
  });
}

main().catch((err) => {
  // eslint-disable-next-line no-console
  console.error(err);
  process.exit(1);
});
