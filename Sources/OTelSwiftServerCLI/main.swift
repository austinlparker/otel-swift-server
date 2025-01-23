import OTelSwiftServer

@main
struct OTelSwiftServerCLI {
    static func main() async throws {
        let server = try OTelSwiftServer(port: 8081)
        
        // Start processing telemetry data
        let processTask = Task {
            // Process traces
            for await traceData in server.traces {
                print("Received trace data with \(traceData.resourceSpans.count) resource spans")
            }
        }
        
        let metricsTask = Task {
            // Process metrics
            for await metricsData in server.metrics {
                print("Received metrics data with \(metricsData.resourceMetrics.count) resource metrics")
            }
        }
        
        let logsTask = Task {
            // Process logs
            for await logsData in server.logs {
                print("Received logs data with \(logsData.resourceLogs.count) resource logs")
            }
        }
        
        // Start the server
        try await server.start()
        
        print("OTel server started!")
        print("Traces endpoint: \(server.tracesURL)")
        print("Metrics endpoint: \(server.metricsURL)")
        print("Logs endpoint: \(server.logsURL)")
        
        // Keep the server running until interrupted
        while true {
            try await Task.sleep(for: .seconds(1))
        }
        
        // Clean up
        try await server.stop()
        processTask.cancel()
        metricsTask.cancel()
        logsTask.cancel()
    }
} 