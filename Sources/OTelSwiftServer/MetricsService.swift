import Foundation
import SwiftProtobuf
import Vapor

/// A service that handles OpenTelemetry metrics data processing and response generation.
public class MetricsService {
    private let logger: Logger
    
    /// Creates a new metrics service with the specified logger.
    /// - Parameter logger: The logger to use for recording processing information.
    public init(logger: Logger) {
        self.logger = logger
    }
    
    /// Processes an OpenTelemetry metrics export request.
    /// - Parameter request: The metrics export request containing resource metrics data.
    /// - Throws: `OTelServerError.invalidRequest` if no resource metrics are provided.
    public func process(_ request: Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest) throws {
        guard !request.resourceMetrics.isEmpty else {
            throw OTelServerError.invalidRequest(reason: "No resource metrics provided")
        }
        
        // Log resource attributes
        for resourceMetrics in request.resourceMetrics {
            logger.info("Processing resource", metadata: [
                "attributes": resourceMetrics.resource.attributes.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            ])
            
            // Log scope information
            for scopeMetrics in resourceMetrics.scopeMetrics {
                logger.info("Processing metrics", metadata: [
                    "scope": "\(scopeMetrics.scope.name) v\(scopeMetrics.scope.version)",
                    "metricCount": "\(scopeMetrics.metrics.count)"
                ])
            }
        }
    }
    
    /// Builds an HTTP response for the metrics export operation.
    /// - Parameter acceptType: The content type requested by the client (e.g., "application/json" or "application/x-protobuf").
    /// - Returns: An HTTP response containing the serialized metrics export response.
    /// - Throws: An error if serialization fails.
    public func buildResponse(acceptType: String) throws -> HTTPResponse {
        let response = Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceResponse()
        
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