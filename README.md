# OTelSwiftServer

A Swift library for receiving OpenTelemetry data over HTTP. This server implements the OTLP/HTTP protocol for traces, metrics, and logs.

## Features

- Receive traces, metrics, and logs via HTTP endpoints
- Async/await API with AsyncStream for processing telemetry data
- Protobuf-encoded data handling
- Easy integration with existing Swift applications
- Built on top of Vapor for reliable HTTP server functionality

## Requirements

- macOS 13.0 or later
- Swift 6.0 or later

## Installation

Add OTelSwiftServer as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "path/to/otlp-swift-server", from: "1.0.0")
]
```

And add it to your target's dependencies:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["OTelSwiftServer"])
]
```

## Usage

### Basic Server Setup

```swift
import OTelSwiftServer

// Initialize server with default port (8080)
let server = try OTelSwiftServer()

// Or specify a custom port
let server = try OTelSwiftServer(port: 8081)

// Start the server
try await server.start()

// Get endpoint URLs
print(server.tracesURL)   // http://localhost:8081/v1/traces
print(server.metricsURL)  // http://localhost:8081/v1/metrics
print(server.logsURL)     // http://localhost:8081/v1/logs
```

### Processing Telemetry Data

```swift
// Process traces
Task {
    for await traceData in server.traces {
        // Access resource spans
        for resourceSpan in traceData.resourceSpans {
            // Access resource attributes
            let resource = resourceSpan.resource
            print("Resource attributes: \(resource.attributes)")
            
            // Process spans
            for scopeSpan in resourceSpan.scopeSpans {
                let scope = scopeSpan.scope
                print("Processing spans from: \(scope.name) v\(scope.version)")
                
                for span in scopeSpan.spans {
                    print("Span: \(span.name)")
                }
            }
        }
    }
}

// Process metrics
Task {
    for await metricsData in server.metrics {
        for resourceMetrics in metricsData.resourceMetrics {
            for scopeMetrics in resourceMetrics.scopeMetrics {
                for metric in scopeMetrics.metrics {
                    print("Metric: \(metric.name)")
                }
            }
        }
    }
}

// Process logs
Task {
    for await logsData in server.logs {
        for resourceLogs in logsData.resourceLogs {
            for scopeLogs in resourceLogs.scopeLogs {
                for record in scopeLogs.logRecords {
                    print("Log: \(record.severityText) - \(record.body.stringValue)")
                }
            }
        }
    }
}
```

### Clean Shutdown

```swift
// Stop the server and clean up resources
try await server.stop()
```

### Testing

The library provides a convenience initializer for testing:

```swift
let testServer = try await OTelSwiftServer.testing()
```

## Protocol Support

The server implements the OpenTelemetry Protocol (OTLP) over HTTP/protobuf:

- Traces: `/v1/traces` endpoint accepting `ExportTraceServiceRequest`
- Metrics: `/v1/metrics` endpoint accepting `ExportMetricsServiceRequest`
- Logs: `/v1/logs` endpoint accepting `ExportLogsServiceRequest`

All endpoints expect protobuf-encoded requests with `Content-Type: application/x-protobuf`.

## Example Client Configuration

When configuring OpenTelemetry clients to send data to this server, use the following settings:

```
endpoint: http://localhost:8081
protocol: http/protobuf
```