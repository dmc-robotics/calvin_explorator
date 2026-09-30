import Foundation

/// What a `WebSocket` reports while it's open
nonisolated enum WebSocketEvent: Sendable {
    /// Handshake finished; the socket can send and receive
    case opened
    /// One text frame (binary frames are decoded as UTF-8)
    case message(String)
}

/// One WebSocket connection attempt, backed by `URLSessionWebSocketTask`
nonisolated final class WebSocket: GatewaySocket {
    let events: AsyncThrowingStream<WebSocketEvent, Error>
    private let task: URLSessionWebSocketTask

    init(url: URL) {
        let (events, continuation) = AsyncThrowingStream.makeStream(of: WebSocketEvent.self)
        let session = URLSession(
            configuration: .ephemeral,
            delegate: OpenDelegate(continuation: continuation),
            delegateQueue: nil
        )
        let task = session.webSocketTask(with: url)
        self.events = events
        self.task = task

        // Set before anything can finish the stream, so cleanup always runs.
        // Cancelling the task also makes the receive loop below throw and exit
        continuation.onTermination = { _ in
            task.cancel(with: .goingAway, reason: nil)
            // Releases the delegate, which the session holds strongly
            session.invalidateAndCancel()
        }

        Task {
            do {
                while true {
                    switch try await task.receive() {
                    case .string(let text):
                        continuation.yield(.message(text))
                    case .data(let data):
                        continuation.yield(.message(String(decoding: data, as: UTF8.self)))
                    @unknown default:
                        break
                    }
                }
            } catch {
                continuation.finish(throwing: error)
            }
        }

        task.resume()
    }

    func send(_ text: String) async throws {
        try await task.send(.string(text))
    }

    func sendPing(onPong: @escaping @Sendable (Error?) -> Void) {
        task.sendPing(pongReceiveHandler: onPong)
    }

    func close() {
        task.cancel(with: .normalClosure, reason: nil)
    }
}

/// Forwards the handshake-complete callback into the event stream
private nonisolated final class OpenDelegate: NSObject, URLSessionWebSocketDelegate, Sendable {
    private let continuation: AsyncThrowingStream<WebSocketEvent, Error>.Continuation

    init(continuation: AsyncThrowingStream<WebSocketEvent, Error>.Continuation) {
        self.continuation = continuation
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        continuation.yield(.opened)
    }
}
