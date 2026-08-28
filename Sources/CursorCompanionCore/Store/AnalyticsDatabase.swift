import Foundation
import SQLite3

public struct AnalyticsSnapshot: Codable, Identifiable {
    public let id: Int64
    public let timestamp: Date
    public let accountID: String
    public let cursorPercent: Double
    public let otherPercent: Double
    public let workspace: String?
}

public final class AnalyticsDatabase: @unchecked Sendable {
    public static let shared = AnalyticsDatabase()
    private var db: OpaquePointer?
    
    private let dbQueue = DispatchQueue(label: "com.cursorcompanion.analyticsdb")
    
    private init() {
        let fileURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("CursorCompanion")
            .appendingPathComponent("analytics.sqlite")
        
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        if sqlite3_open(fileURL.path, &db) == SQLITE_OK {
            let createTableQuery = """
            CREATE TABLE IF NOT EXISTS usage_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                account_id TEXT,
                cursor_percent REAL,
                other_percent REAL,
                workspace TEXT
            );
            """
            sqlite3_exec(db, createTableQuery, nil, nil, nil)
            
            // Migrate if needed
            sqlite3_exec(db, "ALTER TABLE usage_history ADD COLUMN workspace TEXT;", nil, nil, nil)
        }
    }
    
    deinit {
        sqlite3_close(db)
    }
    
    public func saveSnapshot(accountID: String, cursorPercent: Double, otherPercent: Double, workspace: String?) {
        dbQueue.async { [weak self] in
            guard let self = self, let db = self.db else { return }
            
            let query = "INSERT INTO usage_history (account_id, cursor_percent, other_percent, workspace) VALUES (?, ?, ?, ?);"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (accountID as NSString).utf8String, -1, nil)
                sqlite3_bind_double(statement, 2, cursorPercent)
                sqlite3_bind_double(statement, 3, otherPercent)
                
                if let workspace = workspace {
                    sqlite3_bind_text(statement, 4, (workspace as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(statement, 4)
                }
                
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    public func fetchHistory(for accountID: String, limit: Int = 100) -> [AnalyticsSnapshot] {
        var results: [AnalyticsSnapshot] = []
        dbQueue.sync {
            guard let db = db else { return }
            
            let query = "SELECT id, timestamp, account_id, cursor_percent, other_percent, workspace FROM usage_history WHERE account_id = ? ORDER BY timestamp DESC LIMIT ?;"
            var statement: OpaquePointer?
            
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (accountID as NSString).utf8String, -1, nil)
                sqlite3_bind_int(statement, 2, Int32(limit))
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                while sqlite3_step(statement) == SQLITE_ROW {
                    let id = sqlite3_column_int64(statement, 0)
                    
                    let timestampStr = String(cString: sqlite3_column_text(statement, 1))
                    let timestamp = dateFormatter.date(from: timestampStr) ?? Date()
                    
                    let accId = String(cString: sqlite3_column_text(statement, 2))
                    let cPercent = sqlite3_column_double(statement, 3)
                    let oPercent = sqlite3_column_double(statement, 4)
                    
                    var wsName: String? = nil
                    if let wsText = sqlite3_column_text(statement, 5) {
                        wsName = String(cString: wsText)
                    }
                    
                    results.append(AnalyticsSnapshot(id: id, timestamp: timestamp, accountID: accId, cursorPercent: cPercent, otherPercent: oPercent, workspace: wsName))
                }
            }
            sqlite3_finalize(statement)
        }
        return results
    }
}
