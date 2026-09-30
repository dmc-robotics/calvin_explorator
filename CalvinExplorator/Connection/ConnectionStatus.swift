import Foundation

/// State of the WebSocket link to cogitator's gateway
enum ConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
    /// Trying again after `attempt` consecutive failures. `nextRetryAt` is set while waiting to retry
    case reconnecting(attempt: Int, nextRetryAt: Date?)
    /// Gave up after too many failures; needs a manual retry
    case offline

    /// True while a connection attempt is in progress or scheduled
    var isTrying: Bool {
        switch self {
        case .connecting, .reconnecting: true
        default: false
        }
    }

    /// Short description for the toolbar, including the retry countdown relative to `now`
    func label(now: Date = .now) -> String {
        switch self {
        case .disconnected:
            "Disconnected"
        case .connecting:
            "Connecting…"
        case .connected:
            "Connected"
        case .reconnecting(let attempt, let nextRetryAt):
            if let nextRetryAt, case let seconds = Int(nextRetryAt.timeIntervalSince(now).rounded(.up)), seconds > 0 {
                "Reconnecting (attempt \(attempt), retry in \(seconds)s)"
            } else {
                "Reconnecting (attempt \(attempt))"
            }
        case .offline:
            "Offline"
        }
    }
}
