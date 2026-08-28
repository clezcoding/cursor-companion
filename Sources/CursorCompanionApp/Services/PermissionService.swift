import Foundation
import UserNotifications
import Security
import AppKit
import CursorCompanionCore

/// Status einer Systemberechtigung
public enum PermissionStatus: Sendable, Equatable {
    case authorized
    case notDetermined
    case denied
    case notFound(String)
}

/// Service zur einheitlichen Überprüfung und Anforderung aller benötigten Systemberechtigungen
@MainActor
public final class PermissionService: ObservableObject {
    public static let shared = PermissionService()

    private let keychainAuthorizedKey = "dev.cursorcompanion.keychain_authorized"

    @Published public var keychainStatus: PermissionStatus = .notDetermined
    @Published public var sqliteStatus: PermissionStatus = .notDetermined
    @Published public var notificationStatus: PermissionStatus = .notDetermined

    public init() {
        // SQLite direkt prüfen (rein lesender Dateisystem-Check ohne Systemdialoge)
        checkSQLiteAccess()
        
        // Gespeicherte Keychain-Zustände laden (ohne Dialog aufzupoppen)
        if UserDefaults.standard.bool(forKey: keychainAuthorizedKey) {
            self.keychainStatus = .authorized
        } else {
            self.keychainStatus = .notDetermined
        }

        // Benachrichtigungsstatus ermitteln
        checkNotificationStatus()
    }

    /// Prüft, ob die Cursor-Datenbank state.vscdb lesbar ist (passiv, 0 Dialoge)
    public func checkSQLiteAccess() {
        let dbURL = SQLiteReader.defaultDatabaseURL
        if FileManager.default.fileExists(atPath: dbURL.path) {
            if FileManager.default.isReadableFile(atPath: dbURL.path) {
                self.sqliteStatus = .authorized
            } else {
                self.sqliteStatus = .denied
            }
        } else {
            self.sqliteStatus = .notFound("Cursor Datenbank noch nicht angelegt (bitte Cursor starten)")
        }
    }

    /// Fragt den macOS Schlüsselbund genau 1x auf Nutzerklick an
    public func requestKeychainAuthorization() {
        let testAccountID = "companion_auth_probe"
        let testTokens = AuthTokens(accessToken: "probe", refreshToken: "probe")
        let storage = SecureKeychainStorage(servicePrefix: "dev.cursorcompanion.account")
        
        storage.saveTokens(testTokens, accountID: testAccountID)
        storage.deleteTokens(accountID: testAccountID)
        
        UserDefaults.standard.set(true, forKey: keychainAuthorizedKey)
        self.keychainStatus = .authorized
    }

    /// Prüft den Status der macOS-Benachrichtigungen
    public func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            let authStatus = settings.authorizationStatus
            Task { @MainActor [weak self] in
                switch authStatus {
                case .authorized, .provisional:
                    self?.notificationStatus = .authorized
                case .denied:
                    self?.notificationStatus = .denied
                case .notDetermined:
                    self?.notificationStatus = .notDetermined
                @unknown default:
                    self?.notificationStatus = .notDetermined
                }
            }
        }
    }

    /// Fordert Benachrichtigungsberechtigung auf Klick an
    public func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            Task { @MainActor [weak self] in
                self?.notificationStatus = granted ? .authorized : .denied
            }
        }
    }

    /// Aktualisiert alle Status
    public func refreshAll() {
        checkSQLiteAccess()
        checkNotificationStatus()
    }
}
