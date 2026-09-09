# Deployment

Dieses Runbook beschreibt den privaten Buzz-Backend-Betrieb auf Mac Studio 2.

## Build und Runtime

- Checkout: `/Users/cschroeder/Github/buzz`, Branch `customizing/cschroeder`
- Build: `cargo build --release --locked -p buzz-relay -p buzz-pair-relay`
- Dienste: `com.buzz.relay` und `com.buzz.pair-relay`
- Öffentliche URL: `https://macstudio-2.taila89eb3.ts.net`
- Lokale Readiness: `http://127.0.0.1:8088/_readiness`
- PostgreSQL: Container `buzz-pilot-postgres`, Port `127.0.0.1:55432`

Vor jedem Neustart wird ein PostgreSQL-Custom-Format-Dump erzeugt und mit
`pg_restore -l` geprüft. Erst danach dürfen die beiden Relay-Dienste neu
gestartet werden. Konflikte, fehlgeschlagene Tests, Builds oder Backups stoppen
den Lauf; die laufende Produktion bleibt dann unverändert.

## Aktiver Stand

Deployment vom 09.09.2026:

- Customizing-Commit: `ff8c0d36c8a94aa5a68710c82469499ae854793f`
- Enthaltener Upstream: `c045321a7fb3ca8939f28519ce7a555a6f597728`
- `buzz-relay`: SHA-256 `6a9757a35da8f2704e8b3cd2cd94c8ee6451b390405d593ef061d0bfa3f25bd1`
- `buzz-pair-relay`: SHA-256 `66563919d07e72ef62d8d75f8ce235c6c2447310f2c229a8d2031b6743964c74` (unverändert, Inputs seit 31.08. identisch)
- Backup: `/Users/cschroeder/Library/Application Support/Buzz Pilot/backups/buzz-before-ff8c0d3-20260909-034951.dump`
- Backup-SHA-256: `4cf40a59cbf58f60fee67bb7e7a328e943aed3724111ab353a02093cd17fe4cb`
- Migrationen: `1` bis `40`, keine neuen Migrationen im Delta
- Neue PIDs: Pair-Relay `64539`, Relay `64570`
- Nachweise: lokale und öffentliche Readiness `ready`; NIP-11 meldet Buzz Relay
  `0.2.1`; `/api/admin/v1/health` liefert ohne `BUZZ_ADMIN_HOST` weiterhin 404.
  Vorab grün: fmt, Clippy, Tests für `buzz-acp`, `buzz-agent`, `buzz-relay`.

## Rollback

1. Beide Relay-Dienste stoppen, ohne andere Agent- oder tmux-Sitzungen zu
   verändern.
2. Den Code auf Backup-Branch `backup/pre-upstream-20260909`
   (`8f52a3dcc9392640179d25e121bde00465ce54be`) zurücksetzen und beide
   Release-Binaries neu bauen.
3. Falls die Datenbank zurückgesetzt werden muss, den oben genannten, geprüften
   Dump in eine leere Buzz-Datenbank einspielen.
4. Nur `com.buzz.relay` und `com.buzz.pair-relay` starten und lokale sowie
   öffentliche Readiness erneut prüfen.

