import Foundation
import SwiftProtobuf
import Vapor

/// A service that handles OpenTelemetry logs data processing and response generation.
public class LogsService {
    private let logger: Logger
    
    /// Creates a new logs service with the specified logger.
    /// - Parameter logger: The logger to use for recording processing information.
    public init(logger: Logger) {
        self.logger = logger
    }
    
    /// Processes an OpenTelemetry logs export request.
    /// - Parameter request: The logs export request containing resource logs data.
    /// - Throws: `OTelServerError.invalidRequest` if no resource logs are provided.
    public func process(_ request: Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest) throws {
        guard !request.resourceLogs.isEmpty else {
            throw OTelServerError.invalidRequest(reason: "No resource logs provided")
        }
        
        // Log resource attributes
        for resourceLogs in request.resourceLogs {
            logger.info("Processing resource", metadata: [
                "attributes": resourceLogs.resource.attributes.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            ])
            
            // Log scope information
            for scopeLogs in resourceLogs.scopeLogs {
                logger.info("Processing logs", metadata: [
                    "scope": "\(scopeLogs.scope.name) v\(scopeLogs.scope.version)",
                    "logCount": "\(scopeLogs.logRecords.count)"
                ])
            }
        }
    }
    
    /// Builds an HTTP response for the logs export operation.
    /// - Parameter acceptType: The content type requested by the client (e.g., "application/json" or "application/x-protobuf").
    /// - Returns: An HTTP response containing the serialized logs export response.
    /// - Throws: An error if serialization fails.
    public func buildResponse(acceptType: String) throws -> HTTPResponse {
        let response = Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceResponse()
        
        switch acceptType.lowercased() {
        case "application/json":
            let jsonData = try response.jsonUTF8Data()
            return VaporResponse(body: jsonData, contentType: "application/json", contentEncoding: nil)
        case "application/x-protobuf", _:
            let bytes: [UInt8] = try response.serializedBytes()
            return VaporResponse(body: Data(bytes), contentType: "application/x-protobuf", contentEncoding: nil)
        }
    }
} 