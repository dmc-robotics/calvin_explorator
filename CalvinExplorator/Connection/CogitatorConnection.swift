import Foundation
import Observation

/// Keeps a WebSocket open to cogitator's gateway, reconnecting with exponential backoff.
///
/// Received messages are passed to `onMessage` as raw text; parsing is left to the caller.
@Observable
final class CogitatorConnection {
    private(set) var status: ConnectionStatus = .disconnected
    /// Why the most recent attempt failed, if it did
    private(set) var lastError: String?

    @ObservationIgnored var onMessage: ((String) -> Void)?

    @ObservationIgnored private let policy: ReconnectPolicy
    @ObservationIgnored private var url: URL?
    @ObservationIgnored private var runTask: Task<Void, Never>?
    @ObservationIgnored private var socket: WebSocket?

    init(policy: ReconnectPolicy = ReconnectPolicy()) {
        self.policy = policy
    }

    /// Drops any current connection and connects to `url`, retrying on failure
    func connect(to url: URL) {
        runTask?.cancel()
        self.url = url
        runTask = Task { await run(url) }
    }

    /// Starts over with a fresh set of attempts (e.g. after going offline)
    func retry() {
        guard let url else { return }
        connect(to: url)
    }

    func disconnect() {
        runTask?.cancel()
        runTask = nil
        status = .disconnected
    }

    /// Sends `text` if connected. Returns false (and sends nothing) otherwise
    @discardableResult
    func send(_ text: String) -> Bool {
        guard status == .connected, let socket else { return false }
        Task {
            do {
                try await socket.send(text)
            } catch {
                lastError = error.localizedDescription
            }
        }
        return true
    }

    // MARK: - Connection loop

    private func run(_ url: URL) async {
        var failures = 0
        while !Task.isCancelled {
            status = failures == 0 ? .connecting : .reconnecting(attempt: failures, nextRetryAt: nil)

            let didOpen = await runConnection(to: url)
            guard !Task.isCancelled else { return }

            // A connection that opened and then dropped starts a fresh round of attempts
            if didOpen { failures = 0 }
            failures += 1
            guard failures < policy.maxAttempts else {
                status = .offline
                return
            }

            let delay = policy.delay(afterFailures: failures)
            status = .reconnecting(attempt: failures, nextRetryAt: .now + delay)
            try? await Task.sleep(for: .seconds(delay))
        }
    }

    /// Runs one connection until it closes. Returns whether it ever opened
    private func runConnection(to url: URL) async -> Bool {
        let socket = WebSocket(url: url)
        self.socket = socket
        defer { self.socket = nil }

        // Closes the socket if the handshake takes too long. Its value says whether that happened
        let connectTimeout = policy.connectTimeout
        let timeout = Task { () -> Bool in
            do {
                try await Task.sleep(for: .seconds(connectTimeout))
            } catch {
                return false
            }
            socket.close()
            return true
        }
        defer { timeout.cancel() }

        var didOpen = false
        do {
            for try await event in socket.events {
                guard !Task.isCancelled else { break }
                // A message can arrive before the open callback; either one means we're connected
                if !didOpen {
                    didOpen = true
                    timeout.cancel()
                    status = .connected
                    lastError = nil
                }
                if case .message(let text) = event {
                    onMessage?(text)
                }
            }
        } catch {
            timeout.cancel()
            let timedOut = await timeout.value
            if !Task.isCancelled {
                lastError = timedOut ? "Timed out connecting" : error.localizedDescription
            }
        }
        return didOpen
    }
}
