import Foundation

/// Manages UserDefaults inspection and modification across multiple suites
internal final class UserDefaultsManager {
    
    // MARK: - Singleton
    
    static let shared = UserDefaultsManager()
    private init() {}
    
    // MARK: - Nested Types
    
    /// Represents a single UserDefaults entry
    struct DefaultsEntry: Codable {
        let key: String
        let valueString: String  // All values converted to string for transport
        let type: String         // "String", "Int", "Bool", "Date", "Data", "Array", "Dictionary", "Double"
        let suite: String        // "standard" or custom suite name
        let isSystemKey: Bool    // True if this is an iOS system key
        
        enum CodingKeys: String, CodingKey {
            case key, valueString, type, suite, isSystemKey
        }
    }
    
    /// Filter for UserDefaults entries
    enum EntryFilter: String, Codable {
        case all = "all"
        case appOnly = "app"
        case systemOnly = "system"
    }
    
    // MARK: - Configuration
    
    private var suiteNames: Set<String> = []
    private var includeStandard: Bool = true
    
    func configure(suiteNames: Set<String>, includeStandard: Bool) {
        self.suiteNames = suiteNames
        self.includeStandard = includeStandard
    }
    
    // MARK: - Suite Management
    
    /// Returns all available suite names.
    /// Merges manually configured suites with suites auto-discovered from Library/Preferences/.
    func allSuites() -> [String] {
        var suites: [String] = []
        if includeStandard {
            suites.append("standard")
        }
        let allNamedSuites = suiteNames.union(discoverSuites())
        suites.append(contentsOf: allNamedSuites.sorted())
        return suites
    }
    
    /// Adds a custom suite name
    func addSuite(name: String) {
        suiteNames.insert(name)
    }
    
    /// Removes a custom suite name
    func removeSuite(name: String) {
        suiteNames.remove(name)
    }
    
    // MARK: - Reading Entries
    
    /// Returns all entries from all suites, optionally filtered
    func allEntries(filter: EntryFilter = .all) -> [DefaultsEntry] {
        var allEntriesList: [DefaultsEntry] = []
        
        for suite in allSuites() {
            allEntriesList.append(contentsOf: entries(for: suite, filter: filter))
        }
        
        return allEntriesList.sorted { $0.key < $1.key }
    }
    
    /// Returns entries for a specific suite, optionally filtered
    func entries(for suite: String, filter: EntryFilter = .all) -> [DefaultsEntry] {
        guard let defaults = getUserDefaults(for: suite) else {
            return []
        }
        
        let dictionary = defaults.dictionaryRepresentation()
        var entries: [DefaultsEntry] = []
        
        for (key, value) in dictionary {
            let entry = convertToEntry(key: key, value: value, suite: suite)
            
            // Apply filter
            switch filter {
            case .all:
                entries.append(entry)
            case .appOnly:
                if !entry.isSystemKey {
                    entries.append(entry)
                }
            case .systemOnly:
                if entry.isSystemKey {
                    entries.append(entry)
                }
            }
        }
        
        return entries.sorted { $0.key < $1.key }
    }
    
    /// Returns a single entry by key and suite
    func entry(key: String, suite: String) -> DefaultsEntry? {
        guard let defaults = getUserDefaults(for: suite) else {
            return nil
        }
        
        guard let value = defaults.object(forKey: key) else {
            return nil
        }
        
        return convertToEntry(key: key, value: value, suite: suite)
    }
    
    /// Searches entries by key or value substring
    func search(query: String, filter: EntryFilter = .all) -> [DefaultsEntry] {
        let lowercaseQuery = query.lowercased()
        
        return allEntries(filter: filter).filter { entry in
            entry.key.lowercased().contains(lowercaseQuery) ||
            entry.valueString.lowercased().contains(lowercaseQuery)
        }
    }
    
    // MARK: - Writing Entries
    
    /// Sets a value for a key in the specified suite
    @discardableResult
    func setValue(_ valueString: String, type: String, key: String, suite: String) -> Bool {
        guard let defaults = getUserDefaults(for: suite) else {
            return false
        }
        
        // Convert string back to appropriate type
        do {
            switch type {
            case "String":
                defaults.set(valueString, forKey: key)
                
            case "Int":
                if let intValue = Int(valueString) {
                    defaults.set(intValue, forKey: key)
                } else {
                    return false
                }
                
            case "Double":
                if let doubleValue = Double(valueString) {
                    defaults.set(doubleValue, forKey: key)
                } else {
                    return false
                }
                
            case "Bool":
                let boolValue = (valueString.lowercased() == "true" || valueString == "1")
                defaults.set(boolValue, forKey: key)
                
            case "Date":
                let formatter = ISO8601DateFormatter()
                if let date = formatter.date(from: valueString) {
                    defaults.set(date, forKey: key)
                } else {
                    return false
                }
                
            case "Data":
                if let data = Data(base64Encoded: valueString) {
                    defaults.set(data, forKey: key)
                } else {
                    return false
                }
                
            case "Array":
                if let data = valueString.data(using: .utf8),
                   let array = try JSONSerialization.jsonObject(with: data) as? [Any] {
                    defaults.set(array, forKey: key)
                } else {
                    return false
                }
                
            case "Dictionary":
                if let data = valueString.data(using: .utf8),
                   let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    defaults.set(dict, forKey: key)
                } else {
                    return false
                }
                
            default:
                return false
            }
            
            defaults.synchronize()
            return true
            
        } catch {
            print("Error setting value: \(error)")
            return false
        }
    }
    
    /// Deletes a key from the specified suite
    @discardableResult
    func deleteKey(_ key: String, suite: String) -> Bool {
        guard let defaults = getUserDefaults(for: suite) else {
            return false
        }
        
        defaults.removeObject(forKey: key)
        defaults.synchronize()
        return true
    }
    
    // MARK: - Export/Import
    
    /// Exports all UserDefaults to JSON data
    func exportAll() -> Data? {
        var exportData: [String: [[String: String]]] = [:]
        
        for suite in allSuites() {
            let entries = self.entries(for: suite, filter: .all)
            exportData[suite] = entries.map { entry in
                [
                    "key": entry.key,
                    "value": entry.valueString,
                    "type": entry.type
                ]
            }
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            return jsonData
        } catch {
            print("Export error: \(error)")
            return nil
        }
    }
    
    /// Imports UserDefaults from JSON data
    func importAll(from data: Data) -> (success: Int, failed: Int) {
        var successCount = 0
        var failedCount = 0
        
        do {
            guard let importData = try JSONSerialization.jsonObject(with: data) as? [String: [[String: String]]] else {
                return (0, 0)
            }
            
            for (suite, entries) in importData {
                for entry in entries {
                    guard let key = entry["key"],
                          let value = entry["value"],
                          let type = entry["type"] else {
                        failedCount += 1
                        continue
                    }
                    
                    if setValue(value, type: type, key: key, suite: suite) {
                        successCount += 1
                    } else {
                        failedCount += 1
                    }
                }
            }
            
        } catch {
            print("Import error: \(error)")
        }
        
        return (successCount, failedCount)
    }
    
    // MARK: - Private Helpers
    
    private func getUserDefaults(for suite: String) -> UserDefaults? {
        if suite == "standard" {
            return UserDefaults.standard
        } else {
            return UserDefaults(suiteName: suite)
        }
    }
    
    /// Scans Library/Preferences/ for .plist files and returns their names as suite identifiers.
    /// Auto-discovers any named UserDefaults suites the host app has written to.
    /// Note: App Group suites (group.*) are stored outside the app sandbox and are NOT discoverable
    /// here — declare them manually via Configuration.suiteNames.
    private func discoverSuites() -> Set<String> {
        guard let prefsURL = FileManager.default
            .urls(for: .libraryDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Preferences") else {
            return []
        }
        
        let files = (try? FileManager.default.contentsOfDirectory(
            at: prefsURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []
        
        // Exclude the app's own bundle ID — that's UserDefaults.standard, already covered
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        
        let discovered = files
            .filter { $0.pathExtension == "plist" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .filter { name in
                !name.isEmpty &&
                name != bundleId &&                        // standard defaults — already shown
                !name.hasPrefix("com.apple.") &&           // system suites
                !name.hasPrefix("com.debugdash.") &&       // DebugDash's own internal files
                !name.hasSuffix(".LSSharedFileList") &&    // macOS legacy file list plists
                !name.contains("ByHost")                   // per-host preference variants
            }
        
        return Set(discovered)
    }
    
    private func convertToEntry(key: String, value: Any, suite: String) -> DefaultsEntry {
        let type: String
        let valueString: String
        
        switch value {
        case let stringValue as String:
            type = "String"
            valueString = stringValue
            
        case let intValue as Int:
            type = "Int"
            valueString = String(intValue)
            
        case let doubleValue as Double:
            type = "Double"
            valueString = String(doubleValue)
            
        case let boolValue as Bool:
            type = "Bool"
            valueString = boolValue ? "true" : "false"
            
        case let dateValue as Date:
            type = "Date"
            let formatter = ISO8601DateFormatter()
            valueString = formatter.string(from: dateValue)
            
        case let dataValue as Data:
            type = "Data"
            valueString = dataValue.base64EncodedString()
            
        case let arrayValue as [Any]:
            type = "Array"
            if let jsonData = try? JSONSerialization.data(withJSONObject: arrayValue),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                valueString = jsonString
            } else {
                valueString = "\(arrayValue)"
            }
            
        case let dictValue as [String: Any]:
            type = "Dictionary"
            if let jsonData = try? JSONSerialization.data(withJSONObject: dictValue),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                valueString = jsonString
            } else {
                valueString = "\(dictValue)"
            }
            
        default:
            type = "Unknown"
            valueString = "\(value)"
        }
        
        let isSystemKey = detectSystemKey(key)
        
        return DefaultsEntry(
            key: key,
            valueString: valueString,
            type: type,
            suite: suite,
            isSystemKey: isSystemKey
        )
    }
    
    /// Detects if a key is an iOS system key based on common patterns
    private func detectSystemKey(_ key: String) -> Bool {
        // Only allow keys we KNOW are app keys (our prefix)
        // This is an allowlist approach - much more reliable than blocklisting
        let appPrefixes = ["dd_", "com.debugdash"]
        for prefix in appPrefixes {
            if key.hasPrefix(prefix) {
                return false // Definitely an app key
            }
        }
        
        // Common iOS system key prefixes
        let systemPrefixes = [
            "Apple", "NS", "AK", "UI", "CA", "CG", "CF", "CL", "MK",
            "AX", "PK", "GK", "HK", "SK", "WK", "ML", "QL", "SC",
            "ACD", "PK", "Web"
        ]
        
        // Check if key starts with any system prefix
        for prefix in systemPrefixes {
            if key.hasPrefix(prefix) {
                return true
            }
        }
        
        // Common system key patterns (substring matching)
        let systemPatterns = [
            "Internal", "Private", "System", "Framework",
            "kCF", "___", "deviceCheck", "com.apple",
            "Prototype", "Ringer", "Volume", "ShowsUI",
            "Migration", "MultiWindow", "TestRecipe",
            "Emoji", "Enabled", "Active"
        ]
        
        for pattern in systemPatterns {
            if key.contains(pattern) {
                return true
            }
        }
        
        // Specific known iOS/simulator keys
        let knownSystemKeys = Set([
            "AddingEmojiDisplayedList",
            "AddingEmojiKeybordHandled",
            "AppleLanguages",
            "AppleLocale",
            "AppleITunesStoreItemKinds",
            "AppleKeyboards",
            "ApplePasscodeKeyboards",
            "AppleLanguagesDidMigrate",
            "WebKitLocalStorageDatabasePathPreferenceKey",
            "WebDatabaseDirectory",
            "ACDMonthlyAnalyticsLastPosted",
            "ActivePrototypingEnabled",
            "ClearPrototypeCachesForMigration",
            "ClearSettingsArchivesForMigration",
            "MultiWindowEnabled",
            "PrototypeSettingsEnabled",
            "RemotePrototypingEnabled",
            "RingerButtonShowsUI",
            "RingerSwitchShowsUI",
            "TestRecipeEatsRingerButton",
            "TestRecipeEatsRingerSwitch",
            "TestRecipeEatsVolumeDown",
            "TestRecipeEatsVolumeUp",
            "VolumeDownShowsUI",
            "VolumeUpShowsUI"
        ])
        
        return knownSystemKeys.contains(key)
    }
    
    // MARK: - HTTP Request Handling
    
    /// Handles HTTP requests for UserDefaults API endpoints
    func handleDefaultsRequest(_ request: WebServer.HTTPRequest) -> WebServer.HTTPResponse {
        let path = request.path
        let method = request.method
        
        // GET /api/defaults - List all entries
        if path == "/api/defaults" && method == "GET" {
            let suite = request.queryParams["suite"]
            let filterParam = request.queryParams["filter"] ?? "all"
            let filter = EntryFilter(rawValue: filterParam) ?? .all
            
            let entries: [DefaultsEntry]
            if let suite = suite {
                entries = self.entries(for: suite, filter: filter)
            } else {
                entries = allEntries(filter: filter)
            }
            
            // Group by suite
            var grouped: [[String: Any]] = []
            let suiteGroups = Dictionary(grouping: entries) { $0.suite }
            
            for (suite, suitEntries) in suiteGroups.sorted(by: { $0.key < $1.key }) {
                let entriesData = suitEntries.map { entry -> [String: Any] in
                    return [
                        "key": entry.key,
                        "value": entry.valueString,
                        "type": entry.type,
                        "suite": entry.suite,
                        "isSystemKey": entry.isSystemKey
                    ]
                }
                grouped.append([
                    "suite": suite,
                    "entries": entriesData
                ])
            }
            
            return jsonResponse(grouped)
        }
        
        // GET /api/defaults/{key} - Get single entry
        if path.hasPrefix("/api/defaults/") && method == "GET" {
            let key = String(path.dropFirst("/api/defaults/".count))
            let suite = request.queryParams["suite"] ?? "standard"
            
            guard let entry = self.entry(key: key, suite: suite) else {
                return errorResponse("Key not found", status: 404)
            }
            
            let data: [String: Any] = [
                "key": entry.key,
                "value": entry.valueString,
                "type": entry.type,
                "suite": entry.suite,
                "isSystemKey": entry.isSystemKey
            ]
            
            return jsonResponse(data)
        }
        
        // PUT /api/defaults/{key} - Update entry
        if path.hasPrefix("/api/defaults/") && method == "PUT" {
            let key = String(path.dropFirst("/api/defaults/".count))
            
            guard let body = request.body,
                  let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let value = json["value"] as? String,
                  let type = json["type"] as? String,
                  let suite = json["suite"] as? String else {
                return errorResponse("Invalid request body", status: 400)
            }
            
            let success = setValue(value, type: type, key: key, suite: suite)
            return jsonResponse(["success": success])
        }
        
        // DELETE /api/defaults/{key} - Delete entry
        if path.hasPrefix("/api/defaults/") && method == "DELETE" {
            let key = String(path.dropFirst("/api/defaults/".count))
            let suite = request.queryParams["suite"] ?? "standard"
            
            let success = deleteKey(key, suite: suite)
            return jsonResponse(["success": success])
        }
        
        // GET /api/search - Search entries
        if path == "/api/search" && method == "GET" {
            guard let query = request.queryParams["q"], !query.isEmpty else {
                return errorResponse("Missing query parameter", status: 400)
            }
            
            let filterParam = request.queryParams["filter"] ?? "all"
            let filter = EntryFilter(rawValue: filterParam) ?? .all
            
            let results = search(query: query, filter: filter)
            let data = results.map { entry -> [String: Any] in
                return [
                    "key": entry.key,
                    "value": entry.valueString,
                    "type": entry.type,
                    "suite": entry.suite,
                    "isSystemKey": entry.isSystemKey
                ]
            }
            
            return jsonResponse(data)
        }
        
        // GET /api/export - Export all defaults
        if path == "/api/export" && method == "GET" {
            guard let data = exportAll() else {
                return errorResponse("Export failed", status: 500)
            }
            
            return WebServer.HTTPResponse(
                statusCode: 200,
                headers: [
                    "Content-Type": "application/json",
                    "Content-Disposition": "attachment; filename=\"userdefaults-export.json\"",
                    "Content-Length": "\(data.count)",
                    "Access-Control-Allow-Origin": "*"
                ],
                body: data
            )
        }
        
        // POST /api/import - Import defaults
        if path == "/api/import" && method == "POST" {
            guard let body = request.body else {
                return errorResponse("No data provided", status: 400)
            }
            
            let result = importAll(from: body)
            return jsonResponse([
                "success": result.success,
                "failed": result.failed,
                "total": result.success + result.failed
            ])
        }
        
        // GET /api/suites - List all suites
        if path == "/api/suites" && method == "GET" {
            return jsonResponse(allSuites())
        }
        
        // POST /api/suites - Add a suite
        if path == "/api/suites" && method == "POST" {
            guard let body = request.body,
                  let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
                  let name = json["name"] as? String else {
                return errorResponse("Invalid request body", status: 400)
            }
            
            addSuite(name: name)
            return jsonResponse(["success": true])
        }
        
        // DELETE /api/suites/{name} - Remove a suite
        if path.hasPrefix("/api/suites/") && method == "DELETE" {
            let name = String(path.dropFirst("/api/suites/".count))
            removeSuite(name: name)
            return jsonResponse(["success": true])
        }
        
        // Not found
        return errorResponse("Endpoint not found", status: 404)
    }
    
    // MARK: - Response Helpers
    
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
        let error = ["error": message]
        return jsonResponse(error, status: status)
    }
}

