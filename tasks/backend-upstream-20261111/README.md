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

Neue CLI (`buzz`), noch nicht an die Agenten verteilt (die nutzen den Stand
`677a282a4` vom 25.10.):

- `messages send --from-thread`, Bearbeiten behält Anhänge
  (`--clear-attachments` zum Entfernen), Upload beliebiger Dateitypen,
  `users set-status --expires`, `channels unread`, `huddles list`.
- Reihenfolge Relay vor CLI ist jetzt erfüllt. Die alte CLI entfernt beim
  Bearbeiten weiter die Anhänge.

## Offen

- CLI-Stand für die Agenten aktualisieren.
- Logvolumen des Zugriffslogs begrenzen (`RUST_LOG` oder Rotation).
- Events aus `events_p_future` in Monatspartitionen umverteilen
  (Operator-Schritt mit Backup, seit 01.11. offen).
- Entscheiden, ob Standardkanäle (`--auto-join`) und
  `BUZZ_MEDIA_READ_MODE=shadow` eingeschaltet werden.
