import Foundation
import Testing
@testable import CalvinExplorator

struct ReconnectPolicyTests {
    @Test func delayDoublesUpToTheCap() {
        let policy = ReconnectPolicy()
        let delays = (1...7).map { policy.delay(afterFailures: $0) }
        #expect(delays == [1, 2, 4, 8, 16, 30, 30])
    }
}

struct LinkMonitorTests {
    let policy = ReconnectPolicy()
    let start = Date(timeIntervalSinceReferenceDate: 1000)

    @Test func handshakeTimesOut() {
        let link = LinkMonitor(startedAt: start)
        #expect(link.failureReason(at: start + policy.connectTimeout - 0.1, policy: policy) == nil)
        #expect(link.failureReason(at: start + policy.connectTimeout, policy: policy) == LinkMonitor.connectTimeoutReason)
    }

    @Test func openLinkFailsOnlyAfterGoingQuiet() {
        let link = LinkMonitor(startedAt: start)
        link.markOpened(at: start + 1)
        link.heard(at: start + 10)
        #expect(link.failureReason(at: start + 10 + policy.livenessTimeout - 0.1, policy: policy) == nil)
        #expect(link.failureReason(at: start + 10 + policy.livenessTimeout, policy: policy) == LinkMonitor.unresponsiveReason)
    }

    @Test func stableOnlyAfterMinimumDuration() {
        let link = LinkMonitor(startedAt: start)
        #expect(!link.wasStable(at: start + 100, policy: policy))

        link.markOpened(at: start)
        #expect(!link.wasStable(at: start + policy.minimumStableDuration - 0.1, policy: policy))
        #expect(link.wasStable(at: start + policy.minimumStableDuration, policy: policy))
    }
}

struct ConnectionStatusTests {
    let now = Date(timeIntervalSinceReferenceDate: 1000)

    @Test func reconnectingShowsCountdown() {
        let status = ConnectionStatus.reconnecting(attempt: 2, nextRetryAt: now.addingTimeInterval(3.2))
        #expect(status.label(now: now) == "Reconnecting (attempt 2, retry in 4s)")
    }

    @Test func reconnectingWithoutPendingRetryOmitsCountdown() {
        #expect(ConnectionStatus.reconnecting(attempt: 1, nextRetryAt: nil).label(now: now) == "Reconnecting (attempt 1)")
        #expect(ConnectionStatus.reconnecting(attempt: 1, nextRetryAt: now).label(now: now) == "Reconnecting (attempt 1)")
    }

    @Test func tryingStates() {
        #expect(ConnectionStatus.connecting.isTrying)
        #expect(ConnectionStatus.reconnecting(attempt: 1, nextRetryAt: nil).isTrying)
        #expect(!ConnectionStatus.connected.isTrying)
        #expect(!ConnectionStatus.offline.isTrying)
    }
}
