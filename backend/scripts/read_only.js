/**
 * A read-only view of a Firestore or Auth instance, used by the production audit and the
 * production backfill dry run so a stray write cannot happen.
 */
const WRITE_METHOD = /^(set|update|delete|create|add|import|revoke|generate|commit|batch|runTransaction|bulkWriter|recursiveDelete)/;
const proxies = new WeakMap();
const targets = new WeakMap();

/**
 * A read-only view of a Firestore or Auth instance and of everything reached through it (refs,
 * snapshots, query results). Every write method throws; assigning or deleting properties throws.
 */
function readOnly(value) {
  if (value === null || (typeof value !== "object" && typeof value !== "function")) return value;
  if (targets.has(value)) return value;
  if (typeof value.then === "function") return value.then(readOnly);
  if (Array.isArray(value)) return value.map(readOnly);
  if (proxies.has(value)) return proxies.get(value);
  const refuse = (what) => {
    throw new Error(`Read-only audit: ${what} is not allowed.`);
  };
  const proxy = new Proxy(value, {
    get(target, prop) {
      if (typeof prop === "string" && WRITE_METHOD.test(prop)) return () => refuse(prop);
      const v = Reflect.get(target, prop, target);
      const own = Object.getOwnPropertyDescriptor(target, prop);
      // Proxy invariant: a frozen data property must be returned as is.
      if (own && !own.configurable && !own.writable) return v;
      if (typeof v !== "function") return readOnly(v);
      return (...args) => readOnly(v.apply(target, args.map((a) => (typeof a === "function"
        ? (...xs) => a(...xs.map(readOnly))
        : targets.get(a) || a))));
    },
    set: (_, prop) => refuse(`setting ${String(prop)}`),
    defineProperty: (_, prop) => refuse(`defining ${String(prop)}`),
    deleteProperty: (_, prop) => refuse(`deleting ${String(prop)}`),
  });
  proxies.set(value, proxy);
  targets.set(proxy, value);
  return proxy;
}

module.exports = { readOnly, WRITE_METHOD };
