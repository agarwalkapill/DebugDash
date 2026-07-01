import Foundation
import Network

/// NWListener-based HTTP server for DebugDash dashboard
internal final class WebServer {
    
    // MARK: - Nested Types
    
    struct HTTPRequest {
        let method: String
        let path: String
        let queryParams: [String: String]
        let headers: [String: String]
        let body: Data?
    }
    
    struct HTTPResponse {
        let statusCode: Int
        let headers: [String: String]
        let body: Data?
        
        func serialize() -> Data {
            var response = "HTTP/1.1 \(statusCode) \(statusText)\r\n"
            
            for (key, value) in headers {
                response += "\(key): \(value)\r\n"
            }
            
            response += "\r\n"
            
            var data = response.data(using: .utf8) ?? Data()
            if let body = body {
                data.append(body)
            }
            
            return data
        }
        
        private var statusText: String {
            switch statusCode {
            case 200: return "OK"
            case 400: return "Bad Request"
            case 404: return "Not Found"
            case 500: return "Internal Server Error"
            default: return "Unknown"
            }
        }
    }
    
    // MARK: - Properties
    
    private var listener: NWListener?
    private let port: UInt16
    private let queue = DispatchQueue(label: "com.debugdash.webserver", qos: .userInitiated)
    private(set) var isRunning = false
    private var activeConnections: [NWConnection] = []
    
    // MARK: - Initialization
    
    init(port: UInt16) {
        self.port = port
    }
    
    // MARK: - Lifecycle
    
    func start() throws {
        guard !isRunning else { return }
        
        do {
            // Try to bind to the specified port
            let parameters = NWParameters.tcp
            let port = NWEndpoint.Port(rawValue: self.port)!
            
            listener = try NWListener(using: parameters, on: port)
            
            listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.isRunning = true
                    print("[DebugDash] Server started on port \(self?.port ?? 0)")
                case .failed(let error):
                    print("[DebugDash] Server failed: \(error)")
                    self?.isRunning = false
                case .cancelled:
                    self?.isRunning = false
                    print("[DebugDash] Server cancelled")
                default:
                    break
                }
            }
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            
            listener?.start(queue: queue)
            
        } catch {
            throw error
        }
    }
    
    func stop() {
        guard isRunning else { return }
        
        // Cancel all active connections
        for connection in activeConnections {
            connection.cancel()
        }
        activeConnections.removeAll()
        
        listener?.cancel()
        listener = nil
        isRunning = false
        
        print("[DebugDash] Server stopped")
    }
    
    // MARK: - Connection Handling
    
    private func handleConnection(_ connection: NWConnection) {
        activeConnections.append(connection)
        
        connection.stateUpdateHandler = { [weak self] state in
            if case .cancelled = state {
                self?.activeConnections.removeAll { $0 === connection }
            }
        }
        
        connection.start(queue: queue)
        
        // Read the HTTP request
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                print("[DebugDash] Connection error: \(error)")
                connection.cancel()
                return
            }
            
            guard let data = data, !data.isEmpty else {
                connection.cancel()
                return
            }
            
            // Parse HTTP request
            if let request = self.parseHTTPRequest(data) {
                let response = self.route(request)
                let responseData = response.serialize()
                
                connection.send(content: responseData, completion: .contentProcessed { _ in
                    connection.cancel()
                })
            } else {
                connection.cancel()
            }
        }
    }
    
    // MARK: - HTTP Request Parsing
    
    private func parseHTTPRequest(_ data: Data) -> HTTPRequest? {
        guard let requestString = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        let lines = requestString.components(separatedBy: "\r\n")
        guard !lines.isEmpty else { return nil }
        
        // Parse request line: METHOD PATH HTTP/1.1
        let requestLine = lines[0].components(separatedBy: " ")
        guard requestLine.count >= 2 else { return nil }
        
        let method = requestLine[0]
        let fullPath = requestLine[1]
        
        // Split path and query string
        let pathComponents = fullPath.components(separatedBy: "?")
        let path = pathComponents[0]
        
        var queryParams: [String: String] = [:]
        if pathComponents.count > 1 {
            let queryString = pathComponents[1]
            let pairs = queryString.components(separatedBy: "&")
            for pair in pairs {
                let keyValue = pair.components(separatedBy: "=")
                if keyValue.count == 2 {
                    let key = keyValue[0].removingPercentEncoding ?? keyValue[0]
                    let value = keyValue[1].removingPercentEncoding ?? keyValue[1]
                    queryParams[key] = value
                }
            }
        }
        
        // Parse headers
        var headers: [String: String] = [:]
        var bodyStartIndex = 0
        
        for (index, line) in lines.enumerated() {
            if index == 0 { continue }
            if line.isEmpty {
                bodyStartIndex = index + 1
                break
            }
            
            let headerComponents = line.components(separatedBy: ": ")
            if headerComponents.count >= 2 {
                let key = headerComponents[0]
                let value = headerComponents[1...].joined(separator: ": ")
                headers[key] = value
            }
        }
        
        // Parse body if present
        var body: Data?
        if bodyStartIndex < lines.count {
            let bodyLines = lines[bodyStartIndex...].joined(separator: "\r\n")
            body = bodyLines.data(using: .utf8)
        }
        
        return HTTPRequest(
            method: method,
            path: path,
            queryParams: queryParams,
            headers: headers,
            body: body
        )
    }
    
    // MARK: - Routing
    
    private func route(_ request: HTTPRequest) -> HTTPResponse {
        // CORS preflight
        if request.method == "OPTIONS" {
            return corsPreflightResponse()
        }
        
        // UserDefaults API endpoints
        if request.path.hasPrefix("/api/defaults") ||
           request.path.hasPrefix("/api/suites") ||
           request.path.hasPrefix("/api/search") ||
           request.path == "/api/export" ||
           request.path == "/api/import" {
            return UserDefaultsManager.shared.handleDefaultsRequest(request)
        }
        
        // Database API endpoints
        if request.path.hasPrefix("/api/databases") {
            return DatabaseManager.shared.handleDatabaseRequest(request)
        }
        
        // Network capture API endpoints
        if request.path.hasPrefix("/api/network") {
            return handleNetworkRequest(request)
        }
        
        // Interceptor API endpoints
        if request.path.hasPrefix("/api/interceptor") {
            return handleInterceptorRequest(request)
        }
        
        switch (request.method, request.path) {
        case ("GET", "/dashboard"):
            return serveDashboardHTML()
            
        case ("GET", "/api/status"):
            return serveStatusAPI()
            
        default:
            return notFoundResponse()
        }
    }
    
    // MARK: - Response Handlers
    
    private func serveDashboardHTML() -> HTTPResponse {
        let html = DashboardHTML.generate(port: port, localIP: getLocalIPAddress())
        let body = html.data(using: .utf8)
        
        return HTTPResponse(
            statusCode: 200,
            headers: [
                "Content-Type": "text/html; charset=utf-8",
                "Content-Length": "\(body?.count ?? 0)",
                "Access-Control-Allow-Origin": "*"
            ],
            body: body
        )
    }
    
    private func serveStatusAPI() -> HTTPResponse {
        let networkStats = NetworkCaptureManager.shared.stats()
        let json = """
        {
            "status": "running",
            "port": \(port),
            "ip": "\(getLocalIPAddress())",
            "dbCount": \(DatabaseManager.shared.discoverDatabases().count),
            "requestCount": \(networkStats.totalRequests),
            "version": "1.0.0-phase4",
            "timestamp": \(Date().timeIntervalSince1970)
        }
        """
        
        let body = json.data(using: .utf8)
        
        return HTTPResponse(
            statusCode: 200,
            headers: [
                "Content-Type": "application/json",
                "Content-Length": "\(body?.count ?? 0)",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type"
            ],
            body: body
        )
    }
    
    // MARK: - Network API Handlers
    
    private func handleNetworkRequest(_ request: HTTPRequest) -> HTTPResponse {
        let path = request.path
        let method = request.method
        
        // GET /api/network — list all captured request summaries
        if path == "/api/network" && method == "GET" {
            let summaries = NetworkCaptureManager.shared.summaries()
            let data = summaries.map { s -> [String: Any] in
                var d: [String: Any] = [
                    "id": s.id.uuidString,
                    "url": s.url,
                    "method": s.method,
                    "statusCode": s.statusCode,
                    "state": s.state,
                    "startTime": s.startTime.timeIntervalSince1970,
                    "host": s.host,
                    "path": s.path
                ]
                if let dur = s.duration { d["duration"] = dur }
                return d
            }
            return jsonResponse(data)
        }
        
        // DELETE /api/network — clear all captured requests
        if path == "/api/network" && method == "DELETE" {
            NetworkCaptureManager.shared.clear()
            return jsonResponse(["success": true, "message": "All network entries cleared"])
        }
        
        // GET /api/network/stats — capture statistics
        if path == "/api/network/stats" && method == "GET" {
            let stats = NetworkCaptureManager.shared.stats()
            let data: [String: Any] = [
                "totalRequests": stats.totalRequests,
                "successCount": stats.successCount,
                "errorCount": stats.errorCount,
                "pendingCount": stats.pendingCount,
                "interceptedCount": stats.interceptedCount,
                "avgResponseTime": stats.avgResponseTime,
                "totalDataReceived": stats.totalDataReceived,
                "totalDataSent": stats.totalDataSent
            ]
            return jsonResponse(data)
        }
        
        // GET /api/network/{id} — full entry detail
        if path.hasPrefix("/api/network/") && method == "GET" {
            let idString = String(path.dropFirst("/api/network/".count))
            guard let uuid = UUID(uuidString: idString),
                  let entry = NetworkCaptureManager.shared.entry(by: uuid) else {
                return notFoundResponse()
            }
            
            var data: [String: Any] = [
                "id": entry.id.uuidString,
                "url": entry.url,
                "host": entry.host,
                "path": entry.path,
                "method": entry.method,
                "requestHeaders": entry.requestHeaders,
                "requestBodySize": entry.requestBodySize,
                "responseHeaders": entry.responseHeaders,
                "responseBodySize": entry.responseBodySize,
                "statusCode": entry.statusCode,
                "state": entry.state,
                "startTime": entry.startTime.timeIntervalSince1970
            ]
            if let body = entry.requestBody { data["requestBody"] = body }
            if let body = entry.responseBody { data["responseBody"] = body }
            if let endTime = entry.endTime { data["endTime"] = endTime.timeIntervalSince1970 }
            if let dur = entry.duration { data["duration"] = dur }
            if let curl = entry.curlCommand { data["curlCommand"] = curl }
            if let err = entry.errorMessage { data["errorMessage"] = err }
            
            return jsonResponse(data)
        }
        
        return notFoundResponse()
    }
    
    private func handleInterceptorRequest(_ request: HTTPRequest) -> HTTPResponse {
        let path = request.path
        let method = request.method
        
        // GET /api/interceptor/status
        if path == "/api/interceptor/status" && method == "GET" {
            let data: [String: Any] = [
                "isEnabled": NetworkInterceptorManager.shared.isIntercepting,
                "activeRuleCount": NetworkInterceptorManager.shared.activeRuleCount
            ]
            return jsonResponse(data)
        }
        
        // POST /api/interceptor/toggle — master switch
        if path == "/api/interceptor/toggle" && method == "POST" {
            let current = NetworkInterceptorManager.shared.isIntercepting
            NetworkInterceptorManager.shared.setIntercepting(!current)
            return jsonResponse(["isEnabled": !current])
        }
        
        // GET /api/interceptor/rules — list all rules
        if path == "/api/interceptor/rules" && method == "GET" {
            let rules = NetworkInterceptorManager.shared.allRules()
            let data = rules.map { r -> [String: Any] in
                return [
                    "id": r.id.uuidString,
                    "pathPattern": r.pathPattern,
                    "method": r.method,
                    "mockStatusCode": r.mockStatusCode,
                    "mockResponseBody": r.mockResponseBody,
                    "mockResponseHeaders": r.mockResponseHeaders,
                    "isEnabled": r.isEnabled,
                    "label": r.label,
                    "createdAt": r.createdAt.timeIntervalSince1970,
                    "updatedAt": r.updatedAt.timeIntervalSince1970
                ]
            }
            return jsonResponse(data)
        }
        
        // POST /api/interceptor/rules — create new rule
        if path == "/api/interceptor/rules" && method == "POST" {
            guard let body = request.body,
                  let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                return errorResponse("Invalid request body", status: 400)
            }
            
            let rule = InterceptRule(
                id: UUID(),
                pathPattern: json["pathPattern"] as? String ?? "",
                method: (json["method"] as? String ?? "ANY").uppercased(),
                mockStatusCode: json["mockStatusCode"] as? Int ?? 200,
                mockResponseBody: json["mockResponseBody"] as? String ?? "{}",
                mockResponseHeaders: json["mockResponseHeaders"] as? [String: String] ?? ["Content-Type": "application/json"],
                isEnabled: json["isEnabled"] as? Bool ?? true,
                label: json["label"] as? String ?? "New Rule",
                createdAt: Date(),
                updatedAt: Date()
            )
            
            NetworkInterceptorManager.shared.addRule(rule)
            return jsonResponse(["success": true, "id": rule.id.uuidString])
        }
        
        // DELETE /api/interceptor/rules — delete all rules
        if path == "/api/interceptor/rules" && method == "DELETE" {
            NetworkInterceptorManager.shared.deleteAll()
            return jsonResponse(["success": true])
        }
        
        // Routes with rule ID: /api/interceptor/rules/{id}...
        if path.hasPrefix("/api/interceptor/rules/") {
            let remainder = String(path.dropFirst("/api/interceptor/rules/".count))
            
            // POST /api/interceptor/rules/{id}/toggle
            if remainder.hasSuffix("/toggle") && method == "POST" {
                let idStr = String(remainder.dropLast("/toggle".count))
                guard let uuid = UUID(uuidString: idStr) else {
                    return errorResponse("Invalid rule ID", status: 400)
                }
                let success = NetworkInterceptorManager.shared.toggleRule(id: uuid)
                return success ? jsonResponse(["success": true]) : errorResponse("Rule not found", status: 404)
            }
            
            // PUT /api/interceptor/rules/{id} — update rule
            if method == "PUT" {
                guard let uuid = UUID(uuidString: remainder) else {
                    return errorResponse("Invalid rule ID", status: 400)
                }
                guard let body = request.body,
                      let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
                    return errorResponse("Invalid request body", status: 400)
                }
                
                let success = NetworkInterceptorManager.shared.updateRule(id: uuid) { rule in
                    if let v = json["pathPattern"] as? String { rule.pathPattern = v }
                    if let v = json["method"] as? String { rule.method = v.uppercased() }
                    if let v = json["mockStatusCode"] as? Int { rule.mockStatusCode = v }
                    if let v = json["mockResponseBody"] as? String { rule.mockResponseBody = v }
                    if let v = json["mockResponseHeaders"] as? [String: String] { rule.mockResponseHeaders = v }
                    if let v = json["isEnabled"] as? Bool { rule.isEnabled = v }
                    if let v = json["label"] as? String { rule.label = v }
                }
                
                return success ? jsonResponse(["success": true]) : errorResponse("Rule not found", status: 404)
            }
            
            // DELETE /api/interceptor/rules/{id}
            if method == "DELETE" {
                guard let uuid = UUID(uuidString: remainder) else {
                    return errorResponse("Invalid rule ID", status: 400)
                }
                let success = NetworkInterceptorManager.shared.deleteRule(id: uuid)
                return success ? jsonResponse(["success": true]) : errorResponse("Rule not found", status: 404)
            }
        }
        
        return notFoundResponse()
    }
    
    private func jsonResponse(_ object: Any) -> HTTPResponse {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted) else {
            return errorResponse("JSON serialization failed", status: 500)
        }
        return HTTPResponse(
            statusCode: 200,
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
    
    private func errorResponse(_ message: String, status: Int) -> HTTPResponse {
        let json = "{\"error\": \"\(message)\"}"
        let body = json.data(using: .utf8)
        return HTTPResponse(
            statusCode: status,
            headers: [
                "Content-Type": "application/json",
                "Content-Length": "\(body?.count ?? 0)",
                "Access-Control-Allow-Origin": "*"
            ],
            body: body
        )
    }
    
    private func corsPreflightResponse() -> HTTPResponse {
        return HTTPResponse(
            statusCode: 200,
            headers: [
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type",
                "Content-Length": "0"
            ],
            body: nil
        )
    }
    
    private func notFoundResponse() -> HTTPResponse {
        let json = """
        {
            "error": "Not Found",
            "message": "The requested resource does not exist"
        }
        """
        
        let body = json.data(using: .utf8)
        
        return HTTPResponse(
            statusCode: 404,
            headers: [
                "Content-Type": "application/json",
                "Content-Length": "\(body?.count ?? 0)",
                "Access-Control-Allow-Origin": "*"
            ],
            body: body
        )
    }
    
    // MARK: - Utilities
    
    private func getLocalIPAddress() -> String {
        var address: String = "localhost"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else {
            return address
        }
        
        defer {
            freeifaddrs(ifaddr)
        }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee else { continue }
            
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                let name = String(cString: interface.ifa_name)
                
                // Look for en0 (WiFi) or en1 (Ethernet)
                if name == "en0" || name == "en1" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr,
                               socklen_t(interface.ifa_addr.pointee.sa_len),
                               &hostname,
                               socklen_t(hostname.count),
                               nil,
                               socklen_t(0),
                               NI_NUMERICHOST)
                    
                    let addressString = String(cString: hostname)
                    
                    // Prefer IPv4 addresses
                    if addrFamily == UInt8(AF_INET) {
                        address = addressString
                        break
                    } else if address == "localhost" {
                        address = addressString
                    }
                }
            }
        }
        
        return address
    }
}
