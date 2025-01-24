import Foundation
import SwiftProtobuf
import Vapor

public class TraceService {
    private let logger: Logger
    
    public init(logger: Logger) {
        self.logger = logger
    }
    
    public func process(_ request: Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest) throws {
        guard !request.resourceSpans.isEmpty else {
            throw OTelServerError.invalidRequest(reason: "No resource spans provided")
        }
        
        // Log resource attributes
        for resourceSpan in request.resourceSpans {
            logger.info("Processing resource", metadata: [
                "attributes": resourceSpan.resource.attributes.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            ])
            
            // Log scope information
            for scopeSpan in resourceSpan.scopeSpans {
                logger.info("Processing spans", metadata: [
                    "scope": "\(scopeSpan.scope.name) v\(scopeSpan.scope.version)",
                    "spanCount": "\(scopeSpan.spans.count)"
                ])
            }
        }
    }
    
    public func buildResponse(acceptType: String) throws -> HTTPResponse {
        let response = Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceResponse()
        
        switch acceptType.lowercased() {
        case "application/json":
            let jsonData = try response.jsonUTF8Data()
            return VaporResponse(body: jsonData, contentType: "application/json", contentEncoding: nil)
        case "application/x-protobuf", _:
            let bytes = try response.serializedData()
            return VaporResponse(body: bytes, contentType: "application/x-protobuf", contentEncoding: nil)
        }
    }
} 