# CursorCompanion ⌘

> Native macOS Menubar Companion for Cursor AI — Instant dual-pool monitoring across multiple accounts.

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-black?logo=apple)](https://apple.com)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange?logo=swift)](https://swift.org)
[![Tests](https://img.shields.io/badge/Tests-20%20passing-brightgreen)](#testing)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Highlights

- **Beide Pools permanent im Blick**: Live-Anzeige von *Cursor Models* (Composer, Grok) und *Other Models* (Claude 3.7, GPT-4o) direkt in der macOS-Menüleiste (`63% · 41%`).
- **Multi-Account Caching**: Behalte den Überblick über Work-, Personal- und Team-Accounts, selbst wenn du in der Cursor-App gerade mit einem anderen Konto eingeloggt bist.
- **Kaltstart in < 1 Sekunde**: Öffnet sich sofort ohne Ladeverzögerung dank intelligenter lokaler Zwischenspeicherung.
- **Emil Kowalski Signature UI**: 270px ultra-kompaktes Popover, reine Schweizer Typografie mit tabellarischen Zahlen (`tnum`), 2px Hairline-Fortschrittslinien und taktiles Tastenfeedback (`:active scale(0.97)`).
- **100% Lokal & Sicher**: Rein lesender Zugriff auf Cursors lokale Datenbank `state.vscdb`, isolierte Token-Speicherung im eigenen macOS-Schlüsselbund (`dev.cursorcompanion.account.<id>`), null Telemetrie.

---

## Popover-Vorschau

```
┌───────────────────────────────────────┐
│ Work  /  Personal               18d   │
│                                       │
│ Cursor Models                     63% │
│ ━━━━━━━━━━━━━━━━━━━━━━░░░░░░░░░░░░    │
│                                       │
│ Other Models                      41% │
│ ━━━━━━━━━━━━░░░░░░░░░░░░░░░░░░░░░    │
│                                       │
│ 2m ago                 Sync     ⚙    │
└───────────────────────────────────────┘
```

---

## Architektur

Das Projekt basiert auf Swift 6 mit vollständiger Concurrency-Prüfung (`-strict-concurrency=complete`):

- **`CursorCompanionCore`**:
  - `Auth/`: Read-only C-`libsqlite3` Zugriff auf `state.vscdb`, macOS Keychain Fallback, JWT-Claim Extraction (`sub`, `exp`), Session-Cookie-Konstruktion.
  - `Client/`: Connect-RPC & REST Endpunkte mit automatischer 401/403-Refresh-Schleife.
  - `Mapping/`: Robuster `CursorUsageMapper` für beide Modell-Töpfe, Countdown und Request-Fallbacks.
  - `Store/`: Actor-basierter `AccountStore` mit isoliertem Keychain-Namespace.
  - `Scheduler/`: `UsageScheduler` für Hintergrund-Polling und automatisches Aufwachen bei macOS Wake.
  - `State/`: `@MainActor` `AppState` für reaktive SwiftUI-Bindung.
- **`CursorCompanionApp`**:
  - `App/`: `StatusBarController` (`NSStatusItem` + `NSPopover`) und `AppDelegate`.
  - `Views/`: `MenuBarLabelView`, `PopoverView`, `MetricBlockView`, `SettingsView`.

---

## Bauen & Ausführen

### Voraussetzungen
- macOS 13.0+ (Ventura, Sonoma, Sequoia)
- Xcode 15.0+ oder Swift 6.0 Toolchain

### Tests ausführen
```bash
swift test
```

### Release-App bauen & starten
```bash
./build_app.sh
open .build/CursorCompanion.app
```

---

## Danksagung & Attribution

Inspiriert von und basierend auf Konzepten aus dem Open-Source-Projekt [OpenUsage](https://github.com/leovp/OpenUsage) (MIT Lizenz).

---

## Lizenz

Dieses Projekt ist unter der [MIT-Lizenz](LICENSE) lizenziert.
