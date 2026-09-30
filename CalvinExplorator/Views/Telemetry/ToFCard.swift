import SwiftUI

/// One VL53L4CX distance sensor: latest reading, range status, and history
struct ToFCard: View {
    let title: String
    let sensor: ToFSensor
    let color: Color

    var body: some View {
        Card(title: title, subtitle: "VL53L4CX ToF - Adafruit 5425") {
            HStack(alignment: .top) {
                Metric("Distance", value: sensor.hasData ? "\(sensor.distance) mm" : missingValue)
                Metric("Status") {
                    StatusBadge(text: sensor.rangeStatus.label, tint: statusTint)
                }
                Metric("Signal", value: sensor.hasData ? "\(sensor.signalQuality)%" : missingValue)
            }

            let samples = sensor.history.samples
            if samples.count > 1 {
                SeriesChart(
                    series: [
                        ChartSeries(
                            name: "Distance",
                            color: color,
                            filled: true,
                            timeline: samples,
                            time: \.time,
                            value: { Double($0.distance) }
                        ),
                    ],
                    xTitle: "Seconds Ago",
                    yTitle: "Distance (mm)",
                    height: ChartStyle.compactHeight
                )
            } else {
                WaitingPlaceholder()
            }
        }
    }

    private var statusTint: Color {
        switch sensor.rangeStatus {
        case .valid: .green
        case .outOfRange: .yellow
        case .error: .red
        case .noData: .secondary
        }
    }
}
