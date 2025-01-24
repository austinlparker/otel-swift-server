import Foundation

/// Protocol for HTTP responses
public protocol HTTPResponse {
    /// The response body data
    var body: Data { get }
    
    /// The content type of the response
    var contentType: String { get }
    
    /// The content encoding of the response (e.g. "gzip")
    var contentEncoding: String? { get }
}

/// Protocol for HTTP requests
public protocol HTTPRequest {
    /// The request body data
    var body: Data { get }
    
    /// The content type of the request
    var contentType: String { get }
    
    /// The Accept header value
    var acceptType: String { get }
    
    /// The content encoding of the request (e.g. "gzip")
    var contentEncoding: String? { get }
    
    /// The accepted encodings for the response (e.g. ["gzip"])
    var acceptEncoding: [String]? { get }
}

/// Protocol for HTTP server implementations
public protocol OTelHTTPServer {
    /// The port the server is running on
    var port: Int { get }
    
    /// Start the server
    func start() async throws
    
    /// Stop the server
    func stop() async throws
    
    /// Register a POST endpoint handler
    func post(path: String, handler: @escaping @Sendable (HTTPRequest) async throws -> HTTPResponse)
    
    /// Register a GET endpoint handler
    func get(path: String, handler: @escaping @Sendable (HTTPRequest) async throws -> HTTPResponse)
}

/// Errors that can occur during HTTP operations
public enum HTTPError: Error {
    case invalidContentType
    case invalidBody
    case serverError(String)
    case payloadTooLarge(maxSize: Int)
    case compressionError(String)
} 