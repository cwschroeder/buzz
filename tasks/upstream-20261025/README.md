# Upstream-Abgleich vom 25.10.2026

Nicht live. Quellstand mit `origin/main` bei `9e8c9fc04` abgeglichen.
Ausgangsstand des Anpassungsbranches: `ceb682de8`, 174 Upstream-Commits fehlten.
Merge-Commit: `dde99086d`. Die bisherigen Anpassungen bleiben erhalten.

## Integration

- Deterministische ACP-Idle-Tests aus Upstream übernommen.
- Atomare Workflow-Löschung aus Upstream übernommen; die zusätzliche Prüfung
  einer bereits fehlenden Workflow-Zeile nutzt jetzt diesen Produktionspfad.
- Huddle-Transporttests an die bestehende Wiederverbindungstaktung angepasst.
  Die Testuhr leitet die Wartezeit aus der Produktionskonstante ab. Priorität,
  Rate-Limit, Abmeldung und vollständige Wiederherstellung bleiben geprüft.
- Der separate ältere Arbeitsbranch erhält seinen eigenen Merge. Seine lokalen
  Dokumentationsergänzungen werden dabei erhalten.

## Prüfung

- Rust-Formatprüfung und Clippy für den gesamten Workspace mit allen Targets
  und `-D warnings` bestanden.
- ACP: 1.069 Tests bestanden, drei übersprungen. Ein unveränderter
  Upstream-Test zur begrenzten Schreibdauer lief unter paralleler Last in sein
  Zeitlimit und bestand anschließend einzeln (12,38 Sekunden).
- PostgreSQL: zehn Workflow-Löschtests bestanden, einschließlich Parallelität,
  Rollback und unserer zusätzlichen Regression. Eigene lokale Testinstanz;
  Datenbankaufbau und Isolation über die Repository-Skripte.
- Desktop: 6.833 Tests im ersten Lauf bestanden. Zwei neue Upstream-Tests
  erwarteten die dortige 50-ms-Taktung statt unserer 1.000 ms. Nach Anpassung
  bestanden alle fünf Tests dieser Transportdatei.
- Alle 16 Repository-CLI-Tests bestanden, einschließlich der Aktualisierung
  älterer Repository-Metadaten.
- Weitere 161 DOM-Tests bestanden. Desktop- und Web-Codeprüfung,
  TypeScript-Prüfung und Dateigrößenprüfung bestanden.
- `just ci` wurde nach erfolgreicher Workspace-Clippy-Prüfung und vor Abschluss
  der nativen Desktop-Prüfung beendet. Der vollständige Desktop-/Mobile-Build
  und die vollständige Integrationssuite sind damit nicht nachgewiesen.

Buzz und internes Git waren wegen des gemeldeten Büro-Netzausfalls nicht
verfügbar. Kein Rollout, kein Neustart und keine Änderung der Pilot-Konfiguration.
