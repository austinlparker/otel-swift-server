import Foundation

/// Errors that can occur while running the OTel server
public enum OTelServerError: LocalizedError {
    /// Server failed to start
    case serverStartupFailed(underlying: Error)
    
    /// Server failed to shut down
    case serverShutdownFailed(underlying: Error)
    
    /// Invalid telemetry data received
    case invalidTelemetryData(reason: String)
    
    /// Failed to decode telemetry data
    case decodingFailed(format: String, reason: String)
    
    /// Configuration error
    case configurationError(reason: String)
    
    /// Internal server error
    case serverError(reason: String)
    
    /// Invalid request received
    case invalidRequest(reason: String)
    
    public var errorDescription: String? {
        switch self {
        case .serverStartupFailed(let error):
            return "Failed to start server: \(error.localizedDescription)"
        case .serverShutdownFailed(let error):
            return "Failed to shut down server: \(error.localizedDescription)"
        case .invalidTelemetryData(let reason):
            return "Invalid telemetry data: \(reason)"
        case .decodingFailed(let format, let reason):
            return "Failed to decode \(format) data: \(reason)"
        case .configurationError(let reason):
            return "Configuration error: \(reason)"
        case .serverError(let reason):
            return "Server error: \(reason)"
        case .invalidRequest(let reason):
            return "Invalid request: \(reason)"
        }
    }
} 