import Foundation
import Observation

/// Keeps a WebSocket open to cogitator's gateway, reconnecting with exponential backoff.
///
/// Received messages are passed to `onMessage` as raw text; parsing is left to the caller.
/// A watchdog pings the open connection so a dead link (robot off WiFi, Jetson reset) is noticed
/// even when no telemetry is flowing.
@Observable
final class CogitatorConnection {
    enum SendError: LocalizedError {
        case notConnected

        var errorDescription: String? { "Not connected to cogitator" }
    }

    private(set) var status: ConnectionStatus = .disconnected
    /// Why the most recent attempt failed, if it did
    private(set) var lastError: String?

    @ObservationIgnored var onMessage: ((String) -> Void)?

    @ObservationIgnored private let policy: ReconnectPolicy
    @ObservationIgnored private let makeSocket: (URL) -> any GatewaySocket
    @ObservationIgnored private var url: URL?
    @ObservationIgnored private var runTask: Task<Void, Never>?
    @ObservationIgnored private var socket: (any GatewaySocket)?

    init(
        policy: ReconnectPolicy = ReconnectPolicy(),
        makeSocket: @escaping (URL) -> any GatewaySocket = { WebSocket(url: $0) }
    ) {
        self.policy = policy
        self.makeSocket = makeSocket
    }

    /// Drops any current connection and connects to `url`, retrying on failure
    func connect(to url: URL) {
        stop()
        self.url = url
        status = .connecting
        runTask = Task { await run(url) }
    }

    /// Starts over with a fresh set of attempts (e.g. after going offline)
    func retry() {
        guard let url else { return }
        connect(to: url)
    }

    func disconnect() {
        stop()
        status = .disconnected
    }

    /// Sends `text` on the open connection
    func send(_ text: String) async throws {
        guard status == .connected, let socket else { throw SendError.notConnected }
        try await socket.send(text)
    }

    /// Cancels the connection loop and forgets its socket right away, so nothing is sent on it
    /// while the cancelled loop winds down (which closes the socket)
    private func stop() {
        runTask?.cancel()
        runTask = nil
        socket = nil
    }

    // MARK: - Connection loop

    private func run(_ url: URL) async {
        var failures = 0
        while !Task.isCancelled {
            status = failures == 0 ? .connecting : .reconnecting(attempt: failures, nextRetryAt: nil)

            let wasStable = await runConnection(to: url)
            guard !Task.isCancelled else { return }

            if wasStable { failures = 0 }
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

    /// Runs one connection until it closes. Returns whether it stayed open long enough to count as stable
    private func runConnection(to url: URL) async -> Bool {
        let socket = makeSocket(url)
        self.socket = socket
        defer {
            // A newer connect() may already have replaced it
            if self.socket === socket { self.socket = nil }
        }

        let link = LinkMonitor(startedAt: .now)
        let watchdog = startWatchdog(for: socket, link: link)

        var failure: Error?
        do {
            for try await event in socket.events {
                guard !Task.isCancelled else { break }
                // A message can arrive before the open callback; either one means we're connected
                if !link.isOpen {
                    link.markOpened(at: .now)
                    status = .connected
                    lastError = nil
                }
                link.heard(at: .now)
                if case .message(let text) = event {
                    onMessage?(text)
                }
            }
        } catch {
            failure = error
        }

        watchdog.cancel()
        let watchdogReason = await watchdog.value
        if !Task.isCancelled, let reason = watchdogReason ?? failure?.localizedDescription {
            lastError = reason
        }
        return link.wasStable(at: .now, policy: policy)
    }

    /// Every `watchdogInterval`: closes the socket if the handshake is taking too long or an open
    /// connection has gone quiet, and otherwise pings it. Its value is why it closed the socket, if it did
    private func startWatchdog(for socket: any GatewaySocket, link: LinkMonitor) -> Task<String?, Never> {
        let policy = policy
        return Task {
            while true {
                do {
                    try await Task.sleep(for: .seconds(policy.watchdogInterval))
                } catch {
                    return nil
                }
                if let reason = link.failureReason(at: .now, policy: policy) {
                    socket.close()
                    return reason
                }
                if link.isOpen {
                    socket.sendPing { error in
                        guard error == nil else { return }
                        Task { @MainActor in link.heard(at: .now) }
                    }
                }
            }
        }
    }
}
