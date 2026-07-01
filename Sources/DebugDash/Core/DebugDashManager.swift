import Foundation
import UIKit

/// Singleton lifecycle orchestrator for DebugDash
internal final class DebugDashManager {
    
    // MARK: - Singleton
    
    static let shared = DebugDashManager()
    
    // MARK: - Properties
    
    private var webServer: WebServer?
    private var configuration: Configuration = Configuration()
    private var toggleView: ToggleView?
    
    private let stateKey = "com.debugdash.serverRunning"
    private let portKey = "com.debugdash.lastPort"
    
    // MARK: - Computed Properties
    
    var isRunning: Bool {
        webServer?.isRunning ?? false
    }
    
    var dashboardURL: URL? {
        guard isRunning else { return nil }
        return URL(string: "http://localhost:\(configuration.port)/dashboard")
    }
    
    // MARK: - Initialization
    
    private init() {
        // Restore server state if persistence is enabled
        restoreServerState()
    }
    
    // MARK: - Configuration
    
    func configure(with config: Configuration) {
        self.configuration = config
        
        // Configure UserDefaults manager
        UserDefaultsManager.shared.configure(
            suiteNames: config.suiteNames,
            includeStandard: config.includeStandardDefaults
        )
        
        // Configure Database manager
        DatabaseManager.shared.configure(extraPaths: config.databasePaths)
        
        // If server is running with different port, restart it
        if isRunning, let currentServer = webServer {
            if currentServer.isRunning {
                stopServer()
                startServer()
            }
        }
    }
    
    // MARK: - Server Lifecycle
    
    func startServer() {
        guard !isRunning else {
            print("[DebugDash] Server already running")
            return
        }
        
        do {
            let server = WebServer(port: configuration.port)
            try server.start()
            self.webServer = server
            
            // Start network capture
            NetworkCaptureManager.shared.startCapturing()
            
            // Persist state if enabled
            if configuration.persistServerStateAcrossLaunches {
                persistServerState()
            }
            
            // Update toggle view if present
            toggleView?.updateState()
            
            print("[DebugDash] Dashboard available at: \(dashboardURL?.absoluteString ?? "unknown")")
            
        } catch {
            print("[DebugDash] Failed to start server: \(error)")
        }
    }
    
    func stopServer() {
        guard isRunning else {
            print("[DebugDash] Server not running")
            return
        }
        
        webServer?.stop()
        webServer = nil
        
        // Stop network capture
        NetworkCaptureManager.shared.stopCapturing()
        
        // Persist state if enabled
        if configuration.persistServerStateAcrossLaunches {
            persistServerState()
        }
        
        // Update toggle view if present
        toggleView?.updateState()
    }
    
    // MARK: - Toggle UI
    
    func showToggle(in window: UIWindow?) {
        guard let window = window else {
            print("[DebugDash] No window provided for toggle view")
            return
        }
        
        // Remove existing toggle if any
        hideToggle()
        
        // Create and add new toggle
        let toggle = ToggleView()
        toggle.updateState()
        window.addSubview(toggle)
        
        // Position at bottom-right
        toggle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toggle.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -16),
            toggle.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            toggle.widthAnchor.constraint(equalToConstant: 56),
            toggle.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        self.toggleView = toggle
    }
    
    func hideToggle() {
        toggleView?.removeFromSuperview()
        toggleView = nil
    }
    
    // MARK: - State Persistence
    
    private func persistServerState() {
        let defaults = UserDefaults.standard
        defaults.set(isRunning, forKey: stateKey)
        defaults.set(configuration.port, forKey: portKey)
        defaults.synchronize()
    }
    
    private func restoreServerState() {
        guard configuration.persistServerStateAcrossLaunches else { return }
        
        let defaults = UserDefaults.standard
        let wasRunning = defaults.bool(forKey: stateKey)
        
        if wasRunning {
            // Restore the last used port if available
            let lastPort = defaults.object(forKey: portKey) as? UInt16
            if let lastPort = lastPort {
                configuration.port = lastPort
            }
            
            // Auto-start server
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.startServer()
            }
        }
    }
}
