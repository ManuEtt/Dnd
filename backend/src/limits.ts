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
        // Reclaim only expired entries. Evicting an active entry would reset
        // that principal's quota and let key churn bypass the rate limit.
        for (const [otherKey, window] of this.windows) {
          if (now < window.started || now - window.started >= windowMs) {
            this.windows.delete(otherKey);
          }
        }
        // Fail closed if every slot is still active; never remove live quotas.
        if (this.windows.size >= this.maxEntries) return false;
      }
      entry = { started: now, count: 0 };
      this.windows.set(key, entry);
    }
    if (entry.count >= max) return false;
    entry.count += 1;
    return true;
  }
}
