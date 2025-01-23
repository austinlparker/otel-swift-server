import Vapor
import SwiftProtobuf

@available(macOS 13.0, *)
final class LogsService: @unchecked Sendable {
    private let app: Application
    private let logger = Logger(label: "logs-service")
    private let onData: (Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest) -> Void
    
    init(app: Application, onData: @escaping (Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest) -> Void) {
        self.app = app
        self.onData = onData
        
        app.post("v1", "logs") { [weak self] req async throws -> Response in
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
        let request = try Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest(serializedBytes: bytes)
        
        // Process the request
        for resourceLogs in request.resourceLogs {
            let resource = resourceLogs.resource
            logger.info("Processing resource with \(resource.attributes.count) attributes")
            
            for scopeLogs in resourceLogs.scopeLogs {
                let scope = scopeLogs.scope
                logger.info("Processing logs from: \(scope.name) v\(scope.version)")
                
                for record in scopeLogs.logRecords {
                    logger.info("Received log: \(record.severityText) - \(record.body.stringValue)")
                }
            }
        }
        
        // Send data to handler
        onData(request)
        
        // Create and encode the response
        let response = Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceResponse()
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