import Foundation
import Observation

struct ServiceDefinition: Identifiable {
    let id: String
    let title: String
    let description: String
    var enabledByDefault = false
}

/// On/off state for each cogitator service, saved locally. Stubs: nothing is sent to cogitator yet
@Observable
final class ServicesStore {
    static let definitions: [ServiceDefinition] = [
        ServiceDefinition(
            id: "telemetry",
            title: "Telemetry Service",
            description: "Real-time monitoring and data collection from connected devices"
        ),
        ServiceDefinition(
            id: "diagnostics",
            title: "Diagnostics Service",
            description: "Automated system health checks and performance analysis"
        ),
        ServiceDefinition(
            id: "logging",
            title: "Logging Service",
            description: "Centralized logging and event tracking across all services"
        ),
        ServiceDefinition(
            id: "notifications",
            title: "Notification Service",
            description: "Alert system for critical events and system status changes"
        ),
        ServiceDefinition(
            id: "analytics",
            title: "Analytics Service",
            description: "Data processing and statistical analysis of collected metrics"
        ),
        ServiceDefinition(
            id: "backup",
            title: "Backup Service",
            description: "Automated backup and recovery of configuration and data"
        ),
    ]

    private static let defaultsKey = "services"

    private(set) var enabledByID: [String: Bool]
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        enabledByID = defaults.dictionary(forKey: Self.defaultsKey) as? [String: Bool] ?? [:]
    }

    func isEnabled(_ service: ServiceDefinition) -> Bool {
        enabledByID[service.id] ?? service.enabledByDefault
    }

    func setEnabled(_ enabled: Bool, for service: ServiceDefinition) {
        enabledByID[service.id] = enabled
        defaults.set(enabledByID, forKey: Self.defaultsKey)
    }
}
