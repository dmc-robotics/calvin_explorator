import Foundation

/// What `CogitatorConnection` needs from a WebSocket. `WebSocket` is the real one; tests use a fake
protocol GatewaySocket: AnyObject, Sendable {
    /// Yields `.opened`, then each message, and finishes (throwing the failure) when the socket closes.
    /// Ending iteration early closes the socket
    var events: AsyncThrowingStream<WebSocketEvent, Error> { get }

    func send(_ text: String) async throws

    /// `onPong` is called with nil when the pong arrives, or with the error if the ping fails
    func sendPing(onPong: @escaping @Sendable (Error?) -> Void)

    func close()
}
