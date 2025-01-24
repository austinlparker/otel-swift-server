import Foundation
import OSLog

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
    
    /// Logger configuration
    public let logger: os.Logger
    
    /// Default configuration
    public static let `default` = OTelServerConfig()
    
    /// Initialize with custom configuration
    /// - Parameters:
    ///   - port: Port to listen on
    ///   - host: Host to bind to
    ///   - maxRequestSize: Maximum allowed request size in bytes
    ///   - enableCompression: Whether to enable response compression
    ///   - subsystem: The subsystem for logging (default: "com.otel.swift.server")
    ///   - category: The category for logging (default: "otlp")
    public init(
        port: Int = 4318,
        host: String = "localhost",
        maxRequestSize: Int = 5 * 1024 * 1024,
        enableCompression: Bool = false,
        subsystem: String = "com.otel.swift.server",
        category: String = "otlp"
    ) {
        self.port = port
        self.host = host
        self.maxRequestSize = maxRequestSize
        self.enableCompression = enableCompression
        self.logger = Logger(subsystem: subsystem, category: category)
    }
} 