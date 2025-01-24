import Foundation
import SwiftProtobuf

/// Protocol for decoding OTLP data
public protocol OTLPDecoder {
    /// Decode trace data from raw bytes
    func decodeTraces(_ data: Data, contentType: String) throws -> Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest
    
    /// Decode metrics data from raw bytes
    func decodeMetrics(_ data: Data, contentType: String) throws -> Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest
    
    /// Decode logs data from raw bytes
    func decodeLogs(_ data: Data, contentType: String) throws -> Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest
}

/// Default implementation of OTLPDecoder that handles both protobuf and JSON formats
public struct DefaultOTLPDecoder: OTLPDecoder {
    private let jsonDecoder = JSONDecoder()
    
    public init() {}
    
    public func decodeTraces(_ data: Data, contentType: String) throws -> Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest {
        guard !data.isEmpty else {
            throw OTelServerError.invalidRequest(reason: "Empty request body")
        }
        
        switch contentType.lowercased() {
        case "application/x-protobuf":
            do {
                return try Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest(serializedBytes: [UInt8](data))
            } catch {
                throw OTelServerError.decodingFailed(format: contentType, reason: error.localizedDescription)
            }
        case "application/json":
            do {
                return try Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest(jsonUTF8Data: data)
            } catch {
                throw OTelServerError.decodingFailed(format: contentType, reason: error.localizedDescription)
            }
        default:
            throw OTelServerError.decodingFailed(format: contentType, reason: "Unsupported content type")
        }
    }
    
    public func decodeMetrics(_ data: Data, contentType: String) throws -> Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest {
        guard !data.isEmpty else {
            throw OTelServerError.invalidRequest(reason: "Empty request body")
        }
        
        switch contentType.lowercased() {
        case "application/x-protobuf":
            do {
                return try Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest(serializedBytes: [UInt8](data))
            } catch {
                throw OTelServerError.decodingFailed(format: contentType, reason: error.localizedDescription)
            }
        case "application/json":
            do {
                return try Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest(jsonUTF8Data: data)
            } catch {
                throw OTelServerError.decodingFailed(format: contentType, reason: error.localizedDescription)
            }
        default:
            throw OTelServerError.decodingFailed(format: contentType, reason: "Unsupported content type")
        }
    }
    
    public func decodeLogs(_ data: Data, contentType: String) throws -> Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest {
        guard !data.isEmpty else {
            throw OTelServerError.invalidRequest(reason: "Empty request body")
        }
        
        switch contentType.lowercased() {
        case "application/x-protobuf":
            do {
                return try Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest(serializedBytes: [UInt8](data))
            } catch {
                throw OTelServerError.decodingFailed(format: contentType, reason: error.localizedDescription)
            }
        case "application/json":
            do {
                return try Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest(jsonUTF8Data: data)
            } catch {
                throw OTelServerError.decodingFailed(format: contentType, reason: error.localizedDescription)
            }
        default:
            throw OTelServerError.decodingFailed(format: contentType, reason: "Unsupported content type")
        }
    }
}

/// Test decoder that returns predefined responses
public class TestOTLPDecoder: OTLPDecoder {
    public var traceResponse: Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest?
    public var metricsResponse: Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest?
    public var logsResponse: Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest?
    
    public init() {}
    
    public func decodeTraces(_ data: Data, contentType: String) throws -> Opentelemetry_Proto_Collector_Trace_V1_ExportTraceServiceRequest {
        if let response = traceResponse {
            return response
        }
        throw HTTPError.serverError("No test response configured")
    }
    
    public func decodeMetrics(_ data: Data, contentType: String) throws -> Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest {
        if let response = metricsResponse {
            return response
        }
        throw HTTPError.serverError("No test response configured")
    }
    
    public func decodeLogs(_ data: Data, contentType: String) throws -> Opentelemetry_Proto_Collector_Logs_V1_ExportLogsServiceRequest {
        if let response = logsResponse {
            return response
        }
        throw HTTPError.serverError("No test response configured")
    }
} 