import SwiftUI

/// Placeholder shown for a value that hasn't arrived yet
let missingValue = "--"

/// A small caption over a large, fixed-width-digit value
struct Metric<Value: View>: View {
    let title: String
    @ViewBuilder var value: Value

    init(_ title: String, @ViewBuilder value: () -> Value) {
        self.title = title
        self.value = value()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            value
                .font(.title2.weight(.semibold).monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension Metric where Value == Text {
    init(_ title: String, value: String) {
        self.init(title) { Text(value) }
    }
}

/// Capsule label tinted by status
struct StatusBadge: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(tint)
            .background(tint.opacity(0.18), in: .capsule)
    }
}

/// Empty-state box the same height as the chart that will replace it
struct WaitingPlaceholder: View {
    var text = "Waiting for data…"
    var height = ChartStyle.compactHeight

    var body: some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: height)
    }
}

extension StatusTone {
    var color: Color {
        switch self {
        case .good: .green
        case .warning: .yellow
        case .critical: .red
        }
    }
}

#Preview {
    HStack {
        Metric("Distance", value: "1234 mm")
        Metric("Status") { StatusBadge(text: "Valid", tint: .green) }
    }
    .padding()
}
