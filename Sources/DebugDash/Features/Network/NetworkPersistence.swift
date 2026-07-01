import Foundation

/// Lightweight persistence layer for network capture state.
/// The in-memory ring buffer (NetworkCaptureManager) is the primary store.
/// This class provides optional durable storage for future crash recovery.
/// Currently a no-op placeholder — all data lives in memory for Phase 4.
internal final class NetworkPersistence {
    
    static let shared = NetworkPersistence()
    
    private init() {}
    
    // Reserved for future implementation:
    // - SQLite at Library/Caches/DebugDash/network.sqlite
    // - Background write-behind from ring buffer
    // - Load on cold start for session continuity
    //
    // For Phase 4, the ring buffer + interceptor rules JSON file is sufficient.
    // SQLite persistence can be added in a future iteration without API changes.
}
