import Foundation
import SQLite3

public final class WorkspaceTrackerService: @unchecked Sendable {
    public static let shared = WorkspaceTrackerService()
    
    private init() {}
    
    public func getActiveWorkspace() -> String? {
        let fileURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Cursor/User/globalStorage/state.vscdb")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        
        var db: OpaquePointer?
        // Open Read-Only to avoid locking Cursor
        if sqlite3_open_v2(fileURL.path, &db, SQLITE_OPEN_READONLY, nil) != SQLITE_OK {
            sqlite3_close(db)
            return nil
        }
        defer { sqlite3_close(db) }
        
        let query = "SELECT value FROM ItemTable WHERE key = 'history.recentlyOpenedPathsList' LIMIT 1;"
        var statement: OpaquePointer?
        
        var jsonString: String? = nil
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                if let text = sqlite3_column_text(statement, 0) {
                    jsonString = String(cString: text)
                }
            }
        }
        sqlite3_finalize(statement)
        
        guard let jsonStr = jsonString, let data = jsonStr.data(using: .utf8) else { return nil }
        
        struct RecentlyOpened: Decodable {
            struct Entry: Decodable {
                let folderUri: String?
            }
            let entries: [Entry]?
        }
        
        do {
            let parsed = try JSONDecoder().decode(RecentlyOpened.self, from: data)
            if let firstUriStr = parsed.entries?.first?.folderUri, let url = URL(string: firstUriStr) {
                return url.lastPathComponent
            }
        } catch {
            return nil
        }
        return nil
    }
}
