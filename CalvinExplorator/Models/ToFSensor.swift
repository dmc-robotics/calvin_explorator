import Foundation

/// How to read a ToF distance
enum ToFRangeStatus: Equatable {
    case noData
    case valid
    case outOfRange
    case error

    var label: String {
        switch self {
        case .noData: "No Data"
        case .valid: "Valid"
        case .outOfRange: "Out of Range"
        case .error: "Error"
        }
    }
}

/// What the toolbar should say about one ToF sensor
enum ObstacleAlert: Equatable {
    case none
    /// Latest reading is closer than `ToFSensor.warningDistance`
    case close
    /// No reading for longer than `ToFSensor.staleAfter`, so the last one can't be trusted either way
    case stale
}

struct DistanceSample {
    let time: Date
    /// Millimeters
    let distance: Int
}

/// One VL53L4CX time-of-flight sensor (Adafruit 5425)
struct ToFSensor {
    /// Readings below this are errors (mm)
    static let minValidDistance = 50
    /// Readings above this are out of range (mm)
    static let maxValidDistance = 4000
    /// An obstacle closer than this raises the toolbar warning (mm)
    static let warningDistance = 200
    /// Values outside this can't come from the sensor and are ignored (mm)
    static let reportableDistances = 0.0...65_535.0
    /// Instinctus polls at 20 Hz; a reading older than this is stale
    static let staleAfter: TimeInterval = 2

    /// Latest reading in millimeters
    private(set) var distance = 0
    private(set) var rangeStatus = ToFRangeStatus.noData
    /// Percent. Placeholder until instinctus reports real signal quality
    private(set) var signalQuality = 0
    private(set) var latestTime: Date?
    private(set) var history = Timeline<DistanceSample>()

    var hasData: Bool { rangeStatus != .noData }

    /// Any close reading warns, including ones below the sensor's valid range (0 means touching)
    func obstacleAlert(at now: Date) -> ObstacleAlert {
        guard let latestTime else { return .none }
        if now.timeIntervalSince(latestTime) > Self.staleAfter { return .stale }
        return distance < Self.warningDistance ? .close : .none
    }

    static func isReportable(_ rawDistance: Double) -> Bool {
        reportableDistances.contains(rawDistance)
    }

    /// Records a reading. Ignores values outside `reportableDistances`
    mutating func record(distance rawDistance: Double, at time: Date) {
        guard Self.isReportable(rawDistance) else { return }
        let distance = Int(rawDistance.rounded())
        self.distance = distance
        rangeStatus = Self.rangeStatus(for: distance)
        signalQuality = Self.placeholderSignalQuality(for: distance)
        latestTime = time
        history.append(DistanceSample(time: time, distance: distance))
    }

    static func rangeStatus(for distance: Int) -> ToFRangeStatus {
        if distance < minValidDistance { return .error }
        if distance > maxValidDistance { return .outOfRange }
        return .valid
    }

    /// Random stand-in: quality drops very close (<200 mm) and far (>3000 mm)
    static func placeholderSignalQuality(for distance: Int) -> Int {
        if distance < 200 { return Int.random(in: 50..<80) }
        if distance > 3000 { return Int.random(in: 60..<90) }
        return Int.random(in: 85..<100)
    }
}
