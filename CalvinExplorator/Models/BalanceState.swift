import Foundation

/// One instinctus balance-loop report (`sensor.telemetry`)
struct BalanceSample {
    let time: Date
    /// Degrees
    let tilt: Double
    /// Degrees per second
    let tiltRate: Double
    /// Meters per second
    let targetVelocity: Double
    /// Radians per second
    let motorLeft: Double
    /// Radians per second
    let motorRight: Double
    /// Balance ISR iteration count
    let loopCount: Int
}

struct BalanceState {
    /// Instinctus reports at 50 Hz, so keep about 5 seconds
    static let historyCapacity = 250

    private(set) var history = Timeline<BalanceSample>(capacity: historyCapacity)

    var latest: BalanceSample? { history.latest }

    mutating func record(_ sample: BalanceSample) {
        history.append(sample)
    }
}
