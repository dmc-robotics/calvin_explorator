import Foundation
@testable import CalvinExplorator

/// A socket the test drives by hand
final class FakeSocket: GatewaySocket {
    let events: AsyncThrowingStream<WebSocketEvent, Error>
    private let continuation: AsyncThrowingStream<WebSocketEvent, Error>.Continuation

    /// Set when the socket is closed, by `close()` or by the connection ending iteration
    private(set) var isClosed = false
    private(set) var sentTexts: [String] = []
    /// When false, pings never get a pong (a dead link)
    var answersPings = true

    init() {
        (events, continuation) = AsyncThrowingStream.makeStream(of: WebSocketEvent.self)
        continuation.onTermination = { [weak self] _ in
            Task { @MainActor in self?.isClosed = true }
        }
    }

    func open() { continuation.yield(.opened) }
    func deliver(_ text: String) { continuation.yield(.message(text)) }
    func fail() { continuation.finish(throwing: URLError(.networkConnectionLost)) }

    func send(_ text: String) async throws { sentTexts.append(text) }

    func sendPing(onPong: @escaping @Sendable (Error?) -> Void) {
        if answersPings { onPong(nil) }
    }

    func close() {
        isClosed = true
        continuation.finish(throwing: URLError(.cancelled))
    }
}

/// Polls `condition` until it's true or `timeout` passes. Returns whether it became true
func waitUntil(timeout: Duration = .seconds(3), _ condition: () -> Bool) async -> Bool {
    let deadline = ContinuousClock.now + timeout
    while !condition() {
        if ContinuousClock.now >= deadline { return false }
        try? await Task.sleep(for: .milliseconds(5))
    }
    return true
}

/// A throwaway UserDefaults suite, removed when the test is done with it
final class TestDefaults {
    let name = "CalvinExploratorTests-\(UUID().uuidString)"
    let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: name)!
    }

    deinit {
        UserDefaults.standard.removePersistentDomain(forName: name)
    }
}
