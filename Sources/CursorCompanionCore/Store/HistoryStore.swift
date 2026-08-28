import Foundation
import SQLite3

final class DatabaseHandle: @unchecked Sendable {
    var pointer: OpaquePointer?
    
    init(url: URL) {
        if sqlite3_open(url.path, &pointer) != SQLITE_OK {
            pointer = nil
        }
    }
    
    deinit {
        if let pointer = pointer {
            sqlite3_close(pointer)
        }
    }
}

public actor HistoryStore {
    private let dbHandle: DatabaseHandle
    
    public init(databaseURL: URL) {
        try? FileManager.default.createDirectory(at: databaseURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        dbHandle = DatabaseHandle(url: databaseURL)
        if let db = dbHandle.pointer {
            let createTableQuery = """
            CREATE TABLE IF NOT EXISTS history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                account_id TEXT,
                snapshot_json TEXT
            );
            """
            sqlite3_exec(db, createTableQuery, nil, nil, nil)
        }
    }
    
    public func saveSnapshot(_ snapshot: UsageSnapshot, for accountId: String) {
        guard let db = dbHandle.pointer else { return }
        
        let query = "INSERT INTO history (account_id, snapshot_json) VALUES (?, ?);"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (accountId as NSString).utf8String, -1, nil)
            
            if let data = try? JSONEncoder().encode(snapshot),
               let jsonString = String(data: data, encoding: .utf8) {
                sqlite3_bind_text(statement, 2, (jsonString as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(statement, 2)
            }
            
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    public func fetchHistory(for accountId: String, limit: Int = 100) -> [UsageSnapshot] {
        guard let db = dbHandle.pointer else { return [] }
        var results: [UsageSnapshot] = []
        
        let query = "SELECT snapshot_json FROM history WHERE account_id = ? ORDER BY timestamp DESC LIMIT ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (accountId as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 2, Int32(limit))
            
            while sqlite3_step(statement) == SQLITE_ROW {
                if let jsonText = sqlite3_column_text(statement, 0) {
                    let jsonString = String(cString: jsonText)
                    if let data = jsonString.data(using: .utf8),
                       let snapshot = try? JSONDecoder().decode(UsageSnapshot.self, from: data) {
                        results.append(snapshot)
                    }
                }
            }
        }
        sqlite3_finalize(statement)
        return results
    }
}
