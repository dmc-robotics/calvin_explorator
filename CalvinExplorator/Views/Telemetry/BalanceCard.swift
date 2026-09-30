import SwiftUI

/// Instinctus balance loop: tilt, motors, and a tilt history chart
struct BalanceCard: View {
    let balance: BalanceState

    var body: some View {
        Card(title: "Balance", subtitle: "Instinctus balance loop - 50 Hz") {
            let samples = balance.history.samples
            if let latest = balance.latest, samples.count > 1 {
                HStack(alignment: .top) {
                    Metric("Tilt", value: latest.tilt.formatted(Self.degrees) + "°")
                    Metric("Tilt Rate", value: latest.tiltRate.formatted(Self.degrees) + "°/s")
                    Metric("Target Velocity", value: latest.targetVelocity.formatted(Self.precise) + " m/s")
                    Metric("Motor L", value: latest.motorLeft.formatted(Self.precise) + " rad/s")
                    Metric("Motor R", value: latest.motorRight.formatted(Self.precise) + " rad/s")
                    Metric("Loop Count", value: latest.loopCount.formatted())
                }

                SeriesChart(
                    series: [
                        ChartSeries(
                            name: "Tilt",
                            color: ChartStyle.primary,
                            filled: true,
                            timeline: samples,
                            time: \.time,
                            value: \.tilt
                        ),
                    ],
                    xTitle: "Seconds Ago",
                    yTitle: "Tilt (°)",
                    height: ChartStyle.compactHeight
                )
            } else {
                WaitingPlaceholder()
            }
        }
    }

    private static let degrees = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(1))
    private static let precise = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(2))
}
