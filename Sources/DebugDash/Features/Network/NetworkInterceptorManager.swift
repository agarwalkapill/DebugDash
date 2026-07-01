import Foundation

// MARK: - InterceptRule Model

internal struct InterceptRule: Codable {
    let id: UUID
    var pathPattern: String           // substring match against request URL path
    var method: String                // "ANY", "GET", "POST", "PUT", "DELETE"
    var mockStatusCode: Int
    var mockResponseBody: String
    var mockResponseHeaders: [String: String]
    var isEnabled: Bool
    var label: String
    let createdAt: Date
    var updatedAt: Date
}

// MARK: - NetworkInterceptorManager

internal final class NetworkInterceptorManager {
    
    static let shared = NetworkInterceptorManager()
    
    private let queue = DispatchQueue(label: "com.debugdash.network.interceptor", attributes: .concurrent)
    private var rules: [InterceptRule] = []
    private var _isIntercepting = false
    private let storageURL: URL
    private let enabledFlagURL: URL
    
    private init() {
        // Store rules in Library/Caches/DebugDash/
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let debugDashDir = cacheDir.appendingPathComponent("DebugDash")
        try? FileManager.default.createDirectory(at: debugDashDir, withIntermediateDirectories: true)
        self.storageURL = debugDashDir.appendingPathComponent("interceptor_rules.json")
        self.enabledFlagURL = debugDashDir.appendingPathComponent("interceptor_enabled")
        loadRulesFromDisk()
        _isIntercepting = FileManager.default.fileExists(atPath: enabledFlagURL.path)
    }
    
    // MARK: - Master Toggle
    
    var isIntercepting: Bool {
        queue.sync { _isIntercepting }
    }
    
    func setIntercepting(_ enabled: Bool) {
        queue.async(flags: .barrier) {
            self._isIntercepting = enabled
            if enabled {
                FileManager.default.createFile(atPath: self.enabledFlagURL.path, contents: nil)
            } else {
                try? FileManager.default.removeItem(at: self.enabledFlagURL)
            }
        }
    }
    
    // MARK: - Rule Matching
    
    func matchingRule(for request: URLRequest) -> InterceptRule? {
        queue.sync {
            guard _isIntercepting else { return nil }
            
            let requestMethod = request.httpMethod?.uppercased() ?? "GET"
            let requestPath = request.url?.path ?? ""
            let requestURL = request.url?.absoluteString ?? ""
            
            return rules.first { rule in
                guard rule.isEnabled else { return false }
                
                // Method check
                let methodMatch = rule.method == "ANY" || rule.method.uppercased() == requestMethod
                guard methodMatch else { return false }
                
                // Path pattern substring match (against path or full URL)
                let pattern = rule.pathPattern
                return requestPath.contains(pattern) || requestURL.contains(pattern)
            }
        }
    }
    
    // MARK: - CRUD Operations
    
    func allRules() -> [InterceptRule] {
        queue.sync { rules }
    }
    
    func addRule(_ rule: InterceptRule) {
        queue.async(flags: .barrier) {
            self.rules.append(rule)
            self.persistRules()
        }
    }
    
    func updateRule(id: UUID, update: (inout InterceptRule) -> Void) -> Bool {
        var success = false
        queue.sync(flags: .barrier) {
            if let idx = self.rules.firstIndex(where: { $0.id == id }) {
                update(&self.rules[idx])
                self.rules[idx].updatedAt = Date()
                self.persistRules()
                success = true
            }
        }
        return success
    }
    
    func deleteRule(id: UUID) -> Bool {
        var success = false
        queue.sync(flags: .barrier) {
            if let idx = self.rules.firstIndex(where: { $0.id == id }) {
                self.rules.remove(at: idx)
                self.persistRules()
                success = true
            }
        }
        return success
    }
    
    func toggleRule(id: UUID) -> Bool {
        return updateRule(id: id) { rule in
            rule.isEnabled.toggle()
        }
    }
    
    func deleteAll() {
        queue.async(flags: .barrier) {
            self.rules.removeAll()
            self.persistRules()
        }
    }
    
    var activeRuleCount: Int {
        queue.sync { rules.filter { $0.isEnabled }.count }
    }
    
    // MARK: - Persistence
    
    private func persistRules() {
        // Called within barrier, so safe to access rules directly
        do {
            let data = try JSONEncoder().encode(rules)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            // Silently fail — never crash host app
        }
    }
    
    private func loadRulesFromDisk() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            rules = try JSONDecoder().decode([InterceptRule].self, from: data)
        } catch {
            rules = []
        }
    }
}
