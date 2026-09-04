# LEARNINGS.md - Quergedächtnis des Projekts

Konvention: Nach jeder bedeutsamen Session tragen Agenten wichtige Erkenntnisse
ein - belegte Fakten, Entscheidungen, Stolpersteine, Korrekturen, Regressionen.
Eine Zeile pro Erkenntnis, datiert, mit Agenten-Namen. Append-only: Korrekturen
anhängen, nie Verlauf löschen.

## 2026-08-22 - Einführung der Doku-Guardrails
- (pi) Rollout der Plain-Language- und Projekt-Doku-Regeln auf alle
  Buzz-registrierten Projekte. Diese Datei ist ab sofort das immer aktualisierte
  Projektgedächtnis; die restlichen Doku-Dateien (PRODUCT, DESIGN, ARCHITECTURE,
  DEPLOYMENT) pflegen die jeweils zuständigen Skills.

## 2026-08-25 - Kollegen-Onboarding über das buzz-comms-Plugin
- (claude) Trägt ein fremder Agent-Pubkey auf dem Relay bereits ein kind:0-Profil
  mit der Beschreibung "Coding agent reporting through Buzz", dann ist sein
  `project-buzz provision` durchgelaufen. Das setzt Relay-Mitgliedschaft des
  zugehörigen Human-Keys voraus, also fehlt nur noch der Kanalzugang je Projekt.
  `buzz-admin add-member` erübrigt sich dann; das spart den Umweg über den
  Relay-Host. Belegt beim Zugang für Wolfgang Hoggers Agent
  `7c2b3d91c2053a29c9f7243cab4c843e9ba73f07dc0e230b34e87ee6bd01f218`.
- (claude) `repo-agent-access resolve-user` kann mehrere Treffer für dieselbe
  Person liefern (Wolfgang Hogger hat drei Identitäten). Der von Christian
  genannte Schlüssel entscheidet, nicht der Anzeigename.

## 2026-08-28 - Zugang für Georg Baumgardts Agent
- (claude) Zwei Personen namens Georg arbeiten mit uns, und beide Agent-Keys
  heißen auf dem Relay gleich ("Georg (Claude Code)"). Auseinander hält sie nur
  das `about`-Feld mit dem Rechnernamen: `d1c3dcb9…` auf `nbm-baumgardt-2` ist
  Georg Baumgardt (Produktmanagement), `36d52537…` auf `DESKTOP-JMO3UBP` ist
  Georg Fiechtl-Otter (GAFO). Von Christian am 28.08. klargestellt.
- (claude) Der Repo-Kommando-Router lädt die Allowlist bei jedem Durchlauf neu
  (`repo_command_router.py:532` ruft `registry_provider()` in `tick()`, Intervall
  2 s). Nach einem Grant ist also kein Router-Neustart nötig; der Listener-Restart
  des betroffenen Repos erledigt den Rest.
- (claude) Der `status`-Befehl liefert das kind:10100-Profil unter
  `.profile.profiles[]`, nicht direkt unter `.profile`. Wer mit `jq` auf
  `.profile.respond_to_allowlist` prüft, bekommt stillschweigend "nicht
  enthalten" und hält einen gelungenen Grant für kaputt.

## 2026-08-31 - Zugang für GAFOs Agent, und wie man den Umfang belegt
- (claude) Georg Fiechtl-Otter hat neben dem Agent-Key `36d52537…` auch ein
  eigenes Personenkonto auf dem Relay: `84c0f1c2ddfb3a9e7910d2937c0dce038495898c0bc9e9f6e8f63a747abe5319`,
  Anzeigename "GAFO". `resolve-user "Georg"` findet es nicht, weil dort weder
  Vorname noch Nachname steht. Wer nach Georgs Konten sucht, muss zusätzlich
  nach "GAFO" suchen, sonst hält man Baumgardts `7a4064f2…` fälschlich für
  Fiechtl-Otters Personenschlüssel.
- (claude) Umfang eines Grants "in allen Projekten, wo er Kanäle hat" lässt sich
  belegen, ohne zu raten: `repo-agent-access status <repo>` über alle Dateien in
  `pilot/repos/` laufen lassen und die `members` nach dem Personenschlüssel
  filtern. Gegenprobe über `channels list` plus `channels members` erfasst auch
  Kanäle ohne Repo-Agent. Für GAFO ergab beides dasselbe: genau ein Projekt
  (`erechnung-cloud`), sonst nur `general`, `welcome-everyone`, `bearish` und
  eine Direktnachricht.
- (claude) `channels list` liefert das Feld `channel_id`, nicht `id`. Ein `jq
  '.[].id'` ergibt lauter `null`, und der folgende `channels members`-Aufruf
  scheitert mit "invalid UUID: null". Sieht nach fehlenden Rechten aus, ist aber
  ein Feldname.
- (claude) Christian hat den Umfang danach selbst erweitert: GAFO arbeitet auch
  bei `ivu-workflows` mit. Dort war weder sein Personen- noch sein Agent-Schlüssel
  eingetragen, deshalb sind beide gesetzt worden, also dieselbe Ausstattung, die
  Georg Baumgardt in diesem Repo hat. Merkposten für künftige Freischaltungen:
  Nur den Agent-Schlüssel einzutragen ergibt eine halbe Konfiguration, weil die
  Person den privaten Kanal dann nicht sieht und nicht mitliest, was ihr eigener
  Agent dort tut.
- (claude) Der Repo-Agent von `ivu-workflows` bedient laut Verzeichnisprofil auch
  den Arbeitsgruppenkanal "IVU Smart Metering" (`e811fb81…`). In dem Kanal steht
  aber weder GAFO noch Georg Baumgardt; ein Grant fügt nur den Repo-Kanal hinzu.
  Wer die Arbeitsgruppe mitmeinen will, muss das getrennt beauftragen.

## 2026-09-01 - Setup-Prüfung Repo-Agents, Buzz und FirstMate
- (claude) `gpu-fast` taugt nicht als Modell für Repo-Agenten. Der Alias zeigt
  auf Ornith-1.5-35B auf home-1, sein einziger Ausweichpfad `text-large` liegt
  auf demselben Host. Fällt oMLX dort aus, sind die Agenten tot, während
  `gpu-quality` über `gpu-quality-ds4` auf Studio 1 und 2 weiterantwortet.
  Ornith gab außerdem zweimal rohe `<tool_call>`-XML-Blöcke als Antwort ab, die
  der Auto-Publish-Fallback von buzz-acp ungefiltert in den codeapp-Kanal
  stellte. Dazu weist der oMLX-Prefill-Wächter Prompts ab 57k Tokens ab, sobald
  home-1 unter Speicherdruck steht. Die vier Repos codeapp, buzz, erechnung-cloud
  und ivu-workflows stehen deshalb wieder auf `gpu-quality`, wie die anderen 24.
- (claude) Die Staging-Begründung für `gpu-fast` (GLM-5.3-Flash-EXL3 brauchte
  2 bis 3 Minuten pro Aufruf) ist seit dem 01.09. gegenstandslos: der Router
  zeigt `gpu-quality` seit dem Vormittag auf home-1, im Spend-Log gibt es seit
  07:34 UTC keinen EXL3-Verkehr mehr.
- (claude) Der Kimi-Cloud-Ausläufer ist real. Die Fallback-Kette lautet
  `gpu-quality -> gpu-quality-ds4 -> kimi-overflow` (api.kimi.com), und die
  Pilot-Keys erlauben `kimi-overflow`. Der Key `buzz-buzz` hat am 31.08. um
  08:52 UTC zweimal Kimi erreicht. Das widerspricht dem Repo-Prompt ("nie an
  externe Dienste") und der Zusage "local inference only" in AUDIT.md. Der
  Router liegt auf home-1, die Änderung ist Christians Entscheidung.
- (claude) Der Heartbeat-Precheck von buzz-acp hat ein fest verdrahtetes
  Timeout von 10 s (`crates/buzz-acp/src/lib.rs`, `Duration::from_secs(10)`).
  `repo-agent-open-questions` braucht vom MacBook aus 3 bis 12 s, weil
  macstudio-2 nur über den DERP-Relay "fra" erreichbar ist. Der Precheck
  scheitert daher oft, und offene Fragen bleiben unbeantwortet liegen. Ein
  kleineres `PILOT_OPEN_QUESTIONS_FETCH_LIMIT` hilft nicht (50 statt 200: 2,9 s
  statt 3,1 bis 6,2 s), die Streuung kommt aus dem Netz. Abhilfe braucht eine
  Rust-Änderung plus Rebuild und rollierenden Neustart.
- (claude) `com.cschroeder.buzz-codeapp-agent` war ein Rest aus der Zeit vor dem
  Supervisor: zwei Verwalter für dieselbe tmux-Session, im Log stand
  `duplicate session`. Der LaunchAgent ist ausgebucht, die plist liegt unter
  `Buzz Pilot/deploy-backups/…retired-20260901`. Rollback: plist zurück nach
  `~/Library/LaunchAgents` und `launchctl bootstrap gui/$(id -u) <plist>`.
- (claude) Der Rauchtest nach der Umstellung (Scout-Aufgabe "HEAD und Branch")
  brauchte 9 Modellrunden und 530 s, erste Runde 149 s für 25,6k Token kalten
  Prefill auf `gpu-quality-ds4`. Eine triviale Frage kostet den Agenten also
  fast zehn Minuten; der Prompt verlangt, erst jede AGENTS.md zu lesen.
- (claude) HTTP 200 ist kein Beweis für die Primärroute: das Spend-Log
  (`model`-Spalte) zeigt, dass alle neun Aufrufe von `gpu-quality-ds4` kamen,
  obwohl der Agent `gpu-quality` verlangt hatte.
- (claude) `com.cschroeder.prime-agent-pilot` scheitert seit dem 31.08. 17:12 alle
  15 s, weil `fleet-jobs/prime_agent_pilot.py` nur auf dem Branch
  `feat/inference-routing-topologie` existiert (89 Commits vor, 33 hinter
  master). Mergen oder abschalten ist Christians Entscheidung.
- (claude) FirstMate selbst ist gesund: Presence online, History-API in 2 ms,
  Standup um 06:00 in sechs Minuten fertig. Die 109 abgebrochenen und 40
  gescheiterten Tasks im Ledger und die `firstmate-read`-Timeouts des
  Kommando-Routers sind Folgen der toten Repo-Agenten und der DERP-Latenz,
  keine FirstMate-Fehler.
- (claude) `tmux pipe-pane -o -t S "exec >>'datei' 2>&1"` schreibt nie etwas:
  ohne Folgebefehl leitet `exec` nur die Hilfs-Shell um, die sich sofort
  beendet, und tmux schließt die Pipe. So standen alle 31 Pilot-Sessions auf
  `pane_pipe=0` und die Logs unter `Buzz Pilot/logs` seit Juli auf 0 Byte.
  Richtig ist `cat >>'datei'`. Supervisor und `start` sind umgestellt, der
  Supervisor rotiert die Repo-Logs jetzt bei 5 MB, und `pipe-pane -o` lässt
  sich ohne Neustart an laufende Sessions hängen (`-o` öffnet nur, wenn keine
  Pipe offen ist). Prüfen mit `tmux list-panes -t S -F '#{pane_pipe}'`.
- (claude) Die ersten Logzeilen zeigen Precheck-Timeouts auch bei ivu-smp,
  maas-ng und ivu-workflows. Das 10-s-Limit betrifft die ganze Flotte, nicht
  nur codeapp.
