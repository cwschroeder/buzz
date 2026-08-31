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

Deployment vom 31.08.2026:

- Customizing-Commit: `56d251991ccf4c4bed0b19243cd082a1f94cf3ed`
- Enthaltener Upstream: `c3132c3ee982d194cd0198ad07b57ec8bd726e4e`
- `buzz-relay`: SHA-256 `99b59e9d04fafd200348bfdafc466f482b9d1a110897be231bb76d78c36f7ab1`
- `buzz-pair-relay`: SHA-256 `66563919d07e72ef62d8d75f8ce235c6c2447310f2c229a8d2031b6743964c74`
- Backup: `/Users/cschroeder/Library/Application Support/Buzz Pilot/backups/buzz-before-56d2519-20260831-165256.dump`
- Backup-SHA-256: `6a0b32b46474808c888503070a90f9dca14d72f7604481e110782363329c5596`
- Migrationen: `1` bis `40`, vollständig angewendet
- Neue PIDs: Pair-Relay `65589`, Relay `65603`
- Nachweise: lokale und öffentliche Readiness `ready`; NIP-11 meldet Buzz Relay
  `0.2.1`; `/api/admin/v1/health` liefert ohne `BUZZ_ADMIN_HOST` weiterhin 404.

## Rollback

1. Beide Relay-Dienste stoppen, ohne andere Agent- oder tmux-Sitzungen zu
   verändern.
2. Den Code auf Backup-Branch `backup/manual-pre-sync-20260831-1611`
   (`af1cc71a13456e84d03cc41141a4a06de6ac551f`) zurücksetzen und beide
   Release-Binaries neu bauen.
3. Falls die Datenbank zurückgesetzt werden muss, den oben genannten, geprüften
   Dump in eine leere Buzz-Datenbank einspielen.
4. Nur `com.buzz.relay` und `com.buzz.pair-relay` starten und lokale sowie
   öffentliche Readiness erneut prüfen.

