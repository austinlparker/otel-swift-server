import Vapor
import SwiftProtobuf

@available(macOS 13.0, *)
final class TraceService: @unchecked Sendable {
    private let app: Application
    private let logger = Logger(label: "trace-service")
    private let onData: (Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest) -> Void
    
    init(app: Application, onData: @escaping (Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest) -> Void) {
        self.app = app
        self.onData = onData
        
        app.post("v1", "traces") { [weak self] req async throws -> Response in
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
        let request = try Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest(serializedBytes: bytes)
        
        // Process the request
        for resourceSpan in request.resourceSpans {
            let resource = resourceSpan.resource
            logger.info("Processing resource with \(resource.attributes.count) attributes")
            
            for scopeSpan in resourceSpan.scopeSpans {
                let scope = scopeSpan.scope
                logger.info("Processing spans from: \(scope.name) v\(scope.version)")
                
                for span in scopeSpan.spans {
                    logger.info("Received span: \(span.name)")
                }
            }
        }
        
        // Send data to handler
        onData(request)
        
        // Create and encode the response
        let response = Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceResponse()
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