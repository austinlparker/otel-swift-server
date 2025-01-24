import Testing
import VaporTesting
@testable import OTelSwiftServer
import SwiftProtobuf
import Vapor
import Gzip
import OSLog

protocol Service {}
extension TraceService: Service {}
extension MetricsService: Service {}
extension LogsService: Service {}

@Suite("OTelSwiftServer Tests")
struct OTelSwiftServerTests {
    // MARK: - Configuration Tests
    
    @Test("Default configuration should use standard OTLP port")
    func testDefaultConfig() {
        let config = OTelServerConfig.default
        #expect(config.port == 4318)
        #expect(config.host == "localhost")
        #expect(config.maxRequestSize == 5 * 1024 * 1024)
        #expect(!config.enableCompression)
    }
    
    @Test("Custom configuration should override defaults")
    func testCustomConfig() {
        let config = OTelServerConfig(
            port: 8080,
            host: "0.0.0.0",
            maxRequestSize: 1024 * 1024,
            enableCompression: true
        )
        #expect(config.port == 8080)
        #expect(config.host == "0.0.0.0")
        #expect(config.maxRequestSize == 1024 * 1024)
        #expect(config.enableCompression)
    }
    
    // MARK: - Server Lifecycle Tests
    
    @Test("Server should start and stop correctly")
    func testServerLifecycle() async throws {
        let server = TestHTTPServer()
        let config = OTelServerConfig()
        let otelServer = try OTelSwiftServer(config: config, server: server)
        
        try await otelServer.start()
        #expect(server.isRunning)
        
        try await otelServer.stop()
        #expect(!server.isRunning)
    }
    
    // MARK: - Telemetry Processing Tests
    
    @Test("Server should process trace data correctly")
    func testTraceProcessing() async throws {
        let server = TestHTTPServer()
        let config = OTelServerConfig()
        let otelServer = try OTelSwiftServer(config: config, server: server)
        
        // Create sample trace data
        var request = Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest()
        var resourceSpan = Opentelemetry_Proto_Trace_V1_ResourceSpans()
        var resource = Opentelemetry_Proto_Resource_V1_Resource()
        var attr = Opentelemetry_Proto_Common_V1_KeyValue()
        attr.key = "service.name"
        attr.value.stringValue = "test-service"
        resource.attributes = [attr]
        resourceSpan.resource = resource
        request.resourceSpans = [resourceSpan]
        
        // Start server and create receiver
        try await otelServer.start()
        var receivedData: Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest?
        let task = Task {
            for await traceData in otelServer.traces {
                receivedData = traceData
                break
            }
        }
        
        // Send request
        let data = try request.serializedData()
        try await server.simulateRequest(
            path: "/v1/traces",
            body: data,
            contentType: "application/x-protobuf",
            acceptType: "application/x-protobuf"
        )
        
        try await Task.sleep(for: .milliseconds(100))
        task.cancel()
        
        // Verify received data
        #expect(receivedData != nil)
        #expect(receivedData?.resourceSpans.count == 1)
        #expect(receivedData?.resourceSpans[0].resource.attributes[0].key == "service.name")
        #expect(receivedData?.resourceSpans[0].resource.attributes[0].value.stringValue == "test-service")
    }
    
    @Test("Server should handle invalid requests correctly")
    func testInvalidRequests() async throws {
        let server = TestHTTPServer()
        let config = OTelServerConfig()
        let otelServer = try OTelSwiftServer(config: config, server: server)
        
        try await otelServer.start()
        
        // Test missing body
        do {
            try await server.simulateRequest(
                path: "/v1/traces",
                body: nil,
                contentType: "application/x-protobuf",
                acceptType: "application/x-protobuf"
            )
            #expect(Bool(false), "Expected error for missing body")
        } catch {
            if let otelError = error as? OTelServerError {
                #expect(otelError.errorDescription?.contains("Empty request body") == true)
            } else {
                #expect(Bool(false), "Expected OTelServerError but got \(type(of: error))")
            }
        }
        
        // Test invalid content type
        do {
            try await server.simulateRequest(
                path: "/v1/traces",
                body: Data([1, 2, 3]),
                contentType: "invalid",
                acceptType: "application/x-protobuf"
            )
            #expect(Bool(false), "Expected error for invalid content type")
        } catch {
            if let otelError = error as? OTelServerError {
                #expect(otelError.errorDescription?.contains("Failed to decode invalid data: Unsupported content type") == true)
            } else {
                #expect(Bool(false), "Expected OTelServerError but got \(type(of: error))")
            }
        }
        
        // Test invalid protobuf data
        do {
            try await server.simulateRequest(
                path: "/v1/traces",
                body: "invalid data".data(using: .utf8)!,
                contentType: "application/x-protobuf",
                acceptType: "application/x-protobuf"
            )
            #expect(Bool(false), "Expected error for invalid protobuf data")
        } catch {
            if let otelError = error as? OTelServerError {
                #expect(otelError.errorDescription?.contains("Failed to decode") == true)
            } else {
                #expect(Bool(false), "Expected OTelServerError but got \(type(of: error))")
            }
        }
    }
    
    @Test("Server should handle JSON format correctly")
    func testJSONFormat() async throws {
        let server = TestHTTPServer()
        let config = OTelServerConfig()
        let otelServer = try OTelSwiftServer(config: config, server: server)
        
        // Create sample trace data
        var request = Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest()
        var resourceSpan = Opentelemetry_Proto_Trace_V1_ResourceSpans()
        var resource = Opentelemetry_Proto_Resource_V1_Resource()
        var attr = Opentelemetry_Proto_Common_V1_KeyValue()
        attr.key = "service.name"
        attr.value.stringValue = "test-service"
        resource.attributes = [attr]
        resourceSpan.resource = resource
        request.resourceSpans = [resourceSpan]
        
        // Start server and create receiver
        try await otelServer.start()
        var receivedData: Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest?
        let task = Task {
            for await traceData in otelServer.traces {
                receivedData = traceData
                break
            }
        }
        
        // Send request as JSON
        let jsonData = try request.jsonUTF8Data()
        try await server.simulateRequest(
            path: "/v1/traces",
            body: jsonData,
            contentType: "application/json",
            acceptType: "application/json"
        )
        
        try await Task.sleep(for: .milliseconds(100))
        task.cancel()
        
        // Verify received data
        #expect(receivedData != nil)
        #expect(receivedData?.resourceSpans.count == 1)
        #expect(receivedData?.resourceSpans[0].resource.attributes[0].key == "service.name")
        #expect(receivedData?.resourceSpans[0].resource.attributes[0].value.stringValue == "test-service")
    }
    
    @Test("Server should handle request size limit correctly")
    func testRequestSizeLimit() async throws {
        let server = TestHTTPServer()
        let config = OTelServerConfig(maxRequestSize: 10)
        let otelServer = try OTelSwiftServer(config: config, server: server)
        
        try await otelServer.start()
        
        // Test request exceeding size limit
        do {
            try await server.simulateRequest(
                path: "/v1/traces",
                body: Data(repeating: 0, count: 100),
                contentType: "application/json",
                acceptType: "application/json"
            )
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as HTTPError {
            switch error {
            case .payloadTooLarge(let maxSize):
                #expect(maxSize == 10)
            default:
                #expect(Bool(false), "Expected payloadTooLarge error but got \(error)")
            }
        } catch {
            #expect(Bool(false), "Expected HTTPError but got \(error)")
        }
    }
    
    @Test("Server should handle compression correctly")
    func testCompression() async throws {
        let app = try await Application.make(.testing)
        app.http.server.configuration.port = 4319
        let server = VaporServer(app: app)
        let config = OTelServerConfig(port: 4319, enableCompression: true)
        let otelServer = try OTelSwiftServer(config: config, server: server)
        
        // Create sample trace data
        var request = Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest()
        var resourceSpan = Opentelemetry_Proto_Trace_V1_ResourceSpans()
        var resource = Opentelemetry_Proto_Resource_V1_Resource()
        var attr = Opentelemetry_Proto_Common_V1_KeyValue()
        attr.key = "service.name"
        attr.value.stringValue = "test-service"
        resource.attributes = [attr]
        resourceSpan.resource = resource
        request.resourceSpans = [resourceSpan]
        
        // Start server
        try await otelServer.start()
        
        // Create test client
        let client = app.client
        
        // Send compressed request
        let data = try request.serializedData()
        let response = try await client.post("http://localhost:4319/v1/traces") { req in
            req.headers.replaceOrAdd(name: .contentType, value: HTTPMediaType.protobuf.serialize())
            req.headers.add(name: .contentEncoding, value: "gzip")
            
            // Compress the request body using GzipSwift
            let compressedData = try data.gzipped()
            req.headers.add(name: .contentLength, value: compressedData.count.description)
            req.body = ByteBuffer(data: compressedData)
        }
        
        // Verify response status is ok (server successfully decompressed)
        #expect(response.status == HTTPStatus.ok)
        
        // Clean up
        try await otelServer.stop()
    }
}

// MARK: - Test Helpers

final class TestHTTPServer: OTelHTTPServer {
    private(set) var isRunning = false
    private var handlers: [(path: String, handler: @Sendable (HTTPRequest) async throws -> HTTPResponse)] = []
    
    var port: Int = 4318
    
    func start() async throws {
        isRunning = true
    }
    
    func stop() async throws {
        isRunning = false
    }
    
    func post(path: String, handler: @escaping @Sendable (HTTPRequest) async throws -> HTTPResponse) {
        handlers.append((path: path, handler: handler))
    }
    
    func get(path: String, handler: @escaping @Sendable (HTTPRequest) async throws -> HTTPResponse) {
        handlers.append((path: path, handler: handler))
    }
    
    func simulateRequest(
        path: String,
        body: Data?,
        contentType: String,
        acceptType: String,
        contentEncoding: String? = nil,
        acceptEncoding: [String]? = nil
    ) async throws {
        guard let handler = handlers.first(where: { $0.path == path })?.handler else {
            throw OTelServerError.serverError(reason: "No handler for path: \(path)")
        }
        
        let request = TestHTTPRequest(
            body: body ?? Data(),
            contentType: contentType,
            acceptType: acceptType,
            contentEncoding: contentEncoding,
            acceptEncoding: acceptEncoding
        )
        _ = try await handler(request)
    }
}

struct TestHTTPRequest: HTTPRequest {
    let body: Data
    let contentType: String
    let acceptType: String
    let contentEncoding: String?
    let acceptEncoding: [String]?
}

struct TestHTTPResponse: HTTPResponse {
    let body: Data
    let contentType: String
    let contentEncoding: String?
    
    static func ok(body: Data, contentType: String) -> Self {
        TestHTTPResponse(body: body, contentType: contentType, contentEncoding: nil)
    }
    
    static func error(status: Int, message: String) -> Self {
        TestHTTPResponse(body: Data(message.utf8), contentType: "text/plain", contentEncoding: nil)
    }
}
