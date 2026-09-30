import Charts
import SwiftUI

/// Chart sizes and colors, following the system accent color and appearance
enum ChartStyle {
    static let height: CGFloat = 300
    static let compactHeight: CGFloat = 200
    static let lineWidth: CGFloat = 2
    /// Top and bottom opacity of area fills
    static let areaOpacity: (top: Double, bottom: Double) = (0.5, 0.05)

    static let primary = Color.accentColor
    static let secondary = Color.orange
    /// Conventional 3D axis colors
    static let x = Color.red
    static let y = Color.green
    static let z = Color.blue
}

struct ChartPoint: Identifiable {
    let id: Int
    let x: Double
    let y: Double
}

/// One line on a `SeriesChart`, optionally filled down to zero
struct ChartSeries: Identifiable {
    let name: String
    let color: Color
    var filled = false
    let points: [ChartPoint]

    var id: String { name }

    init(name: String, color: Color, filled: Bool = false, points: [ChartPoint]) {
        self.name = name
        self.color = color
        self.filled = filled
        self.points = points
    }

    /// Plots `value` against seconds relative to the newest sample (0 = newest, negative = older)
    init<Sample>(
        name: String,
        color: Color,
        filled: Bool = false,
        timeline samples: [Sample],
        time: (Sample) -> Date,
        value: (Sample) -> Double
    ) {
        let newest = samples.last.map(time) ?? .now
        let points = samples.enumerated().map { index, sample in
            ChartPoint(id: index, x: time(sample).timeIntervalSince(newest), y: value(sample))
        }
        self.init(name: name, color: color, filled: filled, points: points)
    }
}

/// Line / area chart. Shows a legend when there's more than one series
struct SeriesChart: View {
    let series: [ChartSeries]
    let xTitle: String
    let yTitle: String
    var height = ChartStyle.height

    var body: some View {
        // Vectorized plots (one per series) rather than a mark per point: these redraw several
        // times a second with hundreds of points each
        Chart(series) { line in
            if line.filled {
                AreaPlot(line.points, x: .value(xTitle, \.x), y: .value(yTitle, \.y), stacking: .unstacked)
                    .foregroundStyle(areaGradient(line.color))
            }
            LinePlot(line.points, x: .value(xTitle, \.x), y: .value(yTitle, \.y))
                .foregroundStyle(by: .value("Series", line.name))
                .lineStyle(StrokeStyle(lineWidth: ChartStyle.lineWidth))
        }
        .chartXScale(domain: xDomain)
        .chartForegroundStyleScale(domain: series.map(\.name), range: series.map(\.color))
        .chartLegend(series.count > 1 ? .visible : .hidden)
        .chartXAxisLabel(xTitle, alignment: .center)
        .chartYAxisLabel(yTitle)
        .frame(height: height)
    }

    /// Exactly the data's x range, so the axis doesn't pad out to a rounder number
    private var xDomain: ClosedRange<Double> {
        let xs = series.flatMap { $0.points.map(\.x) }
        guard let low = xs.min(), let high = xs.max(), low < high else { return 0...1 }
        return low...high
    }

    private func areaGradient(_ color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color.opacity(ChartStyle.areaOpacity.top), color.opacity(ChartStyle.areaOpacity.bottom)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview {
    let points = (0..<60).map { ChartPoint(id: $0, x: Double($0 - 59), y: sin(Double($0) / 5)) }
    SeriesChart(
        series: [ChartSeries(name: "Tilt", color: ChartStyle.primary, filled: true, points: points)],
        xTitle: "Seconds Ago",
        yTitle: "Tilt (°)"
    )
    .padding()
}
