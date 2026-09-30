import Foundation
import Testing
@testable import CalvinExplorator

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
