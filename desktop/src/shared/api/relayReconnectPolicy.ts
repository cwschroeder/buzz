/**
 * Pure helpers for the relay reconnect policy.
 *
 * Extracted from `RelayClient` so the decision rules — when to schedule a
 * reconnect, when to refuse to connect — live in one legible place that
 * unit tests can reach without booting the WS layer.
 *
 * The rules:
 *
 *  - **Terminal sessions never reconnect.** When the relay has explicitly
 *    rejected us (today: kind:22242 AUTH OK=false) the session is dead
 *    until the user re-engages (community switch or explicit preconnect).
 *    This guards the reconnect-timer catch handler — and the retry wrappers
 *    in `publishEvent` / `sendRawWithReconnectRetry` — from racing the
 *    `disconnected` state back to `reconnecting`.
 *
 *  - **No-op when a reconnect is already scheduled or in progress.**
 *    A pending timer or a live `wsId` means we have nothing to do.
 *
 *  - **No reconnect needed when nothing wants the socket.** No live
 *    subscription, no `keepAliveRequested` from `preconnect()` → don't
 *    keep an idle socket.
 */
export type RelayReconnectInputs = {
  terminal: boolean;
  hasPendingReconnect: boolean;
  hasLiveSocket: boolean;
  keepAliveRequested: boolean;
  hasLiveSubscriptions: boolean;
};

export function shouldScheduleReconnect(inputs: RelayReconnectInputs): boolean {
  if (inputs.terminal) return false;
  if (inputs.hasPendingReconnect) return false;
  if (inputs.hasLiveSocket) return false;
  if (!inputs.keepAliveRequested && !inputs.hasLiveSubscriptions) return false;
  return true;
}

export function shouldWaitForScheduledReconnect(inputs: {
  hasPendingReconnect: boolean;
}): boolean {
  return inputs.hasPendingReconnect;
}

/** Whether `ensureConnected()` should refuse with a terminal error. */
export function shouldRefuseConnect(inputs: { terminal: boolean }): boolean {
  return inputs.terminal;
}

/**
 * Classify an AUTH `OK false` reason (NIP-01 machine-readable prefixes).
 *
 * The relay's ban/membership/allowlist gates fail closed on infrastructure
 * faults and deny with an `error:` reason precisely so an innocent client is
 * NOT told it was rejected — the relay expects a retry once the fault clears.
 * `rate-limited:` is back-pressure and likewise transient. Latching the
 * session terminal on those reasons would permanently stop auto-reconnect
 * over a transient blip, stranding the user on manual reconnect clicks that
 * keep failing until the fault clears.
 *
 * Everything else (`blocked:` ban, `restricted:` not a member,
 * `auth-required:` verification failure, or a missing reason) is a genuine
 * rejection of this identity: stay terminal until the user re-engages.
 */
export function isTerminalAuthRejection(message: string): boolean {
  const normalized = message.trim().toLowerCase();
  return !(
    normalized.startsWith("error:") || normalized.startsWith("rate-limited:")
  );
}

export function isWebSocketClose(
  message: unknown,
): message is { type: "Close"; data?: unknown } {
  return (
    typeof message === "object" &&
    message !== null &&
    "type" in message &&
    message.type === "Close"
  );
}

export function isServiceRestartClose(message: unknown): boolean {
  if (!isWebSocketClose(message)) return false;
  if (!("data" in message)) return false;
  const data = message.data;
  return (
    typeof data === "object" &&
    data !== null &&
    "code" in data &&
    data.code === 1012
  );
}
