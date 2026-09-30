import Foundation

enum I2CBusStatus: Equatable {
    case noData
    case healthy
    case warning
    case error

    var label: String {
        switch self {
        case .noData: "No Data"
        case .healthy: "Healthy"
        case .warning: "Warning"
        case .error: "Error"
        }
    }
}

struct I2CErrorSample {
    let time: Date
    let nacks: Int
    let timeouts: Int
    let resets: Int
}

/// Aggregate I2C bus health reported by instinctus
struct I2CHealth {
    /// More errors than this in one report means the bus is failing
    static let errorThreshold = 5

    private(set) var nacks = 0
    private(set) var timeouts = 0
    private(set) var resets = 0
    private(set) var status = I2CBusStatus.noData
    private(set) var history = Timeline<I2CErrorSample>()

    var hasData: Bool { status != .noData }

    mutating func record(nacks: Int, timeouts: Int, resets: Int, at time: Date) {
        self.nacks = nacks
        self.timeouts = timeouts
        self.resets = resets
        status = Self.status(nacks: nacks, timeouts: timeouts, resets: resets)
        history.append(I2CErrorSample(time: time, nacks: nacks, timeouts: timeouts, resets: resets))
    }

    static func status(nacks: Int, timeouts: Int, resets: Int) -> I2CBusStatus {
        let total = nacks + timeouts + resets
        if total == 0 { return .healthy }
        if resets > 0 || total > errorThreshold { return .error }
        return .warning
    }
}
