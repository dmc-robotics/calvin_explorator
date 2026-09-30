import Foundation

/// Liveness bookkeeping for one connection attempt: when it started, opened, and was last heard from
final class LinkMonitor {
    static let connectTimeoutReason = "Timed out connecting"
    static let unresponsiveReason = "Cogitator stopped responding"

    let startedAt: Date
    private(set) var openedAt: Date?
    private(set) var lastHeardAt: Date

    init(startedAt: Date) {
        self.startedAt = startedAt
        lastHeardAt = startedAt
    }

    var isOpen: Bool { openedAt != nil }

    func markOpened(at time: Date) {
        if openedAt == nil { openedAt = time }
        heard(at: time)
    }

    /// Records a sign of life (a message or a pong)
    func heard(at time: Date) {
        lastHeardAt = max(lastHeardAt, time)
    }

    /// Why the connection should be closed at `now`, or nil if it's fine
    func failureReason(at now: Date, policy: ReconnectPolicy) -> String? {
        if openedAt == nil {
            return now.timeIntervalSince(startedAt) >= policy.connectTimeout ? Self.connectTimeoutReason : nil
        }
        return now.timeIntervalSince(lastHeardAt) >= policy.livenessTimeout ? Self.unresponsiveReason : nil
    }

    /// Whether the connection stayed open long enough to reset the failure count
    func wasStable(at now: Date, policy: ReconnectPolicy) -> Bool {
        guard let openedAt else { return false }
        return now.timeIntervalSince(openedAt) >= policy.minimumStableDuration
    }
}
