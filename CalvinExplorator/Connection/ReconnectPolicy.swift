import Foundation

/// Timing for connecting to cogitator, detecting a dead link, and retrying after failures
struct ReconnectPolicy {
    /// Wait before the first retry; doubles after each further failure
    var initialDelay: TimeInterval = 1
    var maxDelay: TimeInterval = 30
    var multiplier: Double = 2
    /// Stop retrying (go offline) after this many consecutive failures
    var maxAttempts = 5
    /// Give up on a connection attempt whose handshake hasn't finished by then
    var connectTimeout: TimeInterval = 5
    /// Close an open connection when neither a message nor a pong has arrived for this long
    var livenessTimeout: TimeInterval = 5
    /// How often the watchdog checks the timeouts and pings an open connection
    var watchdogInterval: TimeInterval = 1
    /// A connection must stay open this long before a drop starts a fresh round of attempts.
    /// Shorter ones count as failures, so a gateway that accepts and then drops clients still ends up offline
    var minimumStableDuration: TimeInterval = 5

    /// Wait before the retry that follows `failures` consecutive failures (1 = first failure)
    func delay(afterFailures failures: Int) -> TimeInterval {
        let exponent = Double(max(0, failures - 1))
        return min(initialDelay * pow(multiplier, exponent), maxDelay)
    }
}
