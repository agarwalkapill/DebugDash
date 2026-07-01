import Foundation

// MARK: - Data Models

internal struct CapturedNetworkEntry: Codable {
    let id: UUID
    let url: String
    let host: String
    let path: String
    let method: String
    var requestHeaders: [String: String]
    var requestBody: String?
    var requestBodySize: Int
    var responseHeaders: [String: String]
    var responseBody: String?
    var responseBodySize: Int
    var statusCode: Int
    var state: String  // "pending", "completed", "failed", "intercepted"
    let startTime: Date
    var endTime: Date?
    var duration: Double?
    var curlCommand: String?
    var errorMessage: String?
}

internal struct NetworkEntrySummary: Codable {
    let id: UUID
    let url: String
    let method: String
    let statusCode: Int
    let state: String
    let startTime: Date
    let duration: Double?
    let host: String
    let path: String
}

internal struct NetworkStats: Codable {
    let totalRequests: Int
    let successCount: Int
    let errorCount: Int
    let pendingCount: Int
    let interceptedCount: Int
    let avgResponseTime: Double
    let totalDataReceived: Int64
    let totalDataSent: Int64
}

// MARK: - NetworkCaptureManager

internal final class NetworkCaptureManager {
    
    static let shared = NetworkCaptureManager()
    
    private let queue = DispatchQueue(label: "com.debugdash.network.capture", attributes: .concurrent)
    private var entries: [CapturedNetworkEntry] = []
    private var _isCapturing = false
    private let maxEntries = 500
    
    private init() {}
    
    // MARK: - Capture State
    
    var isCapturing: Bool {
        queue.sync { _isCapturing }
    }
    
    func startCapturing() {
        queue.async(flags: .barrier) {
            self._isCapturing = true
        }
    }
    
    func stopCapturing() {
        queue.async(flags: .barrier) {
            self._isCapturing = false
        }
    }
    
    // MARK: - Recording
    
    func recordStart(entry: CapturedNetworkEntry) {
        queue.async(flags: .barrier) {
            self.entries.append(entry)
            // Ring buffer eviction — oldest first
            if self.entries.count > self.maxEntries {
                self.entries.removeFirst(self.entries.count - self.maxEntries)
            }
        }
    }
    
    func recordCompletion(id: UUID, statusCode: Int, responseHeaders: [String: String],
                          responseBody: String?, responseBodySize: Int,
                          duration: Double, curlCommand: String?, state: String = "completed") {
        queue.async(flags: .barrier) {
            guard let idx = self.entries.firstIndex(where: { $0.id == id }) else { return }
            self.entries[idx].statusCode = statusCode
            self.entries[idx].responseHeaders = responseHeaders
            self.entries[idx].responseBody = responseBody
            self.entries[idx].responseBodySize = responseBodySize
            self.entries[idx].duration = duration
            self.entries[idx].endTime = Date()
            self.entries[idx].curlCommand = curlCommand
            self.entries[idx].state = state
        }
    }
    
    func recordFailure(id: UUID, error: String, duration: Double, curlCommand: String?) {
        queue.async(flags: .barrier) {
            guard let idx = self.entries.firstIndex(where: { $0.id == id }) else { return }
            self.entries[idx].state = "failed"
            self.entries[idx].errorMessage = error
            self.entries[idx].duration = duration
            self.entries[idx].endTime = Date()
            self.entries[idx].curlCommand = curlCommand
        }
    }
    
    // MARK: - Query
    
    func allEntries() -> [CapturedNetworkEntry] {
        queue.sync { entries }
    }
    
    func summaries() -> [NetworkEntrySummary] {
        queue.sync {
            entries.reversed().map { entry in
                NetworkEntrySummary(
                    id: entry.id,
                    url: entry.url,
                    method: entry.method,
                    statusCode: entry.statusCode,
                    state: entry.state,
                    startTime: entry.startTime,
                    duration: entry.duration,
                    host: entry.host,
                    path: entry.path
                )
            }
        }
    }
    
    func entry(by id: UUID) -> CapturedNetworkEntry? {
        queue.sync { entries.first(where: { $0.id == id }) }
    }
    
    func stats() -> NetworkStats {
        queue.sync {
            let total = entries.count
            let completed = entries.filter { $0.state == "completed" }
            let failed = entries.filter { $0.state == "failed" }
            let pending = entries.filter { $0.state == "pending" }
            let intercepted = entries.filter { $0.state == "intercepted" }
            
            let durations = completed.compactMap { $0.duration }
            let avg = durations.isEmpty ? 0.0 : durations.reduce(0, +) / Double(durations.count)
            
            let received = entries.reduce(Int64(0)) { $0 + Int64($1.responseBodySize) }
            let sent = entries.reduce(Int64(0)) { $0 + Int64($1.requestBodySize) }
            
            return NetworkStats(
                totalRequests: total,
                successCount: completed.count,
                errorCount: failed.count,
                pendingCount: pending.count,
                interceptedCount: intercepted.count,
                avgResponseTime: Double(round(avg * 100) / 100),
                totalDataReceived: received,
                totalDataSent: sent
            )
        }
    }
    
    func clear() {
        queue.async(flags: .barrier) {
            self.entries.removeAll()
        }
    }
    
    var entryCount: Int {
        queue.sync { entries.count }
    }
}
