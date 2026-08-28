# Design-Spezifikation: CursorCompanion macOS Menüleisten-App

**Version:** 1.0  
**Datum:** 28.08.2026  
**Status:** Genehmigt durch Nutzer (Brainstorming abgeschlossen)  
**Zielsystem:** macOS 13.0+ (Ventura, Sonoma, Sequoia)  
**Technologie-Stack:** Swift 6 (Strict Concurrency), AppKit (`NSStatusItem` + `NSPopover`), SwiftUI, `libsqlite3`, macOS Keychain (`Security.framework`).

---

## 1. Übersicht & Zielsetzung

**CursorCompanion** ist eine native macOS-Menüleisten-App zur permanenten Anzeige beider Cursor-Nutzungspools („Cursor Models" und „Other Models") über mehrere Cursor-Accounts hinweg.

### Kernwerte & Differenzierung
1. **Beide Pools permanent im Blick**: Live-Werte direkt in der macOS-Menüleiste ohne Kontextwechsel in die Cursor-Einstellungen.
2. **Multi-Account-Übersicht**: Verwaltet und zeigt auch Accounts an, in denen der Nutzer aktuell in Cursor nicht angemeldet ist (über isoliert gecachte Tokens im eigenen Keychain).
3. **Sofortige Reaktionszeit**: Kaltstart bis zur Anzeige gecachter Werte < 1 s (kein Blockieren auf Netzwerk-Antworten).
4. **Emil Kowalski Signature UI**: Ultra-minimalistisch (270px Breite), reine Schweizer Typografie, 2px Hairline-Fortschrittslinien, taktile Tasteninteraktion (`:active scale(0.97)`), kein visuelles Rauschen.
5. **Datenschutz & Sicherheit**: 100% lokal, keine Telemetrie, rein lesender Zugriff auf Cursors lokale Datenbank.

---

## 2. Systemarchitektur & Module

Die Applikation ist modular in SwiftPM-Bibliotheken und ein leichtgewichtiges macOS-App-Target unterteilt.

```
CursorCompanion/
├── Package.swift
├── Sources/
│   ├── CursorCompanionCore/
│   │   ├── Auth/
│   │   │   ├── CursorAuth.swift             # Token-Erkennung, Auswahl-Logik & Session-Header
│   │   │   ├── SQLiteReader.swift           # Read-Only C-libsqlite3 Zugriff auf state.vscdb
│   │   │   ├── KeychainReader.swift         # Fallback-Leser für Cursor Keychain-Einträge
│   │   │   └── JWTHelper.swift              # sub/exp Parsing & Session-Cookie-Konstruktion
│   │   ├── Client/
│   │   │   ├── CursorClient.swift           # Connect-RPC & REST Endpoints, 401 Refresh-Retry Loop
│   │   │   ├── CursorEndpoints.swift        # URL-Konstanten (api2.cursor.sh / cursor.com)
│   │   │   └── HTTPClient.swift             # URLSession async/await Abstraktion
│   │   ├── Mapping/
│   │   │   ├── CursorUsageMapper.swift      # JSON -> UsageSnapshot / Domain Mapping
│   │   │   └── DomainModels.swift           # CursorAccount, UsageSnapshot, AccountStatus
│   │   ├── Store/
│   │   │   ├── AccountStore.swift           # Actor: Multi-Account Management
│   │   │   ├── SecureKeychainStorage.swift  # dev.cursorcompanion.account.<id> Keychain Namespace
│   │   │   └── AccountMetadataStorage.swift # UserDefaults Persistenz für Account-Metadaten
│   │   ├── Scheduler/
│   │   │   └── UsageScheduler.swift         # Periodisches Polling & System-Wake Handling
│   │   └── State/
│   │       └── AppState.swift               # @MainActor Observable State für SwiftUI
│   └── CursorCompanionApp/
│       ├── App/
│       │   ├── CursorCompanionApp.swift     # App Entry Point (LSUIElement = true)
│       │   ├── AppDelegate.swift            # AppKit Lifecycle
│       │   └── StatusBarController.swift    # NSStatusItem + NSPopover Controller
│       └── Views/
│           ├── MenuBarLabelView.swift       # Kompakte Statusbar-Anzeige ("63% · 41%")
│           ├── PopoverView.swift            # 270px Minimalistisches Haupt-Popover
│           ├── MetricBlockView.swift        # 2px Hairline Progress Metric Row
│           ├── SettingsView.swift           # Einstellungen-Fenster
│           └── StateViews.swift             # Re-Auth & Empty State Views
└── Tests/
    └── CursorCompanionTests/
        ├── CursorMappingTests.swift         # Fixture-basierte Mapping-Tests
        ├── CursorAuthTests.swift            # JWT-, Cookie- & Token-Tests
        ├── AccountStoreTests.swift          # Multi-Account CRUD & Keychain-Isolation
        └── fixtures/                        # JSON Test-Ressourcen
```

---

## 3. Datenschicht & Protokollspezifikation

### 3.1 Auth-Erkennung & Priorisierung
- **Primär:** `~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`, Tabelle `ItemTable (key, value)`
  - `cursorAuth/accessToken`
  - `cursorAuth/refreshToken`
  - `cursorAuth/stripeMembershipType`
- **Sekundär (macOS Keychain Fallback):**
  - Service `cursor-access-token`
  - Service `cursor-refresh-token`
- **Auswahllogik:**
  1. Beide Quellen lesen.
  2. Falls SQLite `stripeMembershipType == "free"` und Keychain existiert mit abweichendem JWT-`sub` → Keychain-Token verwenden.
  3. Sonst SQLite-Token bevorzugen.
  4. Sonst Keychain-Token verwenden.
  5. Sonst Zustand `notLoggedIn`.

### 3.2 Token & Session-Header
- **JWT-Claims:** `sub` (User-ID nach `|` Split), `exp` (Unix-Ablaufzeit).
- **Session-Cookie:** `WorkosCursorSessionToken=<userID>%3A%3A<accessToken>`.
- **Refresh-Bedingung:** `needsRefresh == true`, wenn `exp - now < 300 s` (5 min Puffer) oder ungültig.

### 3.3 Endpoints
- **Token-Refresh:**
  - `POST https://api2.cursor.sh/oauth/token`
  - Body: `{"grant_type": "refresh_token", "client_id": "KbZUR41cY7W6zRSdpSUJ7I7mLYBKOCmB", "refresh_token": "<token>"}`
- **Connect-RPC (Bearer):**
  - `POST https://api2.cursor.sh/aiserver.v1.DashboardService/GetCurrentPeriodUsage`
  - `POST https://api2.cursor.sh/aiserver.v1.DashboardService/GetPlanInfo`
  - Header: `Authorization: Bearer <token>`, `Connect-Protocol-Version: 1`, `Content-Type: application/json`
- **REST (Cookie):**
  - `GET https://cursor.com/api/usage-summary` (Pfad: `individualUsage.plan.*PercentUsed`, `billingCycleEnd`)
  - `GET https://cursor.com/api/usage?user=<userID>` (Request-Fallback)
  - `GET https://cursor.com/api/auth/stripe` (Optionale On-Demand Daten)

### 3.4 401/403 Retry Loop
Bei HTTP 401/403:
1. Token via Refresh-Endpoint erneuern.
2. Neues Token im `AccountStore` Keychain aktualisieren.
3. Den fehlgeschlagenen Aufruf **genau einmal** wiederholen.
4. Scheitert der Retry → Status `.loginRequired`.

---

## 4. Multi-Account Verwaltung (`AccountStore`)

1. **Isolation:** Jeder Account wird unter einem eigenen Keychain-Namespace gespeichert (`dev.cursorcompanion.account.<userID>`).
2. **Unabhängiges Polling:** Jeder gecachte Account wird parallel mit seinen eigenen Tokens abgefragt (`withTaskGroup`), unabhängig davon, wer in Cursor aktiv eingeloggt ist.
3. **Read-Only Sicherheit:** CursorCompanion schreibt niemals in Cursors `state.vscdb` oder Cursors Keychain.

---

## 5. UI/UX: Emil Kowalski Minimalist Signature Design

### 5.1 Menüleisten-Widget (`StatusBarController`)
- Text: `63% · 41%` mit mintfarbenem (`#10B981`) und bernsteinfarbenem (`#F59E0B`) Indikator.
- Klick öffnet/schließt das Popover mit `scale(0.97)` Einblendung.

### 5.2 Popover (`PopoverView` — 270px Breite)
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
- **Abmessungen:** Exakt 270px Breite, 16px Padding.
- **Hintergrund:** `#121212` mit dezentem 1px Border `#242424`.
- **Fortschrittslinien:** 2px Hairline-Tracks (`#222222`), Füllung in `#10B981` (Cursor Models) und `#F59E0B` (Other Models).
- **Typografie:** Inter / SF Pro mit JetBrains Mono für tabellarische Prozentzahlen (`font-feature-settings: 'tnum'`).
- **Interaktionen:** `:active { transform: scale(0.97); }` auf allen klickbaren Elementen, Easing `cubic-bezier(0.23, 1, 0.32, 1)`.

---

## 6. Teststrategie & Verifikation

- **XCTest Target `CursorCompanionTests`** mit Test-Fixtures Resource Bundle (`fixtures/`).
- **Fixtures:**
  - `usage-summary-individual.json`: Verifiziert Kern-Mapping beider Pools (63.0% und 41.2%) sowie Countdown.
  - `usage-summary-team.json`: Verifiziert defensives Mapping ohne Absturz (`nil` bei individuellen Prozenten).
  - `usage-summary-partial.json`: Verifiziert partielles Mapping.
  - `usage-summary-empty.json`: Verifiziert leeren Planblock.
  - `api-usage-requests.json`: Verifiziert Request-Fallback (412 / 500).
- **Auth-Tests:** JWT-Parsing (`sub` mit/ohne Pipe), Cookie-Format (`%3A%3A`), zeitrelative `needsRefresh`-Prüfung.
- **Store-Tests:** Multi-Account CRUD und Keychain-Isolation.
