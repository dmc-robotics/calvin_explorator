import SwiftUI

/// One IMU's latest X/Y/Z values and history, switchable between its three sensors
struct IMUCard: View {
    private static let valueFormat = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(2))

    let title: String
    let sensor: IMUSensor
    @State private var mode = IMUMode.accel

    var body: some View {
        Card(title: title, subtitle: "\(mode.label) - X, Y, Z axes") {
            Picker("Sensor", selection: $mode) {
                ForEach(IMUMode.allCases) { mode in
                    Text(mode.shortLabel)
                        .help(mode.label)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
        } content: {
            let samples = sensor.history.samples
            if let latest = sensor.latest, samples.count > 1 {
                let vector = mode.vector(in: latest)
                HStack(alignment: .top) {
                    Metric("X", value: vector.x.formatted(Self.valueFormat))
                    Metric("Y", value: vector.y.formatted(Self.valueFormat))
                    Metric("Z", value: vector.z.formatted(Self.valueFormat))
                }

                SeriesChart(
                    series: [
                        series("X", color: ChartStyle.x, samples: samples, axis: \.x),
                        series("Y", color: ChartStyle.y, samples: samples, axis: \.y),
                        series("Z", color: ChartStyle.z, samples: samples, axis: \.z),
                    ],
                    xTitle: "Seconds Ago",
                    yTitle: "\(mode.label) (\(mode.unit))",
                    height: ChartStyle.compactHeight
                )
            } else {
                WaitingPlaceholder()
            }
        }
    }

    private func series(_ name: String, color: Color, samples: [IMUReading], axis: KeyPath<Vector3, Double>) -> ChartSeries {
        ChartSeries(name: name, color: color, timeline: samples, time: \.time) { reading in
            mode.vector(in: reading)[keyPath: axis]
        }
    }
}
