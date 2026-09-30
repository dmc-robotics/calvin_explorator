import Foundation
@testable import CalvinExplorator

/// Polls `condition` until it's true or `timeout` passes. Returns whether it became true
func waitUntil(timeout: Duration = .seconds(3), _ condition: () -> Bool) async -> Bool {
    let deadline = ContinuousClock.now + timeout
    while !condition() {
        if ContinuousClock.now >= deadline { return false }
        try? await Task.sleep(for: .milliseconds(5))
    }
    return true
}

/// A throwaway UserDefaults suite, removed when the test is done with it
final class TestDefaults {
    let name = "CalvinExploratorTests-\(UUID().uuidString)"
    let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: name)!
    }

    deinit {
        UserDefaults.standard.removePersistentDomain(forName: name)
    }
}
