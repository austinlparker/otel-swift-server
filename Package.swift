// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OTelSwiftServer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "OTelSwiftServer",
            targets: ["OTelSwiftServer"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.28.2"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.112.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "5.1.2"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.0"),
        .package(url: "https://github.com/1024jp/GzipSwift", from: "6.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "OTelSwiftServer",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "JWT", package: "jwt"),
                .product(name: "Algorithms", package: "swift-algorithms")                

            ]),
        .testTarget(
            name: "OTelSwiftServerTests",
            dependencies: [
                "OTelSwiftServer",
                .product(name: "VaporTesting", package: "vapor"),
                .product(name: "Gzip", package: "GzipSwift")
            ]
        ),
    ]
)
