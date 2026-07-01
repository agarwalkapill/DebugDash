import Foundation
import SQLite3

// MARK: - Data Models

internal struct DatabaseInfo {
    let name: String
    let path: String
    let sizeBytes: Int64
    let tableCount: Int
}

internal struct TableInfo {
    let name: String
    let columns: [ColumnInfo]
    let rowCount: Int
}

internal struct ColumnInfo {
    let name: String
    let type: String
    let isPrimaryKey: Bool
    let isNullable: Bool
    let defaultValue: String?
}

internal struct TableDataResult {
    let columns: [String]
    let rows: [[String?]]
    let rowids: [Int64]
    let totalRows: Int
    let page: Int
    let pageSize: Int
    let totalPages: Int
}

internal struct QueryResult {
    let columns: [String]
    let rows: [[String?]]
    let rowCount: Int
    let executionTimeMs: Double
    let error: String?
}

// MARK: - DatabaseManager

internal final class DatabaseManager {
    static let shared = DatabaseManager()
    private var extraPaths: [String] = []
    
    private init() {}
    
    func configure(extraPaths: [String]) {
        self.extraPaths = extraPaths
    }
    
    // MARK: - Discovery
    
    func discoverDatabases() -> [DatabaseInfo] {
        var dbPaths = Set<String>()
        
        // Standard app directories to scan
        let searchDirs: [URL] = {
            var dirs: [URL] = []
            if let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                dirs.append(docDir)
            }
            if let libDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first {
                dirs.append(libDir)
            }
            if let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
                dirs.append(cacheDir)
            }
            dirs.append(FileManager.default.temporaryDirectory)
            return dirs
        }()
        
        let extensions = Set(["sqlite", "sqlite3", "db"])
        
        for dir in searchDirs {
            scanDirectory(dir, extensions: extensions, into: &dbPaths, depth: 0, maxDepth: 5)
        }
        
        // Add configured extra paths
        for path in extraPaths {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: path) {
                if let canonical = try? url.resourceValues(forKeys: [.canonicalPathKey]).canonicalPath {
                    dbPaths.insert(canonical)
                } else {
                    dbPaths.insert(path)
                }
            }
        }
        
        // Build DatabaseInfo for each
        var databases: [DatabaseInfo] = []
        for path in dbPaths {
            let url = URL(fileURLWithPath: path)
            let name = url.deletingPathExtension().lastPathComponent
            
            var sizeBytes: Int64 = 0
            if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
               let size = attrs[.size] as? Int64 {
                sizeBytes = size
            }
            
            let tableCount = (try? countTables(at: path)) ?? 0
            
            databases.append(DatabaseInfo(
                name: name,
                path: path,
                sizeBytes: sizeBytes,
                tableCount: tableCount
            ))
        }
        
        return databases.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    private func scanDirectory(_ dir: URL, extensions: Set<String>, into paths: inout Set<String>, depth: Int, maxDepth: Int) {
        guard depth <= maxDepth else { return }
        guard let enumerator = FileManager.default.enumerator(
            at: dir,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        
        for case let fileURL as URL in enumerator {
            if extensions.contains(fileURL.pathExtension.lowercased()) {
                if let canonical = try? fileURL.resourceValues(forKeys: [.canonicalPathKey]).canonicalPath {
                    paths.insert(canonical)
                } else {
                    paths.insert(fileURL.path)
                }
            }
        }
    }
    
    private func countTables(at path: String) throws -> Int {
        var db: OpaquePointer?
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            throw DatabaseError.cannotOpen
        }
        defer { sqlite3_close(db) }
        
        var stmt: OpaquePointer?
        let sql = "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DatabaseError.queryFailed
        }
        defer { sqlite3_finalize(stmt) }
        
        var count = 0
        if sqlite3_step(stmt) == SQLITE_ROW {
            count = Int(sqlite3_column_int(stmt, 0))
        }
        return count
    }
    
    // MARK: - Schema
    
    func tableNames(for dbPath: String) -> [String] {
        var db: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return []
        }
        defer { sqlite3_close(db) }
        
        var stmt: OpaquePointer?
        let sql = "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            return []
        }
        defer { sqlite3_finalize(stmt) }
        
        var names: [String] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let cStr = sqlite3_column_text(stmt, 0) {
                names.append(String(cString: cStr))
            }
        }
        return names
    }
    
    func tableInfo(dbPath: String, table: String) -> TableInfo? {
        // Validate table name against sqlite_master
        let validTables = tableNames(for: dbPath)
        guard validTables.contains(table) else { return nil }
        
        var db: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return nil
        }
        defer { sqlite3_close(db) }
        
        // Get columns via PRAGMA table_info
        var stmt: OpaquePointer?
        let pragmaSQL = "PRAGMA table_info(\(table))"
        guard sqlite3_prepare_v2(db, pragmaSQL, -1, &stmt, nil) == SQLITE_OK else {
            return nil
        }
        defer { sqlite3_finalize(stmt) }
        
        var columns: [ColumnInfo] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let name = sqlite3_column_text(stmt, 1).map { String(cString: $0) } ?? ""
            let type = sqlite3_column_text(stmt, 2).map { String(cString: $0) } ?? "TEXT"
            let notNull = sqlite3_column_int(stmt, 3) != 0
            let defaultVal = sqlite3_column_text(stmt, 4).map { String(cString: $0) }
            let pk = sqlite3_column_int(stmt, 5) != 0
            
            columns.append(ColumnInfo(
                name: name,
                type: type,
                isPrimaryKey: pk,
                isNullable: !notNull,
                defaultValue: defaultVal
            ))
        }
        
        // Get row count
        var countStmt: OpaquePointer?
        let countSQL = "SELECT COUNT(*) FROM \(table)"
        var rowCount = 0
        if sqlite3_prepare_v2(db, countSQL, -1, &countStmt, nil) == SQLITE_OK {
            if sqlite3_step(countStmt) == SQLITE_ROW {
                rowCount = Int(sqlite3_column_int(countStmt, 0))
            }
            sqlite3_finalize(countStmt)
        }
        
        return TableInfo(name: table, columns: columns, rowCount: rowCount)
    }
    
    // MARK: - Paginated Data
    
    func tableData(dbPath: String, table: String, page: Int, pageSize: Int) -> TableDataResult? {
        // Validate table name
        let validTables = tableNames(for: dbPath)
        guard validTables.contains(table) else { return nil }
        
        var db: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return nil
        }
        defer { sqlite3_close(db) }
        
        // Total rows
        var countStmt: OpaquePointer?
        var totalRows = 0
        if sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM \(table)", -1, &countStmt, nil) == SQLITE_OK {
            if sqlite3_step(countStmt) == SQLITE_ROW {
                totalRows = Int(sqlite3_column_int(countStmt, 0))
            }
            sqlite3_finalize(countStmt)
        }
        
        let safePage = max(1, page)
        let safePageSize = max(1, min(pageSize, 200))
        let totalPages = max(1, Int(ceil(Double(totalRows) / Double(safePageSize))))
        let offset = (safePage - 1) * safePageSize
        
        // Fetch rows with rowid for editing support
        var stmt: OpaquePointer?
        let sql = "SELECT rowid, * FROM \(table) LIMIT \(safePageSize) OFFSET \(offset)"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            return nil
        }
        defer { sqlite3_finalize(stmt) }
        
        let colCount = Int(sqlite3_column_count(stmt))
        // First column is rowid, skip it for column names
        var columnNames: [String] = []
        for i in 1..<colCount {
            let name = sqlite3_column_name(stmt, Int32(i)).map { String(cString: $0) } ?? "col_\(i)"
            columnNames.append(name)
        }
        
        var rows: [[String?]] = []
        var rowids: [Int64] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            // First column is rowid
            rowids.append(sqlite3_column_int64(stmt, 0))
            var row: [String?] = []
            for i in 1..<colCount {
                let colType = sqlite3_column_type(stmt, Int32(i))
                switch colType {
                case SQLITE_NULL:
                    row.append(nil)
                case SQLITE_BLOB:
                    let byteCount = sqlite3_column_bytes(stmt, Int32(i))
                    if byteCount > 0, let blobPtr = sqlite3_column_blob(stmt, Int32(i)) {
                        let previewLen = min(Int(byteCount), 256)
                        let data = Data(bytes: blobPtr, count: previewLen)
                        let hex = data.map { String(format: "%02x", $0) }.joined()
                        row.append("[BLOB: \(byteCount) bytes] \(hex)")
                    } else {
                        row.append("[BLOB: 0 bytes]")
                    }
                default:
                    if let cStr = sqlite3_column_text(stmt, Int32(i)) {
                        row.append(String(cString: cStr))
                    } else {
                        row.append(nil)
                    }
                }
            }
            rows.append(row)
        }
        
        return TableDataResult(
            columns: columnNames,
            rows: rows,
            rowids: rowids,
            totalRows: totalRows,
            page: safePage,
            pageSize: safePageSize,
            totalPages: totalPages
        )
    }
    
    // MARK: - SQL Execution
    
    func executeSQL(dbPath: String, sql: String) -> QueryResult {
        // Guard: only SELECT allowed
        let trimmed = sql.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let disallowed = ["INSERT", "UPDATE", "DELETE", "DROP", "ALTER", "CREATE", "REPLACE", "ATTACH", "DETACH", "REINDEX", "VACUUM"]
        for keyword in disallowed {
            if trimmed.hasPrefix(keyword) {
                return QueryResult(columns: [], rows: [], rowCount: 0, executionTimeMs: 0,
                                   error: "Only SELECT statements are allowed. \(keyword) is not permitted.")
            }
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        var db: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return QueryResult(columns: [], rows: [], rowCount: 0, executionTimeMs: 0,
                               error: "Failed to open database")
        }
        defer { sqlite3_close(db) }
        
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let errMsg = sqlite3_errmsg(db).map { String(cString: $0) } ?? "Unknown error"
            return QueryResult(columns: [], rows: [], rowCount: 0, executionTimeMs: 0, error: errMsg)
        }
        defer { sqlite3_finalize(stmt) }
        
        let colCount = Int(sqlite3_column_count(stmt))
        var columnNames: [String] = []
        for i in 0..<colCount {
            let name = sqlite3_column_name(stmt, Int32(i)).map { String(cString: $0) } ?? "col_\(i)"
            columnNames.append(name)
        }
        
        var rows: [[String?]] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            var row: [String?] = []
            for i in 0..<colCount {
                let colType = sqlite3_column_type(stmt, Int32(i))
                switch colType {
                case SQLITE_NULL:
                    row.append(nil)
                case SQLITE_BLOB:
                    let byteCount = sqlite3_column_bytes(stmt, Int32(i))
                    row.append("[BLOB: \(byteCount) bytes]")
                default:
                    if let cStr = sqlite3_column_text(stmt, Int32(i)) {
                        row.append(String(cString: cStr))
                    } else {
                        row.append(nil)
                    }
                }
            }
            rows.append(row)
        }
        
        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
        
        return QueryResult(
            columns: columnNames,
            rows: rows,
            rowCount: rows.count,
            executionTimeMs: Double(round(elapsed * 100) / 100),
            error: nil
        )
    }
    
    // MARK: - Row Update
    
    func executeWriteSQL(dbPath: String, sql: String) -> (affectedRows: Int, error: String?) {
        var db: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK else {
            return (0, "Failed to open database for writing")
        }
        defer { sqlite3_close(db) }
        
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let errMsg = sqlite3_errmsg(db).map { String(cString: $0) } ?? "Unknown error"
            return (0, errMsg)
        }
        defer { sqlite3_finalize(stmt) }
        
        let result = sqlite3_step(stmt)
        guard result == SQLITE_DONE else {
            let errMsg = sqlite3_errmsg(db).map { String(cString: $0) } ?? "Unknown error"
            return (0, errMsg)
        }
        
        return (Int(sqlite3_changes(db)), nil)
    }
    
    func updateRow(dbPath: String, table: String, rowid: Int64, updates: [String: Any?]) -> (success: Bool, error: String?) {
        // Validate table name
        let validTables = tableNames(for: dbPath)
        guard validTables.contains(table) else {
            return (false, "Invalid table name")
        }
        
        // Validate column names against schema
        guard let schema = tableInfo(dbPath: dbPath, table: table) else {
            return (false, "Cannot read table schema")
        }
        let validColumns = Set(schema.columns.map { $0.name })
        for key in updates.keys {
            guard validColumns.contains(key) else {
                return (false, "Invalid column name: \(key)")
            }
        }
        
        guard !updates.isEmpty else {
            return (false, "No columns to update")
        }
        
        // Open database in read-write mode
        var db: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK else {
            return (false, "Failed to open database for writing")
        }
        defer { sqlite3_close(db) }
        
        // Build parameterized UPDATE query
        let setClauses = updates.keys.sorted().map { "\($0) = ?" }
        let sql = "UPDATE \(table) SET \(setClauses.joined(separator: ", ")) WHERE rowid = ?"
        
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let errMsg = sqlite3_errmsg(db).map { String(cString: $0) } ?? "Unknown error"
            return (false, "Failed to prepare statement: \(errMsg)")
        }
        defer { sqlite3_finalize(stmt) }
        
        // Bind parameters
        var idx: Int32 = 1
        for key in updates.keys.sorted() {
            let value = updates[key]
            if let val = value {
                if val is NSNull {
                    sqlite3_bind_null(stmt, idx)
                } else if let str = val as? String {
                    sqlite3_bind_text(stmt, idx, (str as NSString).utf8String, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                } else if let num = val as? NSNumber {
                    if CFNumberIsFloatType(num) {
                        sqlite3_bind_double(stmt, idx, num.doubleValue)
                    } else {
                        sqlite3_bind_int64(stmt, idx, num.int64Value)
                    }
                } else {
                    sqlite3_bind_text(stmt, idx, "\(val)", -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
                }
            } else {
                sqlite3_bind_null(stmt, idx)
            }
            idx += 1
        }
        // Bind rowid as last parameter
        sqlite3_bind_int64(stmt, idx, rowid)
        
        let result = sqlite3_step(stmt)
        guard result == SQLITE_DONE else {
            let errMsg = sqlite3_errmsg(db).map { String(cString: $0) } ?? "Unknown error"
            return (false, "Update failed: \(errMsg)")
        }
        
        let changes = sqlite3_changes(db)
        if changes == 0 {
            return (false, "No row found with rowid \(rowid)")
        }
        
        return (true, nil)
    }
    
    // MARK: - HTTP Request Handling
    
    func handleDatabaseRequest(_ request: WebServer.HTTPRequest) -> WebServer.HTTPResponse {
        let path = request.path
        let method = request.method
        
        // GET /api/databases — list all databases
        if path == "/api/databases" && method == "GET" {
            let databases = discoverDatabases()
            let data = databases.map { db -> [String: Any] in
                return [
                    "name": db.name,
                    "path": db.path,
                    "sizeBytes": db.sizeBytes,
                    "tableCount": db.tableCount,
                    "sizeFormatted": formatFileSize(db.sizeBytes)
                ]
            }
            return jsonResponse(data)
        }
        
        // GET /api/databases/tables?dbPath=X
        if path == "/api/databases/tables" && method == "GET" {
            guard let dbPath = request.queryParams["dbPath"] else {
                return errorResponse("Missing dbPath parameter", status: 400)
            }
            guard FileManager.default.fileExists(atPath: dbPath) else {
                return errorResponse("Database file not found", status: 404)
            }
            let names = tableNames(for: dbPath)
            return jsonResponse(["tables": names])
        }
        
        // GET /api/databases/table-info?dbPath=X&table=Y
        if path == "/api/databases/table-info" && method == "GET" {
            guard let dbPath = request.queryParams["dbPath"],
                  let table = request.queryParams["table"] else {
                return errorResponse("Missing dbPath or table parameter", status: 400)
            }
            guard let info = tableInfo(dbPath: dbPath, table: table) else {
                return errorResponse("Table not found", status: 404)
            }
            let columnsData = info.columns.map { col -> [String: Any] in
                var d: [String: Any] = [
                    "name": col.name,
                    "type": col.type,
                    "isPrimaryKey": col.isPrimaryKey,
                    "isNullable": col.isNullable
                ]
                if let def = col.defaultValue {
                    d["defaultValue"] = def
                }
                return d
            }
            let result: [String: Any] = [
                "name": info.name,
                "columns": columnsData,
                "rowCount": info.rowCount
            ]
            return jsonResponse(result)
        }
        
        // GET /api/databases/table-data?dbPath=X&table=Y&page=N&pageSize=M
        if path == "/api/databases/table-data" && method == "GET" {
            guard let dbPath = request.queryParams["dbPath"],
                  let table = request.queryParams["table"] else {
                return errorResponse("Missing dbPath or table parameter", status: 400)
            }
            let page = Int(request.queryParams["page"] ?? "1") ?? 1
            let pageSize = Int(request.queryParams["pageSize"] ?? "50") ?? 50
            
            guard let result = tableData(dbPath: dbPath, table: table, page: page, pageSize: pageSize) else {
                return errorResponse("Failed to fetch table data", status: 500)
            }
            
            let data: [String: Any] = [
                "columns": result.columns,
                "rows": result.rows.map { row in row.map { $0 as Any } },
                "rowids": result.rowids,
                "totalRows": result.totalRows,
                "page": result.page,
                "pageSize": result.pageSize,
                "totalPages": result.totalPages
            ]
            return jsonResponse(data)
        }
        
        // POST /api/databases/query — execute SQL
        if path == "/api/databases/query" && method == "POST" {
            guard let body = request.body,
                  let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let dbPath = json["dbPath"] as? String,
                  let sql = json["sql"] as? String else {
                return errorResponse("Invalid request body. Requires {dbPath, sql}", status: 400)
            }
            
            guard FileManager.default.fileExists(atPath: dbPath) else {
                return errorResponse("Database file not found", status: 404)
            }
            
            let result = executeSQL(dbPath: dbPath, sql: sql)
            
            var data: [String: Any] = [
                "columns": result.columns,
                "rows": result.rows.map { row in row.map { $0 as Any } },
                "rowCount": result.rowCount,
                "executionTimeMs": result.executionTimeMs
            ]
            if let error = result.error {
                data["error"] = error
            }
            return jsonResponse(data)
        }
        
        // POST /api/databases/update-row — update a single row
        if path == "/api/databases/update-row" && method == "POST" {
            guard let body = request.body,
                  let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let dbPath = json["dbPath"] as? String,
                  let table = json["table"] as? String,
                  let rowid = json["rowid"] as? Int64,
                  let updates = json["updates"] as? [String: Any] else {
                return errorResponse("Invalid request body. Requires {dbPath, table, rowid, updates}", status: 400)
            }
            
            guard FileManager.default.fileExists(atPath: dbPath) else {
                return errorResponse("Database file not found", status: 404)
            }
            
            // Convert NSNull to nil and keep other values
            var parsedUpdates: [String: Any?] = [:]
            for (key, value) in updates {
                if value is NSNull {
                    parsedUpdates[key] = nil
                } else {
                    parsedUpdates[key] = value
                }
            }
            
            let (success, error) = updateRow(dbPath: dbPath, table: table, rowid: rowid, updates: parsedUpdates)
            
            if success {
                return jsonResponse(["success": true, "message": "Row updated successfully"])
            } else {
                return errorResponse(error ?? "Unknown error", status: 400)
            }
        }
        
        // POST /api/databases/execute-update — execute an UPDATE/INSERT/DELETE statement
        if path == "/api/databases/execute-update" && method == "POST" {
            guard let body = request.body,
                  let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let dbPath = json["dbPath"] as? String,
                  let sql = json["sql"] as? String else {
                return errorResponse("Invalid request body. Requires {dbPath, sql}", status: 400)
            }
            
            guard FileManager.default.fileExists(atPath: dbPath) else {
                return errorResponse("Database file not found", status: 404)
            }
            
            // Only allow UPDATE statements
            let trimmed = sql.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            guard trimmed.hasPrefix("UPDATE") else {
                return errorResponse("Only UPDATE statements are allowed via this endpoint", status: 400)
            }
            
            let result = executeWriteSQL(dbPath: dbPath, sql: sql)
            if let error = result.error {
                return errorResponse(error, status: 400)
            }
            return jsonResponse(["success": true, "message": "Updated \(result.affectedRows) row(s)", "affectedRows": result.affectedRows])
        }
        
        return errorResponse("Not found", status: 404)
    }
    
    // MARK: - Helpers
    
    private func jsonResponse(_ object: Any, status: Int = 200) -> WebServer.HTTPResponse {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted) else {
            return errorResponse("JSON serialization failed", status: 500)
        }
        return WebServer.HTTPResponse(
            statusCode: status,
            headers: [
                "Content-Type": "application/json",
                "Content-Length": "\(jsonData.count)",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type"
            ],
            body: jsonData
        )
    }
    
    private func errorResponse(_ message: String, status: Int) -> WebServer.HTTPResponse {
        return jsonResponse(["error": message], status: status)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024.0) }
        return String(format: "%.1f MB", Double(bytes) / (1024.0 * 1024.0))
    }
    
    private enum DatabaseError: Error {
        case cannotOpen
        case queryFailed
    }
}
