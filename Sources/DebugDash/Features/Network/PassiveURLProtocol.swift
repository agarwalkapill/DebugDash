import Foundation

/// Lightweight network interceptor using Apple's URLProtocol API.
/// Captures all HTTP(S) traffic passing through URLSessions that register this class.
/// Can optionally serve mock responses based on interceptor rules.
internal final class PassiveURLProtocol: URLProtocol {
    
    private static let handledKey = "com.debugdash.handled"
    private var startTime: Date = Date()
    private var entryId: UUID?
    
    // MARK: - URLProtocol Overrides
    
    override class func canInit(with request: URLRequest) -> Bool {
        // Guard 1: Capture must be active
        guard NetworkCaptureManager.shared.isCapturing else { return false }
        
        // Guard 2: Don't intercept already-handled requests (prevent recursion)
        guard URLProtocol.property(forKey: handledKey, in: request) == nil else { return false }
        
        // Guard 3: Only HTTP(S)
        guard let scheme = request.url?.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else { return false }
        
        // Guard 4: Don't capture our own dashboard traffic
        if let host = request.url?.host,
           (host == "localhost" || host == "127.0.0.1"),
           let port = request.url?.port, port == 8080 {
            return false
        }
        
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        startTime = Date()
        
        // Mark request as handled to prevent recursion
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        URLProtocol.setProperty(true, forKey: PassiveURLProtocol.handledKey, in: mutableRequest)
        
        // Record the request start
        let id = NetworkLogProcessor.shared.processStart(request: request)
        self.entryId = id
        
        // Check for mock rule match
        if let rule = NetworkInterceptorManager.shared.matchingRule(for: request) {
            serveMockResponse(rule: rule, id: id)
            return
        }
        
        // Forward to real server
        ForwardingSessionManager.shared.forward(request: mutableRequest as URLRequest) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Record completion
            NetworkLogProcessor.shared.processCompletion(
                id: id, startTime: self.startTime,
                response: response, data: data, error: error
            )
            
            // Deliver response to the original caller
            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
                return
            }
            
            if let response = response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let data = data {
                self.client?.urlProtocol(self, didLoad: data)
            }
            
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    override func stopLoading() {
        // No-op: ForwardingSessionManager handles its own task lifecycle
    }
    
    // MARK: - Mock Response
    
    private func serveMockResponse(rule: InterceptRule, id: UUID) {
        let statusCode = rule.mockStatusCode
        let body = rule.mockResponseBody
        let headers = rule.mockResponseHeaders
        
        // Record as intercepted
        NetworkLogProcessor.shared.processMockCompletion(
            id: id, startTime: startTime,
            statusCode: statusCode,
            responseHeaders: headers,
            responseBody: body
        )
        
        // Build and deliver mock HTTP response
        guard let url = request.url,
              let httpResponse = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: headers
              ) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        
        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        
        if let bodyData = body.data(using: .utf8) {
            client?.urlProtocol(self, didLoad: bodyData)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
}
