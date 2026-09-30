import SwiftUI

/// Always-visible robot status (battery, connection, obstacle warnings) and the STOP button
struct RobotStatusToolbar: ToolbarContent {
    let model: AppModel

    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            HStack(spacing: 14) {
                BatteryIndicator(battery: model.battery)
                ConnectionIndicator(
                    status: model.connection.status,
                    endpoint: model.endpoint,
                    lastError: model.connection.lastError,
                    retry: model.connection.retry
                )
                // Reads ToF data itself, so new readings only redraw this view
                ObstacleWarnings(telemetry: model.telemetry)
            }
            .padding(.horizontal, 8)
            // Grow when the Retry button or obstacle warnings appear instead of truncating them
            .fixedSize()
        }

        ToolbarSpacer(.fixed, placement: .primaryAction)

        ToolbarItem(placement: .primaryAction) {
            Button("STOP", systemImage: "xmark.octagon.fill", role: .destructive) {
                model.emergencyStop()
            }
            .labelStyle(.titleAndIcon)
            .fontWeight(.bold)
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .help("Emergency stop (⌘.)")
        }
    }
}

struct BatteryIndicator: View {
    let battery: BatteryStatus

    var body: some View {
        Label {
            Text("\(battery.percent)%")
                .monospacedDigit()
        } icon: {
            Image(systemName: symbolName)
                .foregroundStyle(battery.tone.color)
        }
        .labelStyle(.titleAndIcon)
        .help("Battery \(battery.percent)% (placeholder data)")
    }

    /// Nearest of SF Symbols' 0 / 25 / 50 / 75 / 100 percent battery glyphs
    private var symbolName: String {
        let quarter = (Double(battery.percent) / 25).rounded()
        return "battery.\(Int(quarter) * 25)percent"
    }
}

struct ConnectionIndicator: View {
    /// How often the retry countdown refreshes
    private static let countdownInterval: TimeInterval = 1

    let status: ConnectionStatus
    let endpoint: CogitatorEndpoint
    let lastError: String?
    let retry: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "circle.fill")
                .font(.system(size: 8))
                .foregroundStyle(dotColor)
                .symbolEffect(.pulse, isActive: status.isTrying)

            TimelineView(.periodic(from: .now, by: Self.countdownInterval)) { context in
                Text(status.label(now: context.date))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            if status == .offline {
                Button("Retry", systemImage: "arrow.clockwise", action: retry)
                    .labelStyle(.titleAndIcon)
                    .controlSize(.small)
            }
        }
        .help(helpText)
    }

    private var dotColor: Color {
        switch status {
        case .connected: .green
        case .connecting, .reconnecting: .yellow
        case .offline: .secondary
        case .disconnected: .red
        }
    }

    private var helpText: String {
        var text = "Cogitator at \(endpoint.displayName)"
        switch status {
        case .reconnecting, .offline:
            if let lastError { text += "\n\(lastError)" }
        default:
            break
        }
        return text
    }
}

/// Per ToF sensor: red when something is too close, gray when its readings have gone stale
struct ObstacleWarnings: View {
    /// How often staleness is re-checked when no new readings arrive
    private static let refreshInterval: TimeInterval = 1

    let telemetry: TelemetryStore

    var body: some View {
        TimelineView(.periodic(from: .now, by: Self.refreshInterval)) { context in
            let front = telemetry.tofFront.obstacleAlert(at: context.date)
            let rear = telemetry.tofRear.obstacleAlert(at: context.date)
            if front != .none || rear != .none {
                HStack(spacing: 8) {
                    alert(front, side: "Front")
                    alert(rear, side: "Rear")
                }
                .labelStyle(.titleAndIcon)
                .font(.callout.weight(.medium))
            }
        }
    }

    @ViewBuilder
    private func alert(_ alert: ObstacleAlert, side: String) -> some View {
        switch alert {
        case .none:
            EmptyView()
        case .close:
            Label(side, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .help("\(side) obstacle closer than \(ToFSensor.warningDistance) mm")
        case .stale:
            Label(side, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
                .help("No \(side.lowercased()) ToF reading for over \(Int(ToFSensor.staleAfter)) s")
        }
    }
}
