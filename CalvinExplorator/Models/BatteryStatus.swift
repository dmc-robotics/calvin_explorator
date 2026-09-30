import Foundation

/// Color band for a status indicator
enum StatusTone {
    case good
    case warning
    case critical
}

/// 12V LiPo (3S) state of charge. Placeholder until the INA228 monitor reports real data
struct BatteryStatus {
    /// Charge at or below which the indicator turns warning / critical
    static let warningPercent = 50
    static let criticalPercent = 20

    let percent: Int

    var tone: StatusTone {
        if percent <= Self.criticalPercent { return .critical }
        if percent <= Self.warningPercent { return .warning }
        return .good
    }

    /// Random dummy charge
    static func placeholder() -> BatteryStatus {
        BatteryStatus(percent: Int.random(in: 65..<75))
    }
}
