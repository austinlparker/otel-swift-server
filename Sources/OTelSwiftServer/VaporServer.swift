import Foundation
import Vapor
import NIOHTTP1

/// Vapor implementation of HTTPServer
public class VaporServer: OTelHTTPServer, @unchecked Sendable {
    private let app: Application
    private let handlers: [(path: String, handler: @Sendable (HTTPRequest) async throws -> HTTPResponse)]
    
    public var port: Int {
        app.http.server.configuration.port
    }
    
    public init(app: Application) {
        self.app = app
        self.handlers = []
        
        // Enable compression and pipelining
        app.http.server.configuration.supportPipelining = true
        app.http.server.configuration.requestDecompression = .enabled
        app.http.server.configuration.responseCompression = .enabled
    }
    
    public func start() async throws {
        try await app.server.start()
    }
    
    public func stop() async throws {
        try await app.server.shutdown()
    }
    
    public func post(path: String, handler: @escaping @Sendable (HTTPRequest) async throws -> HTTPResponse) {
        let pathComponents = path
            .split(separator: "/")
            .map(String.init)
            .map(PathComponent.init(stringLiteral:))
        
        app.post(pathComponents) { [weak self] req async throws -> Response in
            guard let self = self else {
                throw HTTPError.serverError("Server was deallocated")
            }
            
            let request = VaporRequest(request: req)
            let response = try await handler(request)
            return try await self.convertResponse(response)
        }
    }
    
    public func get(path: String, handler: @escaping @Sendable (HTTPRequest) async throws -> HTTPResponse) {
        let pathComponents = path
            .split(separator: "/")
            .map(String.init)
            .map(PathComponent.init(stringLiteral:))
        
        app.get(pathComponents) { [weak self] req async throws -> Response in
            guard let self = self else {
                throw HTTPError.serverError("Server was deallocated")
            }
            
            let request = VaporRequest(request: req)
            let response = try await handler(request)
            return try await self.convertResponse(response)
        }
    }
    
    private func convertResponse(_ response: HTTPResponse) async throws -> Response {
        let vaporResponse = Response()
        vaporResponse.body = .init(data: response.body)
        
        // Parse content type into type and subtype
        let parts = response.contentType.split(separator: "/")
        guard parts.count == 2 else {
            throw HTTPError.serverError("Invalid content type format")
        }
        
        vaporResponse.headers.contentType = .init(type: String(parts[0]), subType: String(parts[1]))
        
        // Set content encoding if present
        if let contentEncoding = response.contentEncoding {
            vaporResponse.headers.add(name: .contentEncoding, value: contentEncoding)
            if contentEncoding == "gzip" {
                vaporResponse.headers.add(name: .vary, value: "Accept-Encoding")
            }
        }
        
        return vaporResponse
    }
}

/// Vapor implementation of HTTPRequest
struct VaporRequest: HTTPRequest {
    let body: Data
    let contentType: String
    let acceptType: String
    let contentEncoding: String?
    let acceptEncoding: [String]?
    
    init(request: Request) {
        self.body = Data(buffer: request.body.data ?? ByteBuffer())
        self.contentType = request.headers.contentType?.serialize() ?? "application/octet-stream"
        self.acceptType = request.headers.accept.first?.mediaType.serialize() ?? "application/x-protobuf"
        self.contentEncoding = request.headers[.contentEncoding].first
        self.acceptEncoding = request.headers[.acceptEncoding].first?.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
    }
}

/// Vapor implementation of HTTPResponse
struct VaporResponse: HTTPResponse {
    let body: Data
    let contentType: String
    let contentEncoding: String?
    
    static func ok(body: Data, contentType: String) -> VaporResponse {
        VaporResponse(body: body, contentType: contentType, contentEncoding: nil)
    }
    
    static func error(status: Int, message: String) -> VaporResponse {
        VaporResponse(body: Data(message.utf8), contentType: "text/plain", contentEncoding: nil)
    }
} 