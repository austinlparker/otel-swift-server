import Foundation

/// Configuration options for OTelSwiftServer
public struct OTelServerConfig: Sendable {
    /// The port to listen on (default: 4318 - standard OTLP HTTP port)
    public let port: Int
    
    /// The host to bind to (default: "localhost")
    public let host: String
    
    /// Maximum allowed request size in bytes (default: 5MB)
    public let maxRequestSize: Int
    
    /// Whether to enable compression (default: false)
    public let enableCompression: Bool
    
    /// Default configuration
    public static let `default` = OTelServerConfig()
    
    /// Initialize with custom configuration
    /// - Parameters:
    ///   - port: Port to listen on
    ///   - host: Host to bind to
    ///   - maxRequestSize: Maximum allowed request size in bytes
    ///   - enableCompression: Whether to enable response compression
    public init(
        port: Int = 4318,
        host: String = "localhost",
        maxRequestSize: Int = 5 * 1024 * 1024,
        enableCompression: Bool = false
    ) {
        self.port = port
        self.host = host
        self.maxRequestSize = maxRequestSize
        self.enableCompression = enableCompression
    }
} 