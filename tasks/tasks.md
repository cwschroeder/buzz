# Tasks - Bearbeitungsstatus

Konvention: Eine Zeile pro offener oder aktueller Aufgabe. Für komplexe Aufgaben
(mehrere Schritte, längere Laufzeit, mehrere beteiligte Agents) gibt es einen
Unterordner tasks/<aufgabe>/; der Eintrag hier verweist dorthin und hält nur
Kurzstatus + Verweis, Details liegen im Unterordner.

| Status | Aufgabe | Verweis | Letzte Änderung |
|--------|---------|--------|------------------|
| fertig | Wolfgang Hoggers Plugin-Agent für die vier Smart-Metering-Repos freischalten | maas-ng, ivu-smp, ivu-smgwa, cls-communication-service | 2026-08-25 claude: ACL, Kanal, kind:10100-Profil und Listener geprüft; Live-Abnahme durch Wolfgang steht aus |
| fertig | Georg Baumgardts Agent-Schlüssel für seine vier Repos freischalten | ivu-workflows, energy-sharing, ivu-smp, erechnung-cloud | 2026-08-28 claude: ACL, Kanal, kind:10100-Profil und Listener je Repo geprüft; Live-Abnahme durch Georg steht aus |
| fertig | Setup-Prüfung Repo-Agents/Buzz/FirstMate: LaunchAgent-Dublette codeapp ausgebucht, vier Repos von gpu-fast auf gpu-quality zurück, Rauchtest bestanden | docs/LEARNINGS.md 2026-09-01 | 2026-09-01 claude: Rauchtest-Antwort Event 1a089fe5…, alle vier Agenten online |
| offen | Kimi-Cloud-Ausläufer aus der gpu-quality-Fallback-Kette für die Pilot-Keys entfernen (Router auf home-1, Entscheidung Christian) | docs/LEARNINGS.md 2026-09-01 | 2026-09-01 claude: Beleg buzz-buzz 31.08. 08:52 UTC |
| offen | Heartbeat-Precheck-Timeout in buzz-acp konfigurierbar machen (10 s fest, Relay-Lesen dauert 3 bis 12 s) | crates/buzz-acp/src/lib.rs | 2026-09-01 claude: Precheck bei codeapp nach Neustart erneut ausgelaufen |
| offen | LaunchAgent prime-agent-pilot zeigt auf Datei aus unmerged Branch feat/inference-routing-topologie, scheitert alle 15 s | codeapp fleet-jobs | 2026-09-01 claude: mergen oder abschalten, Christians Entscheidung |
| fertig | Dateilogs der Pilot-Sessions: pipe-pane von exec- auf cat-Form, Rotation im Supervisor, Pipes an 30 laufende Sessions gehängt | docs/LEARNINGS.md 2026-09-01 | 2026-09-01 claude: Logs wachsen wieder, kein Agent neu gestartet |
| offen | | | |

Statuswerte: offen, in bearbeitung, fertig, blockiert, abgebrochen. Jede
Statusänderung wird eingetragen: wer, wann, was. Append-only-Prinzip gilt auch
hier; korrigieren durch neuen Eintrag, nicht durch Löschen.
