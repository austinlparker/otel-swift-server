import Foundation
import SwiftProtobuf
import Vapor
import Compression

/// Main entry point for the OTelSwiftServer library
@available(macOS 13.0, *)
public final class OTelSwiftServer: @unchecked Sendable {
    private let config: OTelServerConfig
    private let server: OTelHTTPServer
    private let decoder: OTLPDecoder
    private let logger: Logger
    
    private let traceService: TraceService
    private let metricsService: MetricsService
    private let logsService: LogsService
    
    private var traceContinuation: AsyncStream<Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest>.Continuation?
    private var metricsContinuation: AsyncStream<Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest>.Continuation?
    private var logsContinuation: AsyncStream<Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest>.Continuation?
    
    /// Stream of received trace data
    public var traces: AsyncStream<Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest>!
    /// Stream of received metrics data
    public var metrics: AsyncStream<Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest>!
    /// Stream of received logs data
    public var logs: AsyncStream<Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest>!
    
    /// Initialize OTelSwiftServer with custom components
    /// - Parameters:
    ///   - config: Server configuration
    ///   - server: The HTTP server implementation to use (if nil, uses VaporServer)
    ///   - decoder: The OTLP decoder to use
    ///   - logger: The logger to use
    public init(
        config: OTelServerConfig = .default,
        server: OTelHTTPServer? = nil,
        decoder: OTLPDecoder = DefaultOTLPDecoder(),
        logger: Logger = ConsoleLogger()
    ) throws {
        self.config = config
        
        if let server = server {
            self.server = server
        } else {
            let app = Application(.production)
            app.http.server.configuration.port = config.port
            self.server = VaporServer(app: app)
        }
        
        self.decoder = decoder
        self.logger = logger
        
        // Initialize services
        self.traceService = TraceService(logger: logger)
        self.metricsService = MetricsService(logger: logger)
        self.logsService = LogsService(logger: logger)
        
        // Initialize streams
        (traces, traceContinuation) = AsyncStream.makeStream()
        (metrics, metricsContinuation) = AsyncStream.makeStream()
        (logs, logsContinuation) = AsyncStream.makeStream()
        
        // Setup endpoints
        setupEndpoints()
    }
    
    private func setupEndpoints() {
        // Traces endpoint
        server.post(path: "/v1/traces") { [weak self] (request: HTTPRequest) async throws -> HTTPResponse in
            guard let self = self else {
                throw OTelServerError.serverError(reason: "Server was deallocated")
            }
            
            let body = request.body
            let contentType = request.contentType
            
            // Check request size
            if body.count > self.config.maxRequestSize {
                throw HTTPError.payloadTooLarge(maxSize: self.config.maxRequestSize)
            }
            
            // Decode request
            let traceRequest = try self.decoder.decodeTraces(body, contentType: contentType)
            
            // Process request
            try self.traceService.process(traceRequest)
            
            // Yield to stream
            self.traceContinuation?.yield(traceRequest)
            
            // Return response with compression if enabled and accepted
            let response = try self.traceService.buildResponse(acceptType: request.acceptType)
            if self.config.enableCompression,
               let acceptEncoding = request.acceptEncoding,
               acceptEncoding.contains("gzip") {
                return VaporResponse(
                    body: response.body,
                    contentType: response.contentType,
                    contentEncoding: "gzip"
                )
            }
            return response
        }
        
        // Metrics endpoint
        server.post(path: "/v1/metrics") { [weak self] (request: HTTPRequest) async throws -> HTTPResponse in
            guard let self = self else {
                throw OTelServerError.serverError(reason: "Server was deallocated")
            }
            
            let body = request.body
            let contentType = request.contentType
            
            // Check request size
            if body.count > self.config.maxRequestSize {
                throw HTTPError.payloadTooLarge(maxSize: self.config.maxRequestSize)
            }
            
            // Decode request
            let metricsRequest = try self.decoder.decodeMetrics(body, contentType: contentType)
            
            // Process request
            try self.metricsService.process(metricsRequest)
            
            // Yield to stream
            self.metricsContinuation?.yield(metricsRequest)
            
            // Return response with compression if enabled and accepted
            let response = try self.metricsService.buildResponse(acceptType: request.acceptType)
            if self.config.enableCompression,
               let acceptEncoding = request.acceptEncoding,
               acceptEncoding.contains("gzip") {
                return VaporResponse(
                    body: response.body,
                    contentType: response.contentType,
                    contentEncoding: "gzip"
                )
            }
            return response
        }
        
        // Logs endpoint
        server.post(path: "/v1/logs") { [weak self] (request: HTTPRequest) async throws -> HTTPResponse in
            guard let self = self else {
                throw OTelServerError.serverError(reason: "Server was deallocated")
            }
            
            let body = request.body
            let contentType = request.contentType
            
            // Check request size
            if body.count > self.config.maxRequestSize {
                throw HTTPError.payloadTooLarge(maxSize: self.config.maxRequestSize)
            }
            
            // Decode request
            let logsRequest = try self.decoder.decodeLogs(body, contentType: contentType)
            
            // Process request
            try self.logsService.process(logsRequest)
            
            // Yield to stream
            self.logsContinuation?.yield(logsRequest)
            
            // Return response with compression if enabled and accepted
            let response = try self.logsService.buildResponse(acceptType: request.acceptType)
            if self.config.enableCompression,
               let acceptEncoding = request.acceptEncoding,
               acceptEncoding.contains("gzip") {
                return VaporResponse(
                    body: response.body,
                    contentType: response.contentType,
                    contentEncoding: "gzip"
                )
            }
            return response
        }
    }
    
    deinit {
        traceContinuation?.finish()
        metricsContinuation?.finish()
        logsContinuation?.finish()
    }
    
    /// Start the OTel server
    /// - Throws: OTelServerError if startup fails
    public func start() async throws {
        logger.info("Starting OTel server", metadata: [
            "host": config.host,
            "port": "\(config.port)"
        ])
        
        try await server.start()
    }
    
    /// Stop the OTel server
    /// - Throws: OTelServerError if shutdown fails
    public func stop() async throws {
        logger.info("Stopping OTel server", metadata: [
            "host": config.host,
            "port": "\(config.port)"
        ])
        
        // Cancel all continuations
        traceContinuation?.finish()
        metricsContinuation?.finish()
        logsContinuation?.finish()
        
        try await server.stop()
    }
    
    /// Get the base URL of the server
    /// - Returns: The base URL as a string (e.g. "http://localhost:4318")
    public var baseURL: String {
        "http://\(config.host):\(server.port)"
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