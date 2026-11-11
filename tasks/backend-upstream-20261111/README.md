# Relay-Update vom 10. und 11.11.2026

Christian hat am 10.11. „prüf mal, wir sollten buzz backend von upstream holen
und neu bauen“ beauftragt und das Ausrollen nach dem Merge freigegeben, am
11.11. nach neuen Upstream-Commits „dann updaten“. Agent: claude. Buzz-Thread
im Kanal `buzz`, Start
`13a7215ae77837bf7a58fbc5940e6c738c0f4e4bfe3822e8830e23a2e548a8a3`.

- Ausgangsstand live: `f2f76c4fa` (01.11.), Upstream `9e8c9fc04`, Schema 68.
- Endstand live: `ae7f9c0a2` (PR #9), Upstream `95dd9d67d` vom 11.11., Schema 86.
- Ausgerollt in zwei Schritten: PR #8 mit Migrationen, danach PR #9 als reiner
  Binärtausch. Werte und Backups: `docs/DEPLOYMENT.md`, Aktiver Stand.

## PR #8: Upstream bis 09.11.

- Merge von Upstream `44b3c4823` (387 Commits seit `9e8c9fc04`).
- Anpassungen im Fork:
  - `dfa64e5d6`: Fork-Code an geänderte Upstream-Schnittstellen angepasst.
  - `cb0bad7f9`: Ein neuer Upstream-Test zur Git-Speicher-Probe baute auf eine
    Wiederholung durch rust-s3 0.37; der Fork nutzt seit 31.10. rust-s3 0.38.
    Nur das Test-Backend angepasst.
  - `61730540e`: Der Fork-Schutz gegen Reconnect-Schleifen behandelte jede
    `AuthorizationUnavailable`-Ablehnung als vorübergehend. Ein
    `OwnerLink::Conflict` (Agent hat schon einen anderen Owner) ist jetzt eine
    endgültige AUTH-Ablehnung; nur ein nicht schreibbarer Link bleibt
    vorübergehend.
- Tests auf Studio 2 mit Rust 1.98.1: 6.638 nextest- und 30 Cargo-Tests grün,
  clippy ohne Befund, Postgres-Spur 1.490 von 1.490 gegen Wegwerf-Instanzen.
- Migrationsprobe: Migrationen 69 bis 86 gegen eine Kopie der Produktion in
  unter einer Sekunde, Events, Kanäle und Mitglieder gleich. Probestart des
  Relays gegen die Kopie `ready`, Anmeldung, Lesen und Schreiben mit der
  Repo-Identität funktionierten. Kopie danach entfernt.
- Review und Merge durch den Repo-Agenten, Merge `04498c170`.

## PR #9: 14 Upstream-Commits vom 10. und 11.11.

- Merge `46c4b8724` ohne Konflikte; `Cargo.toml` und `Cargo.lock`
  unverändert, der Fork-Schutz in `auth.rs` (`close_for_transient_fault`)
  vollständig erhalten.
- Tests für die betroffenen Crates `buzz-relay`, `buzz-pubsub` und
  `buzz-core`: nextest 2.142 von 2.142, clippy ohne Befund, Postgres-Spur
  641 von 641.
- Repo-Agent: Freigabe ohne Blocker, drei nicht blockierende Hinweise
  (Pending-Token-Drop-Guard, vorbestehender Revoke-Race, Warnungsflut bei
  voller Pubsub-Queue). Merge `ae7f9c0a2` hat denselben Baum wie der geprüfte
  Head.
- GitHub-CI auf dem Fork: Rust, Postgres, Relay-E2E, Mobile und Desktop
  macOS grün. Desktop-Tauri und Desktop-Smoke/E2E scheiterten in der
  Einrichtung, bevor Code lief: `apt-get update` lief dreimal gegen den
  Azure-Spiegel ins Timeout, und Playwright unterstützt Chromium auf dem
  Runner-Image Ubuntu 26.04 nicht. Der Playwright-Schritt scheiterte schon bei
  PR #8 auf. PR #9 ändert nichts am Desktop.

## Was der neue Stand bringt

Bereich `9e8c9fc04..95dd9d67d`, ohne Markierung im Upstream-Code gelesen.
„(Commit-Text)“ heißt: nur aus der Commit-Nachricht, nicht im Code geprüft.
Im Betrieb beobachtet sind nur die NIP-11-Felder, das Zugriffslog und die
Media-Prüfung; der Rest ist nicht erprobt.

Ohne Zutun aktiv:

- Datenbank: Der SQLx-Pin begrenzt die Rückgabe einer Verbindung an den Pool
  auf 5 s (`Cargo.toml`, Kommentar zu sqlx PR 4407), Verbindungen leben
  höchstens 300 s (`crates/buzz-db/src/runtime/mod.rs`). Eine Suche endet
  bei Datenbankfehlern mit CLOSED `error: database error` statt mit EOSE;
  für History-Reads gilt das laut #8692 ebenso (Commit-Text). Der
  Fork-Schutz bleibt nötig, weil Upstream außerhalb von NIP-FI weiter
  `OK false` schickt (`handlers/auth.rs`).
- Zugriffslog `buzz_relay::access` mit `close_reason` je Verbindung (siehe
  offener Betriebspunkt zum Logvolumen in `docs/DEPLOYMENT.md`).
- Media mit `Cache-Control: private, no-store`; WebP-Vorschaubilder, die bei
  Bedarf neu erzeugt werden (Commit-Text).
- Einladungen gesperrter Aussteller werden beim Einlösen widerrufen.
- Aus Commit-Texten: Mitgliedschaftshinweise beim Löschen und Moderieren,
  bis zu 100 Personen je kind:9000 (die CLI nimmt weiter einen Pubkey),
  eindeutige Namen für gelistete Kanäle (Migration 0083), Prüfung der
  Workflow-Owner.
- Für Buzz 1.0: Artefakt-Sync (`artifacts.sync`, `artifacts.incremental`,
  im NIP-11 sichtbar), eigene Emoji (kind 30180).
- Entfallen: die Metriken `buzz_total_*` und `buzz_community_*` (Commit-Text);
  die Variablen `BUZZ_REDIS_POOL_SIZE` und `BUZZ_USAGE_METRICS_*` werden
  ignoriert.

Abschaltbar, derzeit aus:

- `BUZZ_MEDIA_READ_MODE=off|shadow|enforce` für private Medien
  (`docs/operator-private-media.md`).
- Standardkanäle mit `--auto-join`; `buzz-admin add-member` tritt ihnen nicht
  bei.
- Ungelistete Kanäle (`--unlisted`), Nebenläufigkeitsgrenzen über
  `BUZZ_FEATURE_FLAGS_PROVIDER`, `BUZZ_CLIENT_IP_HEADER`, NIP-FI
  (`BUZZ_NIP_FI_MODE`).

Mit den nächsten Mobile-Releases (Desktop 1.0 kommt aus `block/buzz-app`):

- Arbeitende Agenten an der Thread-Wurzel sichtbar; braucht Typing-Events
  (kind 20002), ob unsere CLI-Agenten sie senden, ist ungeprüft.
- Leise Agenten-Nachrichten mit `["audience","agents"]` zählen nicht als
  ungelesen. Unsere CLI kann den Tag nicht setzen; das wäre ein kleiner
  Patch am Fork.
- Foto- und Video-Stapel, Markierung „bearbeitet“, gleichnamige Agenten
  unterscheidbar, Lesestand über Geräte hinweg.
- Volltext in iOS-Benachrichtigungen braucht Push; `BUZZ_PUSH_ENABLED` ist
  standardmäßig aus.

Neue CLI (`buzz`), am Abend an die Agenten verteilt (siehe Nachtrag unten):

- `messages send --from-thread`, Bearbeiten behält Anhänge
  (`--clear-attachments` zum Entfernen), Upload beliebiger Dateitypen,
  `users set-status --expires`, `channels unread`, `huddles list`.
- Reihenfolge Relay vor CLI ist jetzt erfüllt. Die alte CLI entfernt beim
  Bearbeiten weiter die Anhänge.

## Nachtrag 11.11. abends: CLI und Logrotation

Christian hat beide Punkte aus den Empfehlungen beauftragt („ja, mach 2 und 3“).

CLI:

- Gebaut auf Studio 2 aus `ae7f9c0a2`, demselben Stand wie das Relay
  (`cargo build --release --locked -p buzz-cli`), SHA-256
  `28d8b29bf0381dc4…`.
- Ersetzt auf MacBook und home-1 `~/Github/buzz-custom/target/release/buzz`.
  Das war der Stand vom 18.08. (SHA-256 `b60333214687…`), nicht wie oben
  zuerst angenommen der vom 25.10.; er liegt als `buzz.20260818-b6033321`
  daneben. Auf dem MacBook zeigt `~/.local/bin/buzz` jetzt auf denselben Pfad,
  vorher auf die CLI im Desktop-Bundle vom 01.11. Der Checkout
  `buzz-custom` steht per Fast-Forward auf `ae7f9c0a2`.
- Verträglichkeit geprüft:
  - Für alle Befehle, die Pilot und Helper aufrufen, fällt kein Flag weg.
  - `messages get` und `messages thread` liefern dieselben Events,
    zusätzlich das Feld `sig`; `channels get`, `channels members` und
    `channels list` liefern inhaltlich dasselbe.
  - Pilot und Helper werten nur „Exit-Code ungleich 0“ aus.
  - Der Preflight-Check auf `--mention` besteht.
- Im Betrieb: Fortschrittsmeldung über den Pilot auf dem MacBook gesendet und
  mit Umlauten und Tags zurückgelesen; auf home-1 lesen beide Pilot-Wege und
  der Helper.
- Der Helper-`doctor` auf home-1 meldet für maas-ng und netzcockpit
  „channel not visible to this agent“. Mit der alten CLI kommt dasselbe, der
  Befund ist also älter als das Update.

Logrotation: siehe `docs/DEPLOYMENT.md`, Abschnitt Logrotation. Skript
[`buzz-relay-logrotate`](buzz-relay-logrotate) und
[`com.buzz.relay-logrotate.plist`](com.buzz.relay-logrotate.plist) liegen
hier. Vorab lokal geprüft: Ein Schreiber mit `O_APPEND` verlor über vier
Rotationen in zwei Sekunden keine seiner 600 Zeilen, das Kürzen hinterlässt
keine Nullbytes, alte Generationen werden gelöscht.

Nebenbefund: Der Probestart des Relays aus der Migrationsprobe vom 10.11.
lief noch (PID 26533, seit 10.11. 09:22), gegen die längst entfernte
Probe-Datenbank und mit Health und Metriken auf `*:18088` und `*:19202`.
Beendet, Produktion unberührt.

## Offen

- Events aus `events_p_future` in Monatspartitionen umverteilen
  (Operator-Schritt mit Backup, seit 01.11. offen).
- Entscheiden, ob Standardkanäle (`--auto-join`) und
  `BUZZ_MEDIA_READ_MODE=shadow` eingeschaltet werden.
