import Foundation
import Observation

struct LogEntry: Identifiable {
    enum Direction {
        case sent
        case received
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

    private(set) var entries: [LogEntry] = []
    /// While paused, new messages aren't recorded
    var isPaused = false

    @ObservationIgnored private var nextID = 0

    func record(_ direction: LogEntry.Direction, _ text: String, at time: Date = .now) {
        guard !isPaused else { return }
        entries.append(LogEntry(id: nextID, time: time, direction: direction, text: text))
        nextID += 1
        if entries.count > Self.maxEntries {
            entries.removeFirst(entries.count - Self.maxEntries)
        }
    }

    func clear() {
        entries.removeAll()
    }
}
