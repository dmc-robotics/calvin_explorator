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

struct CogitatorEndpointTests {
    @Test func validEndpointMakesWebSocketURL() {
        let endpoint = CogitatorEndpoint(host: "192.168.1.50", port: 5560)
        #expect(endpoint.url?.absoluteString == "ws://192.168.1.50:5560")
    }

    @Test(arguments: [
        CogitatorEndpoint(host: "", port: 5560),
        CogitatorEndpoint(host: "calvin jetson", port: 5560),
        CogitatorEndpoint(host: "localhost", port: 0),
        CogitatorEndpoint(host: "localhost", port: 70000),
    ])
    func invalidEndpointHasNoURL(endpoint: CogitatorEndpoint) {
        #expect(endpoint.url == nil)
    }

    @Test func savesAndLoads() throws {
        let defaults = try #require(UserDefaults(suiteName: "CogitatorEndpointTests"))
        defaults.removePersistentDomain(forName: "CogitatorEndpointTests")
        #expect(CogitatorEndpoint.load(from: defaults) == .default)

        CogitatorEndpoint(host: "calvin.local", port: 6000).save(to: defaults)
        #expect(CogitatorEndpoint.load(from: defaults) == CogitatorEndpoint(host: "calvin.local", port: 6000))
    }
}

struct MessageLogTests {
    @Test func dropsOldestBeyondLimit() {
        let log = MessageLog()
        for index in 0..<(MessageLog.maxEntries + 10) {
            log.record(.received, "\(index)")
        }
        #expect(log.entries.count == MessageLog.maxEntries)
        #expect(log.entries.first?.text == "10")
    }

    @Test func pausedLogIgnoresMessages() {
        let log = MessageLog()
        log.isPaused = true
        log.record(.sent, "ignored")
        #expect(log.entries.isEmpty)
    }
}
