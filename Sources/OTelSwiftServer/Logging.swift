import Foundation

/// Protocol defining structured logging requirements
public protocol Logger {
    /// Log an info message with structured data
    func info(_ message: String, metadata: [String: Any])
    
    /// Log a warning message with structured data
    func warning(_ message: String, metadata: [String: Any])
    
    /// Log an error message with structured data
    func error(_ message: String, metadata: [String: Any])
}

/// Default logger implementation that prints to stdout
public struct ConsoleLogger: Logger {
    public init() {}
    
    public func info(_ message: String, metadata: [String: Any] = [:]) {
        log(level: "INFO", message: message, metadata: metadata)
    }
    
    public func warning(_ message: String, metadata: [String: Any] = [:]) {
        log(level: "WARN", message: message, metadata: metadata)
    }
    
    public func error(_ message: String, metadata: [String: Any] = [:]) {
        log(level: "ERROR", message: message, metadata: metadata)
    }
    
    private func log(level: String, message: String, metadata: [String: Any]) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let metadataString = metadata.isEmpty ? "" : " metadata=\(metadata)"
        print("\(timestamp) [\(level)] \(message)\(metadataString)")
    }
}

/// Logger that can be used in tests to capture log messages
public class TestLogger: Logger {
    public struct LogEntry: Equatable {
        public let level: String
        public let message: String
        public let metadata: [String: Any]
        
        public static func == (lhs: LogEntry, rhs: LogEntry) -> Bool {
            lhs.level == rhs.level && lhs.message == rhs.message
        }
    }
    
    public private(set) var entries: [LogEntry] = []
    
    public init() {}
    
    public func info(_ message: String, metadata: [String: Any] = [:]) {
        entries.append(LogEntry(level: "INFO", message: message, metadata: metadata))
    }
    
    public func warning(_ message: String, metadata: [String: Any] = [:]) {
        entries.append(LogEntry(level: "WARN", message: message, metadata: metadata))
    }
    
    public func error(_ message: String, metadata: [String: Any] = [:]) {
        entries.append(LogEntry(level: "ERROR", message: message, metadata: metadata))
    }
    
    public func clear() {
        entries.removeAll()
    }
} 