import SwiftUI

/// I2C bus health and IMU vibration spectra
struct DiagnosticsView: View {
    @Environment(AppModel.self) private var model
    // Generated once per visit
    @State private var balancerSpectrum = PlaceholderSpectrum.balancer()
    @State private var oakDSpectrum = PlaceholderSpectrum.oakD()

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.cardSpacing) {
                I2CHealthCard(health: model.telemetry.i2cHealth)

                LazyVGrid(columns: Layout.cardColumns, spacing: Layout.cardSpacing) {
                    SpectrumCard(title: "Balancer IMU", spectrum: balancerSpectrum)
                    SpectrumCard(title: "OAK-D Pro W IMU", spectrum: oakDSpectrum)
                }
            }
            .padding(Layout.pagePadding)
        }
    }
}

/// NACK / timeout / reset counts and an error timeline
private struct I2CHealthCard: View {
    let health: I2CHealth

    var body: some View {
        Card(title: "I2C Bus Health", subtitle: "Aggregate health from instinctus via cogitator") {
            HStack(spacing: 8) {
                Text("Status")
                    .font(.subheadline.weight(.medium))
                StatusBadge(text: health.status.label, tint: statusTint)
            }

            HStack(alignment: .top) {
                Metric("NACKs", value: health.hasData ? "\(health.nacks)" : missingValue)
                Metric("Timeouts", value: health.hasData ? "\(health.timeouts)" : missingValue)
                Metric("Resets", value: health.hasData ? "\(health.resets)" : missingValue)
            }

            let samples = health.history.samples
            if samples.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Error Timeline (NACKs + Timeouts)")
                        .font(.subheadline.weight(.medium))
                    SeriesChart(
                        series: [
                            ChartSeries(
                                name: "Errors",
                                color: ChartStyle.primary,
                                filled: true,
                                timeline: samples,
                                time: \.time,
                                value: { Double($0.nacks + $0.timeouts) }
                            ),
                        ],
                        xTitle: "Seconds Ago",
                        yTitle: "Errors",
                        height: ChartStyle.compactHeight
                    )
                }
            } else {
                WaitingPlaceholder(text: "Waiting for I2C health data…")
            }
        }
    }

    private var statusTint: Color {
        switch health.status {
        case .healthy: .green
        case .warning: .yellow
        case .error: .red
        case .noData: .secondary
        }
    }
}

/// Accelerometer frequency spectrum (placeholder data)
private struct SpectrumCard: View {
    let title: String
    let spectrum: [SpectrumPoint]

    var body: some View {
        Card(title: title, subtitle: "FFT - Accelerometer Data") {
            SeriesChart(
                series: [
                    ChartSeries(
                        name: "Magnitude",
                        color: ChartStyle.primary,
                        filled: true,
                        points: spectrum.enumerated().map { index, point in
                            ChartPoint(id: index, x: point.frequency, y: point.magnitude)
                        }
                    ),
                ],
                xTitle: "Frequency (Hz)",
                yTitle: "Magnitude"
            )
        }
    }
}

#Preview {
    DiagnosticsView()
        .environment(AppModel())
        .frame(width: 1000, height: 900)
}
