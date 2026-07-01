import Foundation

/// Shared URLSession that bypasses PassiveURLProtocol to prevent recursion.
/// Uses default config (no custom protocolClasses) — recursion is prevented by
/// the "handled" key check in PassiveURLProtocol.canInit().
internal final class ForwardingSessionManager: NSObject, URLSessionDelegate {
    
    static let shared = ForwardingSessionManager()
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    private override init() {
        super.init()
    }
    
    /// Forward a request to the real server, returning response via callback on a background queue
    func forward(request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        // Use the delegate-based approach to ensure TLS challenge is handled
        let task = session.dataTask(with: request)
        TaskStore.shared.set(completion: completion, for: task)
        task.resume()
    }
    
    // MARK: - URLSessionDelegate (trust all certs — this is a debug-only tool)
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - URLSessionDataDelegate

extension ForwardingSessionManager: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        TaskStore.shared.appendData(data, for: dataTask)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let stored = TaskStore.shared.remove(for: task)
        stored?.completion(stored?.data, task.response, error)
    }
}

// MARK: - Task storage for delegate-based tasks

private final class TaskStore {
    static let shared = TaskStore()
    
    struct Entry {
        let completion: (Data?, URLResponse?, Error?) -> Void
        var data: Data
    }
    
    private let queue = DispatchQueue(label: "com.debugdash.taskstore", attributes: .concurrent)
    private var entries: [Int: Entry] = [:]
    
    func set(completion: @escaping (Data?, URLResponse?, Error?) -> Void, for task: URLSessionTask) {
        queue.async(flags: .barrier) {
            self.entries[task.taskIdentifier] = Entry(completion: completion, data: Data())
        }
    }
    
    func appendData(_ data: Data, for task: URLSessionTask) {
        queue.async(flags: .barrier) {
            self.entries[task.taskIdentifier]?.data.append(data)
        }
    }
    
    func remove(for task: URLSessionTask) -> Entry? {
        var result: Entry?
        queue.sync {
            result = self.entries[task.taskIdentifier]
        }
        queue.async(flags: .barrier) {
            self.entries.removeValue(forKey: task.taskIdentifier)
        }
        return result
    }
}
