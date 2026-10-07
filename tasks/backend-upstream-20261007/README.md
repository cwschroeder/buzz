# Backend-Upstream vom 07.10.2026

Christian hat Integration und Backend-Deployment am 07.10.2026 freigegeben.

- Ausgangsstand: customizing/cschroeder 331744b9b, enthaltenes Upstream 8953cbfff.
- Ziel: origin/main bd1ff00e487d473bb60691f023a360d4d89e3079.
- Arbeitsbaum: /Users/cschroeder/Github/buzz-backend-20261007, Branch backend/upstream-20261007.
- Laufzeit: Mac Studio 2, https://macstudio-2.taila89eb3.ts.net.
- Deployment umfasst ausschließlich buzz-relay und buzz-pair-relay.
- Sieben Konfliktdateien aufgelöst. Atomare Workflow-Löschung aus Upstream
  übernommen; Medien-Schlüssel bleiben vor Shell-Kindprozessen abgeschirmt.
- Custom-Reconnect-Schutz erhält NOTICE plus Verbindungsende bei vorübergehenden
  Auth-Infrastrukturfehlern. Auch die neue abschließende Zugangskontrolle
  nutzt diesen Schutz. NIP-FI behält seine eigene kanonische Fehlerantwort.
- Tests nutzen eine eigene PostgreSQL-Instanz auf 127.0.0.1:55447 und Redis
  auf 127.0.0.1:56347. Produktionszugangsdaten werden dafür nicht geladen.
- Migrationsprobe nutzt eine getrennte Datenbank buzz_upgrade_rehearsal mit
  einer Kopie des geprüften Produktionsbackups. Index für Migration 0049
  dort nebenläufig aufgebaut und als gültig, bereit und aktiv geprüft.
- Produktionsbackup: Studio-Ordner Buzz Pilot/backups/backend-20261007,
  buzz-before-update.dump, SHA-256
  870a0a4f8d6f7fb31a0835879abb7bfc7697684fe65880b3f765c0c94c8fac70.
  pg_restore -l erfolgreich (634 Inhaltsverzeichniszeilen). Alte Relay-Binaries
  sind im selben Ordner gesichert.

Compiler-Prüfung und Release-Build für die beiden Relay-Binaries bestanden.
Die Migrationsprobe hat Stand 46 auf 56 angehoben; alle 29.567 Events sind
erhalten. Alle Migrationen melden Erfolg, der vorbereitete Index ist weiterhin
gültig, bereit und aktiv. Backend-Tests, Clippy und Deployment sind noch offen.
