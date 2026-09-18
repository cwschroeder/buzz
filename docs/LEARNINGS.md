# Learnings

Diese Datei ist append-only. Korrekturen werden als neue, datierte Einträge
ergänzt.

## 31.08.2026 – Backend-Upstream und täglicher Repo-Agent-Abgleich

- (Codex) Relay-Tests, die `ensure_configured_community` verwenden, benötigen
  eine migrierte PostgreSQL-Testdatenbank. Ohne sie scheitern Media-Tests an der
  lokalen Rolle, nicht am Merge.
- (Codex) Der neue Mesh-Demo-Test aus Upstream `ccb021d71` lief in der gesamten
  Relay-Suite wiederholt in einen 504, bestand aber einzeln. Die Datei war
  unverändert aus `origin/main`; Release-Build und produktiver Workflow blieben
  davon unberührt.
- (Codex) Der tägliche Abgleich braucht zusätzlich zum Repo-Agent-Prompt einen
  persistenten Zeitgeber. `pilot/bin/buzz-daily-upstream-check` nutzt eine
  lokale Tagesdatei, atomaren Lock und Fehler-Backoff. Ein Prompt allein löst
  keine tägliche Arbeit aus.
- (Codex) Der aktive Buzz-Repo-Agent lädt seinen System-Prompt beim Prozessstart.
  Prompt-Änderungen gelten deshalb erst nach einem ausdrücklich freigegebenen
  Neustart der Sitzung `buzz-buzz-repo-agent`; der Heartbeat-Precheck selbst
  verwendet die geänderte Datei bereits ohne Neustart.
- (Codex) Das Deployment von `56d2519` migrierte PostgreSQL kontrolliert von 31
  auf 40. Der öffentliche Relay-Verkehr lief nach dem Neustart ohne Fehler
  weiter; die neue Admin-API blieb mangels `BUZZ_ADMIN_HOST` deaktiviert.


## 2026-09-05 - Backend-Upstream-Abgleich f038cbbb (pi)
- (pi) Upstream-Testlücken im Merge gefunden und dokumentiert: (1) Der
  Observability-Source-Scan (`observability_source.rs`) schlägt auf purem
  origin/main fehl, weil c6ca9d94d in `huddle_started_links` ein bare
  `.fetch_all(pool)` einführte. Im Merge mit dem Nachbarmuster gefixt
  (acquire_writer + WriterOperation::Authorization). (2) Der Test
  `mesh_demo::demo_join_forwarded_arm_round_trips_echo` (504 vs 200) und
  (3) sieben Store-Tests in push/channel_members ("community write fenced:
  generation 0") schlagen auf purem origin/main identisch fehl — merge-
  unabhängig, upstream melden.
- (pi) Die Postgres-Lane der buzz-db (`cargo test -- --ignored`) braucht zwingend
  TEST_DATABASE_URL, BUZZ_TEST_DATABASE_URL und DATABASE_URL auf denselben
  Server; sonst fällt sie auf localhost:5432 zurück (dort läuft auf dem MacBook
  ein fremder Postgres ohne buzz-Rolle → irreführendes "role buzz does not
  exist"). Seriell (--test-threads=1) nötig; parallel deadlocken die
  Migrationstests gegenseitig. CI fährt die Lane isoliert pro Instanz.
- (pi) Migrations-Generalprobe bewährt: Prod-Backup in Scratch-DB restoren,
  neue Migrationen anwenden, dann erst deployen. 0041-0044 liefen damit ohne
  Überraschung; der Relay zieht sie beim Start automatisch (BUZZ_AUTO_MIGRATE).
- (pi) buzz-pair-relay wurde beim Release-Build nicht neu kompiliert (Inputs
  unverändert seit 31.08., Cargo sagt "fresh") — das ist korrekt, sieht im
  Binary-Timestamp aber nach verpasstem Build aus.

## 2026-09-09 - Backend-Upstream-Abgleich c045321a (pi)

- (pi) Die `buzz-relay --lib`-Media-Tests brauchen eine migrierte
  Testdatenbank mit buzz-Rolle. Auf dem MacBook lauschten auf Port 55433 ein
  lokales Docker-Postgres (IPv4) und ein alter SSH-Tunnel (IPv6) gleichzeitig;
  127.0.0.1 traf das Docker-Postgres und lieferte irreführend
  `role "buzz" does not exist`. Frischen Tunnel-Port wählen (55434) und
  TEST_DATABASE_URL, BUZZ_TEST_DATABASE_URL und DATABASE_URL auf denselben
  Server setzen; danach laufen alle 1045 Lib-Tests grün.
- (pi) Die Merges 99e3dae83 (07.09.) und ff8c0d36c (09.09., Upstream bis
  c045321a) lagen lokal vor, waren aber nicht verifiziert, gepusht oder
  deployt. Der Lauf hat Test, Push zu fork und Deploy nachgeholt;
  buzz-pair-relay blieb beim Build wie erwartet fresh (Inputs unverändert,
  gleicher SHA-256 wie 31.08.).
- (pi) Rollback-Anker dieses Deploys: Branch `backup/pre-upstream-20260909`
  auf Mac Studio 2 (`8f52a3dcc`), Datenbank-Dump
  `buzz-before-ff8c0d3-20260909-034951.dump`.

## 2026-09-18 - Vorfall: buzz-db-Testsuite gegen Produktion (pi)

- (pi) SCHWERWIEGEND: Die Postgres-Lane `cargo test -p buzz-db -- --ignored`
  setzt die unter DATABASE_URL benannte Datenbank zurück und legt eigene
  Testdatenbanken (deg_r_*, deg_w_*, floor_pool_*, one_budget_*, sep_r_*,
  sep_w_*) auf DEMSELBEN Server an. Sie darf niemals gegen Produktion laufen.
  Die Learnings vom 05./09.09. („TEST_DATABASE_URL, BUZZ_TEST_DATABASE_URL und
  DATABASE_URL auf denselben Server“) galten für die Relay-Libtests und wurden
  von mir falsch auf die buzz-db-Lane übertragen: gleicher Server ja, aber
  benannte Datenbank muss eine Wegwerf-Kratzdatenbank sein, nie `buzz`.
- (pi) Vorfallverlauf 18.09.: buzz-db-Lauf über SSH-Tunnel 55435 auf die
  Produkt-Postgres von Mac Studio 2 → Relay fiel auf „404 no community is
  configured for this host“ (communities-Tabelle nur noch Testfixtures).
  Wiederherstellung aus dem unmittelbar vor dem Lauf erzeugten Dump
  buzz-before-0305a5d-20260918-165636.dump (pg_restore -l geprüft);
  Verlustfenster 16:56–~17:15 Uhr. Dienste-Neustart, Readiness lokal und
  öffentlich grün, authentifizierter Kanal-Lesegriff geprüft.
- (pi) Der Vorfall validiert die Backup-vor-allem-Regel des Runbooks: Der Dump
  von 16:56 war die Rettung. Ohne ihn wären 9 Tage Daten (bis zum 11.09.)
  verloren gewesen. Vor JEDEM Lauf gegen die Produkt-Postgres (auch lesend
  gemeinte) gehört ein frischer Dump dazu.
- (pi) Der Tailscale-Tunnel zum Studio kann während eines Laufs von direkt
  (~2 ms) auf Relay (~100 ms RTT) kippen — Symptom: Testsuite wird 15×
  langsamer. Tests, die viele DB-Roundtrips machen, besser direkt auf dem
  Studio ausführen oder auf einer lokalen Wegwerf-Postgres.
- (pi) Forensik-Dump der kaputten Produktions-DB: /tmp/buzz-wrecked-*.dump auf
  Mac Studio 2. Altlasten: Test-Communities (relay.example, ident-test-*,
  test-*.example) lagen schon vor dem Vorfall in der Produktions-DB (August/
  September) und sind mit dem Restore zurückgekehrt; Aufräumen nur mit
  Christians Freigabe.
