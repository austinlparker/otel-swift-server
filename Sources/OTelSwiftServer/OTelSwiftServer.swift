import Vapor
import SwiftProtobuf

/// Main entry point for the OTelSwiftServer library
@available(macOS 13.0, *)
public final class OTelSwiftServer {
    private let app: Application
    private let traceService: TraceService
    private let metricsService: MetricsService
    private let logsService: LogsService
    
    private let tracesContinuation: AsyncStream<Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest>.Continuation
    private let metricsContinuation: AsyncStream<Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest>.Continuation
    private let logsContinuation: AsyncStream<Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest>.Continuation
    
    /// Stream of received trace data
    public let traces: AsyncStream<Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest>
    /// Stream of received metrics data
    public let metrics: AsyncStream<Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest>
    /// Stream of received logs data
    public let logs: AsyncStream<Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest>
    
    /// Initialize OTelSwiftServer with a Vapor application
    /// - Parameter app: The Vapor application to use
    public init(app: Application) {
        self.app = app
        
        // Initialize async streams
        var tracesCont: AsyncStream<Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest>.Continuation!
        var metricsCont: AsyncStream<Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest>.Continuation!
        var logsCont: AsyncStream<Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest>.Continuation!
        
        self.traces = AsyncStream { continuation in
            tracesCont = continuation
        }
        self.metrics = AsyncStream { continuation in
            metricsCont = continuation
        }
        self.logs = AsyncStream { continuation in
            logsCont = continuation
        }
        
        self.tracesContinuation = tracesCont
        self.metricsContinuation = metricsCont
        self.logsContinuation = logsCont
        
        // Initialize services
        self.traceService = TraceService(app: app) { [tracesContinuation] request in
            tracesContinuation.yield(request)
        }
        self.metricsService = MetricsService(app: app) { [metricsContinuation] request in
            metricsContinuation.yield(request)
        }
        self.logsService = LogsService(app: app) { [logsContinuation] request in
            logsContinuation.yield(request)
        }
    }
    
    /// Initialize OTelSwiftServer with default configuration
    /// - Parameter port: The port to run the server on (default: 8080)
    /// - Throws: If server initialization fails
    public init(port: Int = 8080) throws {
        self.app = Application(.production)
        self.app.http.server.configuration.port = port
        
        // Initialize async streams
        var tracesCont: AsyncStream<Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest>.Continuation!
        var metricsCont: AsyncStream<Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest>.Continuation!
        var logsCont: AsyncStream<Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest>.Continuation!
        
        self.traces = AsyncStream { continuation in
            tracesCont = continuation
        }
        self.metrics = AsyncStream { continuation in
            metricsCont = continuation
        }
        self.logs = AsyncStream { continuation in
            logsCont = continuation
        }
        
        self.tracesContinuation = tracesCont
        self.metricsContinuation = metricsCont
        self.logsContinuation = logsCont
        
        // Initialize services
        self.traceService = TraceService(app: app) { [tracesContinuation] request in
            tracesContinuation.yield(request)
        }
        self.metricsService = MetricsService(app: app) { [metricsContinuation] request in
            metricsContinuation.yield(request)
        }
        self.logsService = LogsService(app: app) { [logsContinuation] request in
            logsContinuation.yield(request)
        }
    }
    
    deinit {
        tracesContinuation.finish()
        metricsContinuation.finish()
        logsContinuation.finish()
    }
    
    /// Start the OTel server
    /// - Throws: If server startup fails
    public func start() async throws {
        try await app.startup()
    }
    
    /// Stop the OTel server
    public func stop() async throws {
        try await app.asyncShutdown()
    }
    
    /// Get the base URL of the server
    /// - Returns: The base URL as a string (e.g. "http://localhost:8080")
    public var baseURL: String {
        "http://localhost:\(app.http.server.configuration.port)"
    }
    
    /// Get the traces endpoint URL
    public var tracesURL: String {
        "\(baseURL)/v1/traces"
    }
    
    /// Get the metrics endpoint URL
    public var metricsURL: String {
        "\(baseURL)/v1/metrics"
    }
    
    /// Get the logs endpoint URL
    public var logsURL: String {
        "\(baseURL)/v1/logs"
    }
}

// MARK: - Convenience Initializers
extension OTelSwiftServer {
    /// Create an OTelSwiftServer instance for testing
    /// - Returns: A configured OTelSwiftServer instance
    public static func testing() async throws -> OTelSwiftServer {
        let app = try await Application.make(.testing)
        return OTelSwiftServer(app: app)
    }
} 