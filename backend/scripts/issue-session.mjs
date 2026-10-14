// Run on the backend host. Only the short-lived session token is printed;
// the server access credential and provider API keys remain on the server.
const access = process.env.LOCAL_ACCESS_TOKEN;
if (!access) {
  console.error('LOCAL_ACCESS_TOKEN ist auf dem Server nicht konfiguriert.');
  process.exitCode = 1;
} else {
  try {
    const port = Number(process.env.PORT || 3000);
    if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error();
    const response = await fetch(`http://127.0.0.1:${port}/v1/session`, {
      method: 'POST',
      redirect: 'error',
      headers: { Authorization: `Bearer ${access}`, 'Content-Type': 'application/json' },
      body: '{}',
      signal: AbortSignal.timeout(10000),
    });
    if (!response.ok) throw new Error();
    const session = await response.json();
    if (typeof session.token !== 'string' || typeof session.expiresAt !== 'string') {
      throw new Error();
    }
    console.log(session.token);
    console.error(`Kurzlebige Sitzung; gültig bis ${session.expiresAt}. Nur in der App verwenden.`);
  } catch {
    console.error('Sitzung konnte nicht ausgestellt werden. Prüfe Serverstart und Serverzugang.');
    process.exitCode = 1;
  }
}
