# Aufgaben

Diese Liste ist append-only. Statuskorrekturen werden als neue Zeile ergänzt.

| Status | Aufgabe | Verweis | Letzte Änderung |
|---|---|---|---|
| erledigt | Backend-Upstream-Abgleich: origin/main bis c045321a integriert und auf Mac Studio 2 deployt | `docs/LEARNINGS.md` 2026-09-09, Merge `ff8c0d36c` | 09.09.2026, pi: keine neuen Migrationen, Readiness lokal und öffentlich ready, Backup `buzz-before-ff8c0d3-20260909-034951.dump` |
| erledigt | Backend-Upstream-Abgleich: origin/main f038cbbb integriert und auf Mac Studio 2 deployt | `docs/LEARNINGS.md` 2026-09-05, Merge `ae18cfca5` | 05.09.2026, pi: Migrationen 0041-0044 live, Funnel-Health 200, Backup `buzz-pre-upstream-20260905.sql.gz` |
| erledigt | Buzz-Backend auf aktuellen Upstream bringen und auf Mac Studio 2 verifizieren | `56d251991ccf4c4bed0b19243cd082a1f94cf3ed` | 31.08.2026, Codex |
| erledigt | Täglichen Upstream-Zeitgeber und eng begrenzte Dauerfreigabe für den Buzz-Repo-Agenten implementieren | Pilot `7b58490` | 31.08.2026, Codex |
| offen | Aktualisierten System-Prompt in die laufende Sitzung `buzz-buzz-repo-agent` laden; Sitzung nur nach Christians ausdrücklicher Freigabe neu starten | Pilot `7b58490` | 31.08.2026, Codex |
| erledigt | Aktualisierten System-Prompt nach Christians Freigabe in `buzz-buzz-repo-agent` laden | ACP-PID `9449`, Prompt-Zeitstempel `2026-08-31T17:19:38+0200` | 31.08.2026, Codex |

## 2026-09-18 - Upstream-Abgleich 8953cbfff + Vorfall-Wiederherstellung (pi)

Status: **done** (18.09., inkl. Vorfall-Wiederherstellung)

- [x] Merge origin/main (8953cbfff) in customizing/cschroeder — 0305a5d54,
      Konfliktauflösung erhält Customizing f0954339a (transiente Auth-Faults)
- [x] fmt, Clippy, cargo check grün; Relay-Libtests 1060 grün (1 bekannter
      Upstream-Flake, einzeln grün)
- [x] Migrations-Generalprobe 0045/0046 gegen Kratzdatenbank bestanden
- [x] Merge auf fork/customizing/cschroeder gepusht
- [x] Backup vor dem Lauf: buzz-before-0305a5d-20260918-165636.dump (geprüft)
- [x] buzz-db-Postgres-Lane sicher gegen lokale Wegwerf-Postgres wiederholt
      (255 grün, 4 rot = merge-unabhängige Upstream-Fehlerklasse, Gegenprobe
      auf purem origin/main: 7 identische Ausfälle)
- [x] Deploy buzz-relay + buzz-pair-relay auf Mac Studio 2 (Migrationen 46,
      Readiness grün, PIDs 61033/61036)
- [x] Altlast-Test-Communities transaktional entfernt (1 Community übrig)

### Vorfall 18.09. (pi)

buzz-db-Testsuite lief versehentlich gegen die Produktionsdatenbank → Relay
fiel auf 404. Wiederherstellung aus dem 16:56-Dump, Verlustfenster ~16:56 bis
~17:15 Uhr. Details: docs/LEARNINGS.md, docs/DEPLOYMENT.md.

- [x] Buzz-Ergebnis mit Nachweisen publiziert (Thread 18.09.)


## 2026-10-07 - Backend-Upstream (Codex)

| Status | Aufgabe | Details |
|---|---|---|
| erledigt | Upstream bd1ff00e4 integrieren und Relay sowie Pair-Relay auf Mac Studio 2 aktualisieren | [Prüfung und Nachweise](backend-upstream-20261007/README.md) |
