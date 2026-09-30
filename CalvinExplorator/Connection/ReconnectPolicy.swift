import Foundation

/// Timing for connecting to cogitator and retrying after failures
struct ReconnectPolicy {
    /// Wait before the first retry; doubles after each further failure
    var initialDelay: TimeInterval = 1
    var maxDelay: TimeInterval = 30
    var multiplier: Double = 2
    /// Stop retrying (go offline) after this many consecutive failures
    var maxAttempts = 5
    /// Give up on a connection attempt whose handshake hasn't finished by then
    var connectTimeout: TimeInterval = 5

    /// Wait before the retry that follows `failures` consecutive failures (1 = first failure)
    func delay(afterFailures failures: Int) -> TimeInterval {
        let exponent = Double(max(0, failures - 1))
        return min(initialDelay * pow(multiplier, exponent), maxDelay)
    }
}
