import Foundation
import UIKit

/// Public API for DebugDash embedded HTTP debugging server
public enum DebugDash {
    
    // MARK: - Configuration
    
    /// Configure DebugDash with custom settings
    /// - Parameter configuration: Configuration object with server settings
    public static func configure(with configuration: Configuration = Configuration()) {
        DebugDashManager.shared.configure(with: configuration)
    }
    
    // MARK: - Server Lifecycle
    
    /// Start the HTTP server
    /// Server will be accessible at http://localhost:<port>/dashboard
    public static func startServer() {
        DebugDashManager.shared.startServer()
    }
    
    /// Stop the HTTP server
    public static func stopServer() {
        DebugDashManager.shared.stopServer()
    }
    
    // MARK: - Toggle UI
    
    /// Show the floating toggle button in the key window
    /// Automatically finds the key window from connected scenes
    public static func showToggle() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            print("[DebugDash] No key window found")
            return
        }
        
        DebugDashManager.shared.showToggle(in: window)
    }
    
    /// Show the floating toggle button in a specific scene
    /// - Parameter scene: The UIWindowScene to display the toggle in
    public static func showToggle(in scene: UIWindowScene) {
        guard let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first else {
            print("[DebugDash] No window found in scene")
            return
        }
        
        DebugDashManager.shared.showToggle(in: window)
    }
    
    /// Hide the floating toggle button
    public static func hideToggle() {
        DebugDashManager.shared.hideToggle()
    }
    
    // MARK: - Network Capture
    
    /// URLProtocol class for network capture injection.
    /// Register this in your URLSessionConfiguration.protocolClasses to capture traffic.
    public static var urlProtocolClass: AnyClass? {
        return PassiveURLProtocol.self
    }
    
    // MARK: - Status
    
    /// Whether the server is currently running
    public static var isRunning: Bool {
        DebugDashManager.shared.isRunning
    }
    
    /// The URL where the dashboard is accessible
    /// Returns nil if server is not running
    public static var dashboardURL: URL? {
        DebugDashManager.shared.dashboardURL
    }
}
