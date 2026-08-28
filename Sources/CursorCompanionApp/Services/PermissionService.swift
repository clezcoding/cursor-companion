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

    @Published public var keychainStatus: PermissionStatus = .notDetermined
    @Published public var sqliteStatus: PermissionStatus = .notDetermined
    @Published public var notificationStatus: PermissionStatus = .notDetermined

    public init() {
        checkAllPermissions()
    }

    /// Überprüft alle Berechtigungen synchron/asynchron
    public func checkAllPermissions() {
        checkKeychainAccess()
        checkSQLiteAccess()
        checkNotificationAccess()
    }

    /// Prüft den Lese- und Schreibzugriff auf den macOS Schlüsselbund
    public func checkKeychainAccess() {
        let testAccountID = "permissions_check_probe"
        let testTokens = AuthTokens(accessToken: "probe_token", refreshToken: "probe_refresh")
        let storage = SecureKeychainStorage(servicePrefix: "dev.cursorcompanion.probe")
        
        storage.saveTokens(testTokens, accountID: testAccountID)
        if let loaded = storage.getTokens(accountID: testAccountID), loaded.accessToken == "probe_token" {
            storage.deleteTokens(accountID: testAccountID)
            self.keychainStatus = .authorized
        } else {
            self.keychainStatus = .denied
        }
    }

    /// Prüft, ob die Cursor-Datenbank state.vscdb lesbar ist
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

    /// Prüft den Status der macOS-Benachrichtigungen
    public func checkNotificationAccess() {
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

    /// Fordert Benachrichtigungsberechtigung an
    public func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            Task { @MainActor [weak self] in
                self?.notificationStatus = granted ? .authorized : .denied
            }
        }
    }
}
