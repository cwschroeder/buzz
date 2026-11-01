# Deployment

Dieses Runbook beschreibt den privaten Buzz-Backend-Betrieb auf Mac Studio 2.

## Build und Runtime

- Checkout: `/Users/cschroeder/Github/buzz`, Branch `customizing/cschroeder`
- Build aus isoliertem Git-Arbeitsbaum mit separatem `CARGO_TARGET_DIR`:
  `BUZZ_SOURCE_SHA=$(git rev-parse HEAD) BUZZ_BUILD_ID=backend-<JJJJMMTT>-studio2 BUZZ_BUILD_URL=https://github.com/cwschroeder/buzz/commit/$(git rev-parse HEAD) cargo build --release --locked -p buzz-relay -p buzz-pair-relay`
- Eingebauten Quellcommit und Abhängigkeiten am lokalen Health-Listener
  `http://127.0.0.1:8088/_status` prüfen; Readiness allein belegt diese nicht.
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

Dump wiederherstellen: Ein `pg_restore` in einem Durchgang verliert alle
Events, weil der Trigger der Community-Schreibsperre beim Restore seine
Hilfsfunktion nicht findet. Deshalb in drei Durchgängen einspielen:
`--section=pre-data`, dann `--section=data --disable-triggers`, dann
`--section=post-data`. `--disable-triggers` braucht einen Superuser; im
Container ist `buzz` der `POSTGRES_USER`. Belegt bei der Migrationsprobe am
01.11.2026.

Migrationsprobe ohne Nebenwirkungen: `buzz-admin migrate` aus demselben Stand
gegen eine Kopie in einer Wegwerf-Instanz. Für einen Probestart des Relays
gegen die Kopie zusätzlich Wegwerfwerte für `BUZZ_RELAY_PRIVATE_KEY` und
`RELAY_OWNER_PUBKEY`, `BUZZ_GIT_CONFORMANCE_PROBE=false` und eigene Ports
setzen. Vorher prüfen, dass Operator-Listener, Workflows und Push-Leases in der
Kopie leer sind. Auf Studio 2 sind dafür `libpq` und `cargo-nextest` per
Homebrew installiert. Die Postgres-Spur läuft mit `scripts/postgres-test-run.sh`
und `BUZZ_POSTGRES_ADMIN_URL` auf die Wegwerf-Instanz.

Offener Betriebspunkt (01.11.2026, claude): Alle Events liegen in der
Auffang-Partition `events_p_future`, Monatspartitionen gibt es nur bis Juni
2026. Seit upstream #8464 will das Relay die Auffang-Partition weiterschieben
und meldet bei jedem Start `Failed to ensure partitions` mit „advancing it
requires an operator“. Der Start läuft weiter; der Startschritt
`PartitionEnsure` endet als `degraded`, `partition_catalog.serving_safe`
bleibt true. Die Umverteilung in Monatspartitionen ist ein eigener
Operator-Schritt mit Backup.

## Aktiver Stand

Deployment vom 01.11.2026 (claude, Freigabe durch Christian am selben Tag):

- Laufzeit-Code: `f2f76c4faf5ff1d3a12978b4c8187d798a8e2809`, Merge von PR #2
  mit den Sicherheitsupdates vom 31.10. Enthaltener Upstream: `9e8c9fc04`
  (Abgleich vom 25.10.).
- Anlass: Buzz 1.0 (`block/buzz-app`) blendet Funktionen aus, die das Relay im
  NIP-11 nicht anbietet. Neu angeboten werden `nip-cl` (Kanal-Identität,
  Labels — darunter Solo-Chats über `t=buzz.solo` — und System-Kanäle) und
  `buzz-search-sort`, dazu Personensuche über
  `/profiles/search` und Agenten-Presence (kind 20003). Live-Sync für Artefakte
  (`artifacts.sync`, upstream #8522 vom 30.10.) ist noch nicht enthalten.
- Nur `buzz-relay` und `buzz-pair-relay` installiert (per Umbenennen) und neu
  gestartet. Web-Assets, Desktop und Agenten unverändert.
- Relay SHA-256: `06be8367310ccc7df7e5e2591f835c43f55e8edb8ccb6d407416e6d188faf370`.
- Pair-Relay SHA-256: `db7561b768c18786d552505af95ef557ada6ec4debf39405324284e7ab55ed69`.
- PIDs bei Abschluss: Relay `73829`, Pair-Relay `73847`.
- Migrationen 57 bis 68 beim Start erfolgreich. 39.296 Events vor und nach dem
  Neustart.
- Live-Status: Build-ID `backend-20261101-studio2`, Quellcommit wie oben,
  PostgreSQL und Redis erreichbar, Partitionenkatalog sicher.
- Externe Nachweise: öffentliche Readiness `ready`. NIP-11 mit unverändertem
  `self`, unveränderter `community_id` `4de1e03a-3a00-428f-8d3a-96a664cd8324`
  und gleichen `supported_nips`; `supported_extensions` neu mit `nip-cl` und
  `buzz-search-sort`.
  Authentifizierter Kanal-Lesezugriff, Pair-WebSocket beantwortet eine
  Subscription mit EOSE, wieder 4 aktive WebSocket-Verbindungen wie vor dem
  Neustart.
- Log nach dem Neustart: einmal `ERROR Failed to ensure partitions` (siehe
  offener Betriebspunkt oben), sonst kein ERROR oder Panic.
- Keine GUI-Prüfung, der Bildschirm des MacBooks war gesperrt. Mobile ungeprüft.
- Tests und Probe: [Aufgabenbericht](../tasks/backend-upstream-20261101/README.md).

Backups liegen geschützt auf Studio 2 unter
`~/Library/Application Support/Buzz Pilot/backups/backend-20261101`:

- Dump direkt vor dem Neustart: `buzz-before-update-20261101-174834.dump`,
  SHA-256 `b60ce38f97ec79cdaae3fd252d101746308112a563f41d93c57780b92efeeb58`,
  `pg_restore -l` mit 672 Zeilen.
- Alte Binaries `buzz-relay-9e8bd7d` und `buzz-pair-relay-9e8bd7d` (Hashes wie
  im Stand vom 07.10.) sowie das NIP-11 vor dem Update, `nip11-before.json`.

Rückweg nur über den Dump: Die Migrationen 0058 und 0060 entfernen Spalten,
0063 und 0065 Trigger. Das alte Binary läuft deshalb nicht auf Schema 68, ein
Tausch der Binaries allein reicht nicht. Ablauf: beide Relay-Dienste
(`com.buzz.relay`, `com.buzz.pair-relay`) per `launchctl bootout` stoppen und
deaktivieren, Datenbank `buzz` neu anlegen, Dump in drei Durchgängen einspielen
(siehe oben), alte Binaries zurück, Relay starten. Schreibvorgänge seit dem Dump
gehen verloren.

## Historischer Stand vom 07.10.2026

Deployment vom 07.10.2026:

- Laufzeit-Code: `9e8bd7d5b60a9ce10393df280859a676f1dbbb8e`.
  Spätere Dokumentationscommits erfordern keinen Backend-Neustart.
- Enthaltener Upstream: `bd1ff00e487d473bb60691f023a360d4d89e3079`.
  Seit dem bisherigen Upstream-Anker kamen 163 Commits hinzu, davon 45 mit
  Backend-Bezug. Custom-Reconnect-Schutz und Konfiguration bleiben erhalten.
- Nur `buzz-relay` und `buzz-pair-relay` installiert und neu gestartet.
- Relay SHA-256: `67c1338994b6cb20f727c91260c26dffba95d1f09cc79d68efa2d1a5b15d89c9`.
- Pair-Relay SHA-256: `235e847f9e1dcd08ff75b9d59a1ba2539c88a1840921ca6a5b0030e995d63435`.
- PIDs bei Abschluss: Relay `16334`, Pair-Relay `14769`.
- Migrationen 1 bis 56 erfolgreich. Der Index für Migration 0049 wurde vor
  Aktivierung nebenläufig aufgebaut; Katalogdefinition und Gültigkeit geprüft.
- Live-Status: Build-ID `backend-20261007-studio2`, Quellcommit wie oben,
  PostgreSQL und Redis erreichbar, Partitionenkatalog sicher.
- Externe Nachweise: öffentliche Readiness `ready`, NIP-11 Version 0.2.1,
  authentifizierter Kanal-Lesezugriff und echte Pair-WebSocket-Subscription mit
  EOSE. Der letzte Datencheck fand 29.619 Events. Der geprüfte Logabschnitt
  nach dem letzten Neustart enthält keinen ERROR oder Panic.
- Die Browser-Fenstererkennung schlug fehl. Es liegt externe HTTP- und
  Nostr/WebSocket-Prüfung vor, keine abschließende GUI-Prüfung.
- Testumfang und gezielte Nachprüfungen:
  [Aufgabenbericht](../tasks/backend-upstream-20261007/README.md).
  Tests und Migrationsprobe liefen ausschließlich auf isolierten Instanzen;
  die lokale Produktionskopie wurde danach entfernt.

Backups liegen geschützt auf Studio 2 unter
`~/Library/Application Support/Buzz Pilot/backups/backend-20261007`:

- Vor Aktivierung: `buzz-before-activation.dump`, SHA-256
  `9976140f4180aee1250e663ef059438548d375af55d8d31c5f20616e3cfc3b48`.
- Vor dem Neustart mit eingebautem Quellcommit:
  `buzz-before-stamped-restart.dump`, SHA-256
  `3bcacd1ed722f3d2021904389c2d9016fc01c32558174ef8de6365c032b43e2e`.
- Beide Inhaltsverzeichnisse mit `pg_restore -l` geprüft. Alte Relay-Binaries
  und das bereits funktionierende neue Relay ohne Build-Stempel sind gesichert.
- Rollback-Quellanker: `backup/pre-upstream-20261007` auf `331744b9b`.
  Ein Datenbank-Restore muss neue Schreibvorgänge seit dem Dump berücksichtigen.
  Bei einem reinen Problem des Build-Stempels steht das neue, mit Schema 56
  kompatible Binary `buzz-relay-9e8bd7d-unstamped` bereit.

## Historischer Stand vom 18.09.2026

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

Merge `0305a5d54` ist deployed (siehe Historischer Stand vom 18.09.2026). Die buzz-db-Postgres-
Lane lief diesmal sicher gegen eine lokale Wegwerf-Postgres (Docker,
postgres:17-alpine, Port 55440): 255 grün, 4 rot — dieselbe „community write
fenced"-Fehlerklasse, die auf purem origin/main mit 7 Ausfällen identisch
reproduziert (merge-unabhängig, seit 05.09. dokumentiert).
