import Foundation

/// Configuration for DebugDash server and features
public struct Configuration {
    /// Server port (default: 8080)
    public var port: UInt16
    
    /// UserDefaults suite names to include
    public var suiteNames: Set<String>
    
    /// Additional SQLite database paths to include
    public var databasePaths: [String]
    
    /// Whether to include UserDefaults.standard
    public var includeStandardDefaults: Bool
    
    /// Maximum concurrent browser connections
    public var maxConnections: Int
    
    /// Allow write operations from the web UI
    public var allowWebModifications: Bool
    
    /// Persist server state across app launches
    public var persistServerStateAcrossLaunches: Bool
    
    /// Initialize with default values
    public init(
        port: UInt16 = 8080,
        suiteNames: Set<String> = [],
        databasePaths: [String] = [],
        includeStandardDefaults: Bool = true,
        maxConnections: Int = 5,
        allowWebModifications: Bool = true,
        persistServerStateAcrossLaunches: Bool = true
    ) {
        self.port = port
        self.suiteNames = suiteNames
        self.databasePaths = databasePaths
        self.includeStandardDefaults = includeStandardDefaults
        self.maxConnections = maxConnections
        self.allowWebModifications = allowWebModifications
        self.persistServerStateAcrossLaunches = persistServerStateAcrossLaunches
    }
}
