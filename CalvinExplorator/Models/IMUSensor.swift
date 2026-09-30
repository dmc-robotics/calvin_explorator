import Foundation

struct Vector3: Equatable {
    var x: Double
    var y: Double
    var z: Double
}

struct IMUReading {
    let time: Date
    let accel: Vector3
    let gyro: Vector3
    let mag: Vector3
}

/// Which of the IMU's three sensors to show
enum IMUMode: CaseIterable, Identifiable {
    case accel
    case gyro
    case mag

    var id: Self { self }

    var label: String {
        switch self {
        case .accel: "Accelerometer"
        case .gyro: "Gyroscope"
        case .mag: "Magnetometer"
        }
    }

    /// For the compact mode picker
    var shortLabel: String {
        switch self {
        case .accel: "Accel"
        case .gyro: "Gyro"
        case .mag: "Mag"
        }
    }

    var unit: String {
        switch self {
        case .accel: "g"
        case .gyro: "°/s"
        case .mag: "µT"
        }
    }

    func vector(in reading: IMUReading) -> Vector3 {
        switch self {
        case .accel: reading.accel
        case .gyro: reading.gyro
        case .mag: reading.mag
        }
    }
}

/// Which IMU a `sensor.imu` message came from
enum IMUSource {
    /// ICM20948 on instinctus
    case balancer
    /// OAK-D Pro W camera's built-in IMU
    case oakD

    /// Messages tagged `"source": "oakd"` are from the camera; anything else is the balancer
    init(tag: String?) {
        self = tag == "oakd" ? .oakD : .balancer
    }
}

struct IMUSensor {
    private(set) var history = Timeline<IMUReading>()

    var latest: IMUReading? { history.latest }

    mutating func record(_ reading: IMUReading) {
        history.append(reading)
    }
}
