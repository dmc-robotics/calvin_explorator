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

    @Test func shortensHugeMessages() throws {
        let log = MessageLog()
        log.record(.received, String(repeating: "x", count: MessageLog.maxTextLength + 100))

        let text = try #require(log.entries.first?.text)
        #expect(text.hasPrefix(String(repeating: "x", count: MessageLog.maxTextLength)))
        #expect(text.hasSuffix("… (100 more characters)"))
    }
}
