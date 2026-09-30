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
                ObstacleWarnings(
                    front: model.telemetry.tofFront.isObstacleWarning,
                    rear: model.telemetry.tofRear.isObstacleWarning
                )
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
        if let lastError, status != .connected {
            text += "\n\(lastError)"
        }
        return text
    }
}

/// Red warnings when a ToF sensor sees something too close
struct ObstacleWarnings: View {
    let front: Bool
    let rear: Bool

    var body: some View {
        if front || rear {
            HStack(spacing: 8) {
                if front { warning("Front") }
                if rear { warning("Rear") }
            }
            .foregroundStyle(.red)
        }
    }

    private func warning(_ side: String) -> some View {
        Label(side, systemImage: "exclamationmark.triangle.fill")
            .labelStyle(.titleAndIcon)
            .font(.callout.weight(.medium))
            .help("\(side) obstacle closer than \(ToFSensor.warningDistance) mm")
    }
}
