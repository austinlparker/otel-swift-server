import Vapor

extension HTTPMediaType {
    static let protobuf = HTTPMediaType(type: "application", subType: "x-protobuf")
}

// Add the media type directly to headers
extension HTTPHeaders {
    mutating func setProtobufContentType() {
        self.replaceOrAdd(name: .contentType, value: HTTPMediaType.protobuf.serialize())
    }
} 