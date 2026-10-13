interface Window { started: number; count: number }

/** In-memory quota, bounded storage. Production quotas must live in a shared store. */
export class WindowLimiter {
  private readonly windows = new Map<string, Window>();
  constructor(private readonly maxEntries = 10000) {}

  take(key: string, now: number, windowMs: number, max: number): boolean {
    let entry = this.windows.get(key);
    if (!entry || now - entry.started >= windowMs || now < entry.started) {
      this.windows.delete(key);
      if (this.windows.size >= this.maxEntries) {
        const oldest = this.windows.keys().next().value;
        if (oldest !== undefined) this.windows.delete(oldest);
      }
      entry = { started: now, count: 0 };
      this.windows.set(key, entry);
    }
    if (entry.count >= max) return false;
    entry.count += 1;
    return true;
  }
}
