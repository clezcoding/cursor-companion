import Foundation
import SQLite3

/// Liest Cursor-Authentifizierungsdaten direkt aus der lokalen SQLite-Datenbank state.vscdb
public enum SQLiteReader: Sendable {
    public static var defaultDatabaseURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("Cursor")
            .appendingPathComponent("User")
            .appendingPathComponent("globalStorage")
            .appendingPathComponent("state.vscdb")
    }

    /// Liest die Auth-Schlüssel aus der ItemTable
    public static func readCursorAuth(databaseURL: URL = defaultDatabaseURL) -> RawAuthData? {
        guard FileManager.default.fileExists(atPath: databaseURL.path) else {
            return nil
        }

        var db: OpaquePointer?
        // SQLITE_OPEN_READONLY | SQLITE_OPEN_URI öffnet die Datei ohne Write-Locks
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_URI
        if sqlite3_open_v2(databaseURL.path, &db, flags, nil) != SQLITE_OK {
            if let db = db { sqlite3_close(db) }
            return nil
        }
        defer {
            if let db = db { sqlite3_close(db) }
        }

        let query = "SELECT key, value FROM ItemTable WHERE key IN ('cursorAuth/accessToken', 'cursorAuth/refreshToken', 'cursorAuth/stripeMembershipType');"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            return nil
        }
        defer {
            if let statement = statement { sqlite3_finalize(statement) }
        }

        var accessToken: String?
        var refreshToken: String?
        var membershipType: String?

        while sqlite3_step(statement) == SQLITE_ROW {
            guard let keyCStr = sqlite3_column_text(statement, 0),
                  let valCStr = sqlite3_column_text(statement, 1) else {
                continue
            }
            let key = String(cString: keyCStr)
            let val = String(cString: valCStr)

            switch key {
            case "cursorAuth/accessToken":
                accessToken = val
            case "cursorAuth/refreshToken":
                refreshToken = val
            case "cursorAuth/stripeMembershipType":
                membershipType = val
            default:
                break
            }
        }

        guard let token = accessToken, let refresh = refreshToken else {
            return nil
        }

        return RawAuthData(
            accessToken: token,
            refreshToken: refresh,
            membershipType: membershipType
        )
    }
}
