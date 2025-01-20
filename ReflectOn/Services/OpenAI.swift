import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

enum RealtimeAPIError: Error {
    case invalidMessage
}

public final class RealtimeAPI: NSObject, Sendable {
    @MainActor public var onDisconnect: (@Sendable () -> Void)? {
        get { connector.onDisconnect }
        set { connector.onDisconnect(newValue) }
    }

    public var events: AsyncThrowingStream<ServerEvent, Error> {
        connector.events
    }

    let connector: any Connector

    /// Connect to the OpenAI Realtime API using the given connector instance.
    public init(connector: any Connector) {
        self.connector = connector
        super.init()
    }

    public func send(event: ClientEvent) async throws {
        try await connector.send(event: event)
    }
}

/// Helper methods for connecting to the OpenAI Realtime API.
extension RealtimeAPI {

    /// Connect to the OpenAI WebRTC Realtime API with the given request.
    public static func webRTC(connectingTo request: URLRequest) async throws -> RealtimeAPI {
        let connector = try await WebRTCConnector(connectingTo: request)
        return RealtimeAPI(connector: connector)
    }

    /// Connect to the OpenAI WebRTC Realtime API with the given authentication token and model.
    public static func webRTC(authToken: String, model: String = "gpt-4o-mini-realtime-preview-2024-12-17") async throws -> RealtimeAPI {
        var request = URLRequest(url: URL(string: "wss://api.openai.com/v1/realtime")!.appending(queryItems: [
            URLQueryItem(name: "model", value: model),
        ]))
        request.addValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")
        request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        return try await webRTC(connectingTo: request)
    }
}
