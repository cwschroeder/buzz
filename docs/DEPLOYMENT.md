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

Deployment vom 09.09.2026 (durch Vorfall-Wiederherstellung am 18.09.
bestätigt, siehe unten):

- Customizing-Commit: `ff8c0d36c8a94aa5a68710c82469499ae854793f`
- Enthaltener Upstream: `c045321a7fb3ca8939f28519ce7a555a6f597728`
- `buzz-relay`: SHA-256 `6a9757a35da8f2704e8b3cd2cd94c8ee6451b390405d593ef061d0bfa3f25bd1`
- `buzz-pair-relay`: SHA-256 `66563919d07e72ef62d8d75f8ce235c6c2447310f2c229a8d2031b6743964c74` (unverändert, Inputs seit 31.08. identisch)
- Migrationen: `1` bis `40`, keine neuen Migrationen im Delta
- PIDs nach Vorfall-Wiederherstellung 18.09.: Relay `44633`, Pair-Relay `44636`
- Nachweise: lokale und öffentliche Readiness `ready`; NIP-11 meldet Buzz
  Relay `0.2.1`; authentifizierter Kanal-Lesegriff über die öffentliche URL
  geprüft.

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

### Bereit, aber NICHT deployt (Stand 18.09.)

Merge `0305a5d54` (Upstream bis `8953cbfff`, Migrationen `0045`/`0046`,
Generalprobe bestanden, Clippy sauber, Relay-Libtests 1060 grün) liegt auf
`fork/customizing/cschroeder` und wartet auf Christians Freigabe.
