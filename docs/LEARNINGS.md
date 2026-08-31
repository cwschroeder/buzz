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

