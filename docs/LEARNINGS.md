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
