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

WICHTIG: Die Postgres-Lane `cargo test -p buzz-db -- --ignored` zerstört die
unter `DATABASE_URL` benannte Datenbank (siehe LEARNINGS.md 2026-09-18). Sie
gehört ausschließlich gegen eine Wegwerf-Kratzdatenbank, nie gegen `buzz`.

## Aktiver Stand

Deployment vom 18.09.2026:

- Customizing-Commit: `0305a5d54` (Merge Upstream `8953cbfff`), Branch-Tip
  inkl. Doku: `a274a8ccf`
- Enthaltener Upstream: `8953cbfff` (25 Commits, inkl. WebSocket-Recovery-
  Telemetrie, DB-Pool-Instrumentierung, S3-Metrik-Isolation, Push-Lease-Fix)
- `buzz-relay`: SHA-256 `a04680fa6ce6352e695a80d9…` (vollständig beim Deploy)
- `buzz-pair-relay`: SHA-256 `bf597efc1e4a176a4da7fb4d…` (neu gebaut — Inputs
  haben sich diesmal geändert, anders als am 09.09.)
- Migrationen: `1` bis `46`; `0045` (Push-Revocation-Tombstones) und `0046`
  (storage_accounting_snapshots) beim Start automatisch angewendet
  (Generalprobe zuvor gegen Kopie des Produktionsdumps bestanden)
- PIDs: Relay `61033`, Pair-Relay `61036`
- Backup: `buzz-before-deploy-0305a5d-20260918-182422.dump` (geprüft)
- Rollback-Anker: Branch `backup/pre-upstream-20260918` (`4a526d35e`) und
  der Dump; zusätzlich der Vorfall-Dump von 16:56 (siehe unten)
- Altlasten bereinigt: 5 Test-Communities (relay.example, ident-test-*,
  test-*.example) und 28 abhängige Zeilen transaktional entfernt; nur noch
  die Produktiv-Community ist vorhanden. Anker dafür: der 18:24er-Dump.
- Nachweise: lokale und öffentliche Readiness `ready`; NIP-11 antwortet;
  Migrationstand 46; 26.220 Produktiv-Events; authentifizierter Kanal-Zugriff
  geprüft; keine Panics im Relay-Log.

### Vorfall 18.09.2026 (Wiederherstellung)

Die buzz-db-Testsuite lief versehentlich mit `DATABASE_URL` auf die
Produktionsdatenbank und setzte sie zurück („404 no community").
Wiederherstellung durch Einspielen des geprüften Dumps
`buzz-before-0305a5d-20260918-165636.dump` in die neu angelegte Datenbank
`buzz`; Datenstand 16:56 Uhr, Verlustfenster bis ca. 17:15 Uhr. Testdatenbanken
und Generalprobe-Datenbank wurden entfernt; Forensik-Dump der kaputten DB
unter `/tmp/buzz-wrecked-*.dump` auf dem Studio. Rollback-Anker bleibt der
Dump `buzz-before-ff8c0d3-20260909-034951.dump` (SHA-256 `4cf40a59…`) plus
Branch `backup/pre-upstream-20260909` (`8f52a3dcc`).

### Bereitgestellt am 18.09. (nach Vorfall)

Merge `0305a5d54` ist deployed (siehe Aktiver Stand). Die buzz-db-Postgres-
Lane lief diesmal sicher gegen eine lokale Wegwerf-Postgres (Docker,
postgres:17-alpine, Port 55440): 255 grün, 4 rot — dieselbe „community write
fenced"-Fehlerklasse, die auf purem origin/main mit 7 Ausfällen identisch
reproduziert (merge-unabhängig, seit 05.09. dokumentiert).
