import Foundation
import Observation

/// App-wide state: the cogitator connection and everything fed by it
@Observable
final class AppModel {
    let connection = CogitatorConnection()
    let telemetry = TelemetryStore()
    let messageLog = MessageLog()
    let services: ServicesStore
    /// Dummy until the battery monitor reports real data
    let battery = BatteryStatus.placeholder()

    /// Restored on launch. Also settable with the launch argument `-selectedPage <page>`
    var selectedPage: Page? {
        didSet { defaults.set(selectedPage?.rawValue, forKey: Self.selectedPageKey) }
    }
    var isStopAlertPresented = false
    private(set) var endpoint: CogitatorEndpoint

    private static let selectedPageKey = "selectedPage"
    /// Received messages are applied in batches this often, so the UI redraws at this rate
    /// rather than once per message (instinctus alone sends 50 per second)
    private static let refreshInterval: Duration = .milliseconds(100)

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var pendingMessages: [(text: String, time: Date)] = []
    @ObservationIgnored private var flushTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        selectedPage = defaults.string(forKey: Self.selectedPageKey).flatMap(Page.init(rawValue:)) ?? .dashboard
        endpoint = CogitatorEndpoint.load(from: defaults)
        services = ServicesStore(defaults: defaults)
        connection.onMessage = { [weak self] text in
            self?.receive(text)
        }
    }

    /// Connects to the saved endpoint unless a connection is already up or in progress
    func start() {
        guard connection.status == .disconnected else { return }
        reconnect()
    }

    /// Saves `newEndpoint` as the default and connects to it
    func connect(to newEndpoint: CogitatorEndpoint) {
        endpoint = newEndpoint
        newEndpoint.save(to: defaults)
        reconnect()
    }

    /// Drops the current connection and starts a fresh round of attempts
    func reconnect() {
        guard let url = endpoint.url else { return }
        connection.connect(to: url)
    }

    /// Sends `{"topic": topic, "data": data}` to cogitator and logs it. Returns false when not connected
    @discardableResult
    func send(topic: String, data: some Encodable) -> Bool {
        guard let json = try? JSONEncoder().encode(GatewayEnvelope(topic: topic, data: data)) else { return false }
        let text = String(decoding: json, as: UTF8.self)
        guard connection.send(text) else { return false }
        // Keep the log in order: anything received before this goes first
        flushPendingMessages()
        messageLog.record(.sent, text)
        return true
    }

    /// STOP is UI-only for now: cogitator's gateway doesn't accept commands yet, so nothing is sent
    func emergencyStop() {
        isStopAlertPresented = true
    }

    /// Queues a message, keeping its arrival time, and schedules a flush if none is pending
    private func receive(_ text: String) {
        pendingMessages.append((text, .now))
        guard flushTask == nil else { return }
        flushTask = Task {
            try? await Task.sleep(for: Self.refreshInterval)
            flushPendingMessages()
        }
    }

    private func flushPendingMessages() {
        flushTask?.cancel()
        flushTask = nil
        for message in pendingMessages {
            // Log before parsing so malformed messages are still visible
            messageLog.record(.received, message.text, at: message.time)
            telemetry.handle(message: message.text, receivedAt: message.time)
        }
        pendingMessages.removeAll()
    }
}
