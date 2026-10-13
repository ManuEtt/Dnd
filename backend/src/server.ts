import { buildApp } from './app.js';
import { readConfig } from './config.js';

async function main() {
  const config = readConfig();
  const app = buildApp(config);
  for (const signal of ['SIGINT', 'SIGTERM'] as const) {
    process.once(signal, () => {
      void app.close().then(() => process.exit(0));
    });
  }
  await app.listen({ host: config.host, port: config.port });
  console.info(`Spielleiter-Backend auf ${config.host}:${config.port}; Provider: ${config.provider}`);
  if (!config.accessToken) console.info('POST /v1/session bleibt gesperrt, bis LOCAL_ACCESS_TOKEN gesetzt ist.');
}
main().catch(() => {
  // Config errors are intentionally reduced to a safe message without secret values.
  console.error('Backendstart fehlgeschlagen. Prüfe Konfiguration und freie Ports gemäß backend/README.md.');
  process.exitCode = 1;
});
