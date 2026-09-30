import Foundation
import Observation

struct LogEntry: Identifiable {
    enum Direction {
        case sent
        case received
        /// A send that failed; the text includes the error
        case sendFailed
    }

    let id: Int
    let time: Date
    let direction: Direction
    let text: String
}

/// Every WebSocket message sent and received, newest last
@Observable
final class MessageLog {
    /// Oldest entries are dropped beyond this many
    static let maxEntries = 5000
    /// Longer messages are shortened to this many characters (real telemetry is ~150)
    static let maxTextLength = 4096

    private(set) var entries: [LogEntry] = []
    /// While paused, new messages aren't recorded
    var isPaused = false

    @ObservationIgnored private var nextID = 0

    func record(_ direction: LogEntry.Direction, _ text: String, at time: Date = .now) {
        guard !isPaused else { return }
        entries.append(LogEntry(id: nextID, time: time, direction: direction, text: Self.truncated(text)))
        nextID += 1
        if entries.count > Self.maxEntries {
            entries.removeFirst(entries.count - Self.maxEntries)
        }
    }

    func clear() {
        entries.removeAll()
    }

    static func truncated(_ text: String) -> String {
        guard text.count > maxTextLength else { return text }
        return "\(text.prefix(maxTextLength))… (\(text.count - maxTextLength) more characters)"
    }
}
