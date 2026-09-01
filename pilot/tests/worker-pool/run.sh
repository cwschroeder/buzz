#!/usr/bin/env bash
set -euo pipefail

PILOT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/buzz-pilot-worker-pool-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

export BUZZ_PILOT_STATE_DIR="${TEST_ROOT}/state"
export BUZZ_PILOT_REPO_CONFIG_DIR="${TEST_ROOT}/repos"
export BUZZ_PILOT_WORKTREE_ROOT="${TEST_ROOT}/worktrees"
mkdir -p "$BUZZ_PILOT_STATE_DIR" "$BUZZ_PILOT_REPO_CONFIG_DIR" "$BUZZ_PILOT_WORKTREE_ROOT"

# Load only the contract functions from common, not the whole runtime.
COMMON_SOURCE="$(sed -n '/^# --- worker pool contract ---/,$p' "${PILOT_ROOT}/bin/common")"
if [[ -z "$COMMON_SOURCE" ]]; then
  echo "worker pool contract section not found in pilot/bin/common" >&2
  exit 1
fi
eval "$COMMON_SOURCE"

pass=0; fail=0
check() { # check <name> <expected-exit> <cmd...>
  local name="$1" expected="$2"; shift 2
  local rc
  if "$@" >/dev/null 2>&1; then rc=0; else rc=$?; fi
  if [[ "$rc" == "$expected" ]]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: $name (rc=$rc, expected $expected)"; fi
}

# --- Schema ---

# Schema 1 accepted: valid bounds.
PILOT_REPO_WORKER_POOL_SCHEMA_VERSION=1 \
PILOT_REPO_ID=demo \
WORKERS_MIN=1 WORKERS_MAX=3 \
check "schema1-valid-bounds" 0 pilot_worker_pool_validate

# Schema 0 rejected: unknown schema version fails closed.
PILOT_REPO_WORKER_POOL_SCHEMA_VERSION=0 \
PILOT_REPO_ID=demo \
WORKERS_MIN=1 WORKERS_MAX=3 \
check "schema0-rejected" 1 pilot_worker_pool_validate

# Unset schema rejected (POSIX sh lacks `env -u`; use a subshell instead).
PILOT_REPO_WORKER_POOL_SCHEMA_VERSION=1 \
  PILOT_REPO_ID=demo WORKERS_MIN=1 WORKERS_MAX=3 \
  check "schema-unset-rejected-baseline" 0 pilot_worker_pool_validate
(
  unset PILOT_REPO_WORKER_POOL_SCHEMA_VERSION
  PILOT_REPO_ID=demo WORKERS_MIN=1 WORKERS_MAX=3 \
    check "schema-unset-rejected" 1 pilot_worker_pool_validate
)

# --- Bounds ---

# min > max is invalid.
PILOT_REPO_WORKER_POOL_SCHEMA_VERSION=1 \
PILOT_REPO_ID=demo \
WORKERS_MIN=4 WORKERS_MAX=3 \
check "min-gt-max-rejected" 1 pilot_worker_pool_validate

# Zero or negative bounds are invalid.
PILOT_REPO_WORKER_POOL_SCHEMA_VERSION=1 \
PILOT_REPO_ID=demo \
WORKERS_MIN=0 WORKERS_MAX=3 \
check "zero-min-rejected" 1 pilot_worker_pool_validate
PILOT_REPO_WORKER_POOL_SCHEMA_VERSION=1 \
PILOT_REPO_ID=demo \
WORKERS_MIN=1 WORKERS_MAX=-1 \
check "negative-max-rejected" 1 pilot_worker_pool_validate

# Non-numeric bounds are invalid.
PILOT_REPO_WORKER_POOL_SCHEMA_VERSION=1 \
PILOT_REPO_ID=demo \
WORKERS_MIN=abc WORKERS_MAX=3 \
check "nonnumeric-min-rejected" 1 pilot_worker_pool_validate

# --- Desired lease ---

# Valid future lease is accepted; desired must lie within [min,max].
PILOT_REPO_WORKER_POOL_SCHEMA_VERSION=1 \
PILOT_REPO_ID=demo \
WORKERS_MIN=1 WORKERS_MAX=3 \
WORKERS_DESIRED=2 \
WORKERS_DESIRED_UNTIL="$(date -u -v+1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '+1 hour' +%Y-%m-%dT%H:%M:%SZ)" \
check "valid-lease-accepted" 0 pilot_worker_pool_validate

# Desired below min is invalid.
PILOT_REPO_WORKER_POOL_SCHEMA_VERSION=1 \
PILOT_REPO_ID=demo \
WORKERS_MIN=2 WORKERS_MAX=3 \
WORKERS_DESIRED=1 \
WORKERS_DESIRED_UNTIL="$(date -u -v+1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '+1 hour' +%Y-%m-%dT%H:%M:%SZ)" \
check "desired-below-min-rejected" 1 pilot_worker_pool_validate

# Desired above max is invalid.
PILOT_REPO_WORKER_POOL_SCHEMA_VERSION=1 \
PILOT_REPO_ID=demo \
WORKERS_MIN=1 WORKERS_MAX=3 \
WORKERS_DESIRED=5 \
WORKERS_DESIRED_UNTIL="$(date -u -v+1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '+1 hour' +%Y-%m-%dT%H:%M:%SZ)" \
check "desired-above-max-rejected" 1 pilot_worker_pool_validate

# Expired lease is rejected: WORKERS_MIN applies instead.
PILOT_REPO_WORKER_POOL_SCHEMA_VERSION=1 \
PILOT_REPO_ID=demo \
WORKERS_MIN=1 WORKERS_MAX=3 \
WORKERS_DESIRED=2 \
WORKERS_DESIRED_UNTIL="$(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '-1 hour' +%Y-%m-%dT%H:%M:%SZ)" \
check "expired-lease-rejected" 1 pilot_worker_pool_validate

# Malformed lease timestamp is rejected.
PILOT_REPO_WORKER_POOL_SCHEMA_VERSION=1 \
PILOT_REPO_ID=demo \
WORKERS_MIN=1 WORKERS_MAX=3 \
WORKERS_DESIRED=2 \
WORKERS_DESIRED_UNTIL="not-a-date" \
check "malformed-lease-rejected" 1 pilot_worker_pool_validate

# No lease: valid, falls back to WORKERS_MIN.
PILOT_REPO_WORKER_POOL_SCHEMA_VERSION=1 \
PILOT_REPO_ID=demo \
WORKERS_MIN=1 WORKERS_MAX=3 \
check "no-lease-valid" 0 pilot_worker_pool_validate

# Effective count without lease = min.
PILOT_REPO_WORKER_POOL_SCHEMA_VERSION=1 \
PILOT_REPO_ID=demo \
WORKERS_MIN=2 WORKERS_MAX=3 \
count="$(pilot_worker_pool_effective 2>/dev/null)"
[[ "$count" == "2" ]] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: effective-no-lease (got '$count', want 2)"; }

# Effective count with valid lease = desired.
FUTURE="$(date -u -v+1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '+1 hour' +%Y-%m-%dT%H:%M:%SZ)"
PILOT_REPO_WORKER_POOL_SCHEMA_VERSION=1 \
PILOT_REPO_ID=demo \
WORKERS_MIN=1 WORKERS_MAX=3 \
WORKERS_DESIRED=3 \
WORKERS_DESIRED_UNTIL="$FUTURE" \
count="$(pilot_worker_pool_effective 2>/dev/null)"
[[ "$count" == "3" ]] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: effective-with-lease (got '$count', want 3)"; }

# Effective count with expired lease = min.
PAST="$(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '-1 hour' +%Y-%m-%dT%H:%M:%SZ)"
PILOT_REPO_WORKER_POOL_SCHEMA_VERSION=1 \
PILOT_REPO_ID=demo \
WORKERS_MIN=2 WORKERS_MAX=3 \
WORKERS_DESIRED=3 \
WORKERS_DESIRED_UNTIL="$PAST" \
count="$(pilot_worker_pool_effective 2>/dev/null)"
[[ "$count" == "2" ]] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: effective-expired-lease (got '$count', want 2)"; }

# --- Name collision ---

# A session name that collides with an existing tmux session fails closed.
command -v tmux >/dev/null 2>&1 || { echo "FAIL: tmux missing for collision test"; fail=$((fail+1)); }
if command -v tmux >/dev/null 2>&1; then
  existing="wp-collision-probe"
  tmux kill-session -t "$existing" 2>/dev/null || true
  tmux new-session -d -s "$existing" true
  # Session naming: <repo-session>-wNN. pilot_worker_pool_session_name builds
  # the name; collision check must reject an existing session.
  PILOT_REPO_SESSION=wp-demo \
  PILOT_REPO_WORKER_POOL_SCHEMA_VERSION=1 \
  PILOT_REPO_ID=demo \
  WORKERS_MIN=1 WORKERS_MAX=3 \
  name="$(pilot_worker_pool_session_name 1 2>/dev/null)"
  [[ "$name" == "wp-demo-w01" ]] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: session-name-format (got '$name')"; }

  if pilot_worker_pool_session_exists "$name" 2>/dev/null; then
    fail=$((fail+1)); echo "FAIL: collision not detected for $name"
  else
    pass=$((pass+1))
  fi

  tmux new-session -d -s "$name" true
  if pilot_worker_pool_session_exists "$name" 2>/dev/null; then
    pass=$((pass+1))
  else
    fail=$((fail+1)); echo "FAIL: existing session not detected"
  fi
  tmux kill-session -t "$name" 2>/dev/null || true
  tmux kill-session -t "$existing" 2>/dev/null || true
fi

# --- Worktree isolation ---

# Deterministic per-repo worktree path, isolated under the test root.
PILOT_REPO_ID=demo \
wt="$(pilot_worker_pool_worktree_path 2>/dev/null)"
[[ "$wt" == "${BUZZ_PILOT_WORKTREE_ROOT}/demo/w01" ]] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL: worktree-path (got '$wt')"; }

# An existing non-empty worktree directory is rejected (no shared write paths).
mkdir -p "${BUZZ_PILOT_WORKTREE_ROOT}/demo/w01"
printf 'x' > "${BUZZ_PILOT_WORKTREE_ROOT}/demo/w01/file"
if pilot_worker_pool_worktree_free "${BUZZ_PILOT_WORKTREE_ROOT}/demo/w01" 2>/dev/null; then
  fail=$((fail+1)); echo "FAIL: occupied worktree accepted"
else
  pass=$((pass+1))
fi

# A fresh path is free.
if pilot_worker_pool_worktree_free "${BUZZ_PILOT_WORKTREE_ROOT}/demo/w02" 2>/dev/null; then
  pass=$((pass+1))
else
  fail=$((fail+1)); echo "FAIL: fresh worktree not free"
fi

echo "worker-pool: ${pass} passed, ${fail} failed"
[[ "$fail" -eq 0 ]]
