import Foundation

/// Background serial queue for building cURL commands, parsing bodies, and truncating large payloads.
/// All heavy work happens off the main thread.
internal final class NetworkLogProcessor {
    
    static let shared = NetworkLogProcessor()
    
    private let processingQueue = DispatchQueue(label: "com.debugdash.network.processor", qos: .utility)
    private let maxBodySize = 512 * 1024  // 512 KB
    
    private init() {}
    
    // MARK: - Request Start
    
    /// Called when a new request is intercepted. Creates entry and records it.
    func processStart(request: URLRequest) -> UUID {
        let id = UUID()
        let url = request.url?.absoluteString ?? ""
        let host = request.url?.host ?? ""
        let path = request.url?.path ?? ""
        let method = request.httpMethod ?? "GET"
        
        // Snapshot headers
        let headers = request.allHTTPHeaderFields ?? [:]
        
        // Snapshot body synchronously (must happen before request is forwarded)
        let bodyData = snapshotBody(from: request)
        let bodyString = truncateBody(bodyData)
        let bodySize = bodyData?.count ?? 0
        
        let entry = CapturedNetworkEntry(
            id: id,
            url: url,
            host: host,
            path: path,
            method: method,
            requestHeaders: headers,
            requestBody: bodyString,
            requestBodySize: bodySize,
            responseHeaders: [:],
            responseBody: nil,
            responseBodySize: 0,
            statusCode: 0,
            state: "pending",
            startTime: Date(),
            endTime: nil,
            duration: nil,
            curlCommand: nil,
            errorMessage: nil
        )
        
        NetworkCaptureManager.shared.recordStart(entry: entry)
        
        // Build cURL on background queue (non-blocking)
        processingQueue.async {
            let curl = self.buildCurlCommand(method: method, url: url, headers: headers, body: bodyData)
            NetworkCaptureManager.shared.recordCompletion(
                id: id, statusCode: 0,
                responseHeaders: [:], responseBody: nil, responseBodySize: 0,
                duration: 0, curlCommand: curl, state: "pending"
            )
        }
        
        return id
    }
    
    // MARK: - Response Completion
    
    func processCompletion(id: UUID, startTime: Date, response: URLResponse?, data: Data?, error: Error?) {
        processingQueue.async {
            let duration = Date().timeIntervalSince(startTime) * 1000  // ms
            
            if let error = error {
                // Fetch existing curl
                let existing = NetworkCaptureManager.shared.entry(by: id)
                NetworkCaptureManager.shared.recordFailure(
                    id: id,
                    error: error.localizedDescription,
                    duration: duration,
                    curlCommand: existing?.curlCommand
                )
                return
            }
            
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode ?? 0
            let responseHeaders = (httpResponse?.allHeaderFields as? [String: String]) ?? [:]
            
            let bodyString = self.truncateBody(data)
            let bodySize = data?.count ?? 0
            
            // Retrieve the cURL that was built during start
            let existing = NetworkCaptureManager.shared.entry(by: id)
            
            NetworkCaptureManager.shared.recordCompletion(
                id: id,
                statusCode: statusCode,
                responseHeaders: responseHeaders,
                responseBody: bodyString,
                responseBodySize: bodySize,
                duration: duration,
                curlCommand: existing?.curlCommand,
                state: "completed"
            )
        }
    }
    
    // MARK: - Mock Completion
    
    func processMockCompletion(id: UUID, startTime: Date, statusCode: Int,
                               responseHeaders: [String: String], responseBody: String?) {
        processingQueue.async {
            let duration = Date().timeIntervalSince(startTime) * 1000
            let existing = NetworkCaptureManager.shared.entry(by: id)
            
            NetworkCaptureManager.shared.recordCompletion(
                id: id,
                statusCode: statusCode,
                responseHeaders: responseHeaders,
                responseBody: responseBody,
                responseBodySize: responseBody?.utf8.count ?? 0,
                duration: duration,
                curlCommand: existing?.curlCommand,
                state: "intercepted"
            )
        }
    }
    
    // MARK: - Body Helpers
    
    private func snapshotBody(from request: URLRequest) -> Data? {
        if let body = request.httpBody {
            return body.count <= maxBodySize ? body : body.prefix(maxBodySize)
        }
        if let stream = request.httpBodyStream {
            return readStream(stream)
        }
        return nil
    }
    
    private func readStream(_ stream: InputStream) -> Data? {
        stream.open()
        defer { stream.close() }
        
        var data = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        
        while stream.hasBytesAvailable {
            let bytesRead = stream.read(buffer, maxLength: bufferSize)
            if bytesRead <= 0 { break }
            data.append(buffer, count: bytesRead)
            if data.count >= maxBodySize { break }
        }
        
        return data.isEmpty ? nil : data
    }
    
    private func truncateBody(_ data: Data?) -> String? {
        guard let data = data, !data.isEmpty else { return nil }
        let truncated = data.count > maxBodySize ? data.prefix(maxBodySize) : data
        if let str = String(data: truncated, encoding: .utf8) {
            return data.count > maxBodySize ? str + "\n...[truncated at 512KB]" : str
        }
        return "[Binary data: \(data.count) bytes]"
    }
    
    // MARK: - cURL Builder
    
    private func buildCurlCommand(method: String, url: String, headers: [String: String], body: Data?) -> String {
        var parts = ["curl"]
        
        if method != "GET" {
            parts.append("-X \(method)")
        }
        
        for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
            let escaped = value.replacingOccurrences(of: "'", with: "'\\''")
            parts.append("-H '\(key): \(escaped)'")
        }
        
        if let body = body, let bodyStr = String(data: body, encoding: .utf8) {
            let escaped = bodyStr.replacingOccurrences(of: "'", with: "'\\''")
            if escaped.count <= 2048 {
                parts.append("-d '\(escaped)'")
            } else {
                parts.append("-d '[body too large for cURL preview]'")
            }
        }
        
        parts.append("'\(url)'")
        
        return parts.joined(separator: " \\\n  ")
    }
}
