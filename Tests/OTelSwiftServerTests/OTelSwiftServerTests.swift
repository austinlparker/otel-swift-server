import Testing
import VaporTesting
@testable import OTelSwiftServer

protocol Service {}
extension TraceService: Service {}
extension MetricsService: Service {}
extension LogsService: Service {}

@Suite("OTelSwiftServer Tests", .serialized)
struct OTelSwiftServerTests {
    private func withApp(_ test: (Application) async throws -> ()) async throws {
        let app = try await Application.make(.testing)
        do {
            // Initialize all services and store them
            let services: [Service] = [
                TraceService(app: app),
                MetricsService(app: app),
                LogsService(app: app)
            ]
            _ = services // Keep strong reference
            
            try await app.startup()
            try await test(app)
        } catch {
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
    
    @Test("Test Trace Endpoint")
    func testTraceEndpoint() async throws {
        try await withApp { app in
            // Create a sample trace request
            var request = Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest()
            var resourceSpans = Opentelemetry_Proto_Trace_V1_ResourceSpans()
            var resource = Opentelemetry_Proto_Resource_V1_Resource()
            
            var attr = Opentelemetry_Proto_Common_V1_KeyValue()
            attr.key = "service.name"
            var value = Opentelemetry_Proto_Common_V1_AnyValue()
            value.stringValue = "test-service"
            attr.value = value
            resource.attributes = [attr]
            resourceSpans.resource = resource
            
            var scope = Opentelemetry_Proto_Trace_V1_ScopeSpans()
            var span = Opentelemetry_Proto_Trace_V1_Span()
            span.name = "test-span"
            span.kind = .client
            span.startTimeUnixNano = UInt64(Date().timeIntervalSince1970 * 1_000_000_000)
            span.endTimeUnixNano = UInt64(Date().timeIntervalSince1970 * 1_000_000_000)
            scope.spans = [span]
            resourceSpans.scopeSpans = [scope]
            request.resourceSpans = [resourceSpans]
            
            let bytes = try request.serializedData()
            
            try await app.testing().test(.POST, "/v1/traces") { req async in
                req.headers.contentType = HTTPMediaType(type: "application", subType: "x-protobuf")
                req.body = ByteBuffer(data: bytes)
            } afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.headers.contentType?.type == "application")
                #expect(res.headers.contentType?.subType == "x-protobuf")
            }
        }
    }
    
    @Test("Test Metrics Endpoint")
    func testMetricsEndpoint() async throws {
        try await withApp { app in
            // Create a sample metrics request
            var request = Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest()
            var resourceMetrics = Opentelemetry_Proto_Metrics_V1_ResourceMetrics()
            var resource = Opentelemetry_Proto_Resource_V1_Resource()
            
            var attr = Opentelemetry_Proto_Common_V1_KeyValue()
            attr.key = "service.name"
            var value = Opentelemetry_Proto_Common_V1_AnyValue()
            value.stringValue = "test-service"
            attr.value = value
            resource.attributes = [attr]
            resourceMetrics.resource = resource
            
            var scope = Opentelemetry_Proto_Metrics_V1_ScopeMetrics()
            var metric = Opentelemetry_Proto_Metrics_V1_Metric()
            metric.name = "test-metric"
            var gauge = Opentelemetry_Proto_Metrics_V1_Gauge()
            var dataPoint = Opentelemetry_Proto_Metrics_V1_NumberDataPoint()
            dataPoint.timeUnixNano = UInt64(Date().timeIntervalSince1970 * 1_000_000_000)
            dataPoint.asDouble = 42.0
            gauge.dataPoints = [dataPoint]
            metric.gauge = gauge
            scope.metrics = [metric]
            resourceMetrics.scopeMetrics = [scope]
            request.resourceMetrics = [resourceMetrics]
            
            let bytes = try request.serializedData()
            
            try await app.testing().test(.POST, "/v1/metrics") { req async in
                req.headers.contentType = HTTPMediaType(type: "application", subType: "x-protobuf")
                req.body = ByteBuffer(data: bytes)
            } afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.headers.contentType?.type == "application")
                #expect(res.headers.contentType?.subType == "x-protobuf")
            }
        }
    }
    
    @Test("Test Logs Endpoint")
    func testLogsEndpoint() async throws {
        try await withApp { app in
            // Create a sample logs request
            var request = Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest()
            var resourceLogs = Opentelemetry_Proto_Logs_V1_ResourceLogs()
            var resource = Opentelemetry_Proto_Resource_V1_Resource()
            
            var attr = Opentelemetry_Proto_Common_V1_KeyValue()
            attr.key = "service.name"
            var value = Opentelemetry_Proto_Common_V1_AnyValue()
            value.stringValue = "test-service"
            attr.value = value
            resource.attributes = [attr]
            resourceLogs.resource = resource
            
            var scope = Opentelemetry_Proto_Logs_V1_ScopeLogs()
            var record = Opentelemetry_Proto_Logs_V1_LogRecord()
            record.timeUnixNano = UInt64(Date().timeIntervalSince1970 * 1_000_000_000)
            record.severityText = "INFO"
            var body = Opentelemetry_Proto_Common_V1_AnyValue()
            body.stringValue = "Test log message"
            record.body = body
            scope.logRecords = [record]
            resourceLogs.scopeLogs = [scope]
            request.resourceLogs = [resourceLogs]
            
            let bytes = try request.serializedData()
            
            try await app.testing().test(.POST, "/v1/logs") { req async in
                req.headers.contentType = HTTPMediaType(type: "application", subType: "x-protobuf")
                req.body = ByteBuffer(data: bytes)
            } afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.headers.contentType?.type == "application")
                #expect(res.headers.contentType?.subType == "x-protobuf")
            }
        }
    }
    
    @Test("Test Invalid Request Body")
    func testInvalidRequestBody() async throws {
        try await withApp { app in
            try await app.testing().test(.POST, "/v1/traces") { req async in
                req.headers.contentType = HTTPMediaType(type: "application", subType: "x-protobuf")
                req.body = ByteBuffer(data: "invalid data".data(using: .utf8)!)
            } afterResponse: { res async in
                #expect(res.status == .badRequest)
            }
            
            try await app.testing().test(.POST, "/v1/metrics") { req async in
                req.headers.contentType = HTTPMediaType(type: "application", subType: "x-protobuf")
                req.body = ByteBuffer(data: "invalid data".data(using: .utf8)!)
            } afterResponse: { res async in
                #expect(res.status == .badRequest)
            }
            
            try await app.testing().test(.POST, "/v1/logs") { req async in
                req.headers.contentType = HTTPMediaType(type: "application", subType: "x-protobuf")
                req.body = ByteBuffer(data: "invalid data".data(using: .utf8)!)
            } afterResponse: { res async in
                #expect(res.status == .badRequest)
            }
        }
    }
}
