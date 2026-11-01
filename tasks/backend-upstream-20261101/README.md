# Relay-Update vom 01.11.2026

Christian hat das Ausrollen am 01.11.2026 freigegeben. Anlass: Buzz 1.0
(`block/buzz-app`) prüft im NIP-11, was das Relay kann, und blendet Fehlendes
aus. Der Fork-Stand `f2f76c4fa` enthält Upstream bis `9e8c9fc04` (25.10.) und
damit `nip-cl`, `buzz-search-sort`, `/profiles/search` und Agenten-Presence.

- Ausgangsstand live: `9e8bd7d5b` (07.10.), Schema 56.
- Ziel: `customizing/cschroeder` bei `f2f76c4faf5ff1d3a12978b4c8187d798a8e2809`.
- Arbeitsbaum auf Studio 2: `~/Github/buzz-backend-release-20261101`, detached.
- Deployment umfasst nur `buzz-relay` und `buzz-pair-relay`.
- Agent: claude. Buzz-Thread im Kanal `buzz`, Start
  `39fbb5fdc42cc6179bb731dbb8dbaea85a43f960b1551a3e444f2965660797b9`.

## Prüfung vor dem Deployment

- Release-Build mit `--locked` und Build-Stempel `backend-20261101-studio2`
  bestanden.
- `just test-unit`: alle Läufe grün, rund 5.760 Tests, kein Fehler.
- Postgres-Spur (`scripts/postgres-test-run.sh` für buzz-admin, buzz-audit,
  buzz-db, buzz-deletion, buzz-push-gateway, buzz-relay, buzz-search,
  buzz-workflow) gegen eine Wegwerf-Instanz auf Port 55447: 1.099 von 1.104
  bestanden.
  - `handlers::group_state_postgres_tests::system_channel_without_h_tag_defaults_private`
    scheiterte mit einem Pool-Timeout, während die Unit-Spur parallel kompilierte.
    Einzeln wiederholt: bestanden.
  - Die vier `store::event_follow_up_postgres_tests::*_event_follow_up_contract_*`
    scheitern auch einzeln (Zeile 1038, erwartet 0 Treffer, gefunden 1). Ursache
    ist die Testvorbereitung: Der Push-Lease-Zeitstempel kam aus
    `clock_timestamp()` und konnte älter sein als der Eingang des Events.
    Upstream hat genau diese Vorbereitung in `d6196a16c` (#8237, 28.10.)
    korrigiert, nach unserem Merge-Stand. Unser buzz-db-Diff zu Upstream
    betrifft nur `workflow.rs`. Push nutzen wir nicht, die Push-Tabellen der
    Produktion sind leer.
- Umgebungsvariablen: Alle Namen aus `pilot/bin/relay-entry` und `relay.env`
  liest der neue Stand weiterhin.

## Migrationsprobe

- Lesedump der Produktion in die Wegwerf-Instanz eingespielt. Der Restore in
  einem Durchgang verlor alle Events (Trigger der Community-Schreibsperre ohne
  auflösbare Hilfsfunktion). In drei Durchgängen mit `--disable-triggers` im
  Datenteil kamen alle 39.284 Events an.
- `buzz-admin migrate` aus demselben Stand: Migrationen 57 bis 68 erfolgreich,
  jede in wenigen Millisekunden. Events vollständig, beide Push-Trigger entfernt.
- Probestart des neuen Relays gegen die migrierte Kopie auf eigenen Ports,
  nachdem Operator-Listener, Workflows und Push-Leases als leer geprüft waren:
  `ready`, Partitionenkatalog sicher, NIP-11 mit `nip-cl` und
  `buzz-search-sort`. Einziger Fehler: `Failed to ensure partitions`, weil alle
  Events in `events_p_future` liegen. Den Zustand hat die Produktion schon
  vorher, siehe offener Betriebspunkt in `docs/DEPLOYMENT.md`.
- Wegwerf-Instanzen samt Produktionskopie danach entfernt.

## Deployment

- Deploy-Sperre vor Beginn und direkt vor dem Neustart frei.
- Dump direkt vor dem Neustart, geprüft und mit Hash, siehe `docs/DEPLOYMENT.md`.
- Binaries per Umbenennen installiert, `com.buzz.relay` neu gestartet (nach 8 s
  `ready`), danach `com.buzz.pair-relay`.
- Checkout `~/Github/buzz` auf Studio 2 per Fast-Forward auf `f2f76c4fa`.

## Live geprüft

- `_status`: Build-ID und Quellcommit wie oben, PostgreSQL und Redis
  erreichbar, `serving_safe` true.
- Migrationen 1 bis 68 erfolgreich, 39.296 Events vor und nach dem Neustart.
- Öffentliches NIP-11: `self`, `community_id` und `supported_nips` unverändert,
  `supported_extensions` neu mit `nip-cl` und `buzz-search-sort`.
- Öffentliche Readiness `ready`. Authentifizierter Kanal-Lesezugriff über
  `project-buzz context`. Pair-WebSocket beantwortet eine Subscription mit EOSE.
- 4 aktive WebSocket-Verbindungen wie vor dem Neustart.
- Log nach dem Neustart: nur der bekannte Partitionsfehler.

Nicht geprüft: Buzz 1.0 und 0.X in der Oberfläche, weil der Bildschirm des
MacBooks gesperrt war, und die Mobile-App.
