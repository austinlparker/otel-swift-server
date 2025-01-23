import Vapor
import SwiftProtobuf

@available(macOS 13.0, *)
final class MetricsService: @unchecked Sendable {
    private let app: Application
    private let logger = Logger(label: "metrics-service")
    private let onData: (Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest) -> Void
    
    init(app: Application, onData: @escaping (Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest) -> Void) {
        self.app = app
        self.onData = onData
        
        app.post("v1", "metrics") { [weak self] req async throws -> Response in
            guard let self = self else {
                throw Abort(.internalServerError)
            }
            return try await self.export(req)
        }
    }
    
    private func export(_ req: Request) async throws -> Response {
        guard var bodyData = try await req.body.collect(max: 1024 * 1024).get() else {
            throw Abort(.badRequest)
        }
        
        // Convert ByteBuffer to [UInt8]
        let bytes = bodyData.readBytes(length: bodyData.readableBytes) ?? []
        
        // Decode the protobuf request
        let request = try Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest(serializedBytes: bytes)
        
        // Process the request
        for resourceMetrics in request.resourceMetrics {
            let resource = resourceMetrics.resource
            logger.info("Processing resource with \(resource.attributes.count) attributes")
            
            for scopeMetrics in resourceMetrics.scopeMetrics {
                let scope = scopeMetrics.scope
                logger.info("Processing metrics from: \(scope.name) v\(scope.version)")
                
                for metric in scopeMetrics.metrics {
                    logger.info("Received metric: \(metric.name)")
                }
            }
        }
        
        // Send data to handler
        onData(request)
        
        // Create and encode the response
        let response = Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceResponse()
        let responseBytes: [UInt8] = try response.serializedBytes()
        
        var headers = HTTPHeaders()
        headers.setProtobufContentType()
        
        return Response(
            status: .ok,
            headers: headers,
            body: .init(data: Data(responseBytes))
        )
    }
} 