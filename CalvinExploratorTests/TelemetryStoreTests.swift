import Foundation
import Testing
@testable import CalvinExplorator

struct TelemetryStoreTests {
    let store = TelemetryStore()

    @Test func tofUpdatesOnlyTheSidesPresent() {
        store.handle(message: #"{"topic":"sensor.tof","data":{"front":250.4}}"#)

        #expect(store.tofFront.distance == 250)
        #expect(store.tofFront.rangeStatus == .valid)
        #expect(store.tofFront.history.samples.count == 1)
        #expect(store.tofRear.rangeStatus == .noData)
        #expect(store.tofRear.history.samples.isEmpty)
    }

    @Test func imuRoutesBySource() {
        store.handle(message: #"{"topic":"sensor.imu","data":{"ax":0.1,"ay":-0.02,"az":0.98,"gx":1,"gy":2,"gz":3}}"#)
        store.handle(message: #"{"topic":"sensor.imu","data":{"source":"oakd","ax":0.5}}"#)

        let balancer = try! #require(store.imuBalancer.latest)
        #expect(balancer.accel == Vector3(x: 0.1, y: -0.02, z: 0.98))
        #expect(balancer.gyro == Vector3(x: 1, y: 2, z: 3))
        // Missing fields read as zero
        #expect(balancer.mag == Vector3(x: 0, y: 0, z: 0))

        #expect(store.imuOakD.latest?.accel.x == 0.5)
        #expect(store.imuBalancer.history.samples.count == 1)
    }

    @Test func i2cHealthRecordsCountsAndStatus() {
        store.handle(message: #"{"topic":"sensor.i2c_health","data":{"nacks":2,"timeouts":1,"resets":0}}"#)

        #expect(store.i2cHealth.nacks == 2)
        #expect(store.i2cHealth.timeouts == 1)
        #expect(store.i2cHealth.status == .warning)
    }

    @Test func balanceTelemetryFromProtocolExample() {
        // Example line from cogitator's PROTOCOL.md, as the gateway wraps it
        let message = #"{"topic":"sensor.telemetry","data":{"type":"telemetry","ms":12345,"tilt":1.23,"tiltRate":-0.45,"targetVel":0.0,"motorL":0.0,"motorR":0.0,"loopCount":12345}}"#
        store.handle(message: message)

        let latest = try! #require(store.balance.latest)
        #expect(latest.tilt == 1.23)
        #expect(latest.tiltRate == -0.45)
        #expect(latest.loopCount == 12345)
    }

    @Test(arguments: [
        "not json",
        #"{"topic":"sensor.tof"}"#,
        #"{"topic":"sensor.telemetry","data":{"tilt":1}}"#,
        #"{"topic":"instinctus.log","data":{"level":"INFO","msg":"heartbeat"}}"#,
    ])
    func ignoresMalformedAndUnknownMessages(message: String) {
        store.handle(message: message)

        #expect(store.tofFront.rangeStatus == .noData)
        #expect(store.balance.latest == nil)
        #expect(store.i2cHealth.status == .noData)
    }
}

struct SensorModelTests {
    @Test(arguments: [
        (49, ToFRangeStatus.error),
        (50, .valid),
        (4000, .valid),
        (4001, .outOfRange),
    ])
    func tofRangeStatus(distance: Int, expected: ToFRangeStatus) {
        #expect(ToFSensor.rangeStatus(for: distance) == expected)
    }

    @Test func tofWarnsForCloseReadingsOnly() {
        var sensor = ToFSensor()
        #expect(!sensor.isObstacleWarning)

        sensor.record(distance: 30, at: .now)
        #expect(sensor.isObstacleWarning)

        sensor.record(distance: Double(ToFSensor.warningDistance), at: .now)
        #expect(!sensor.isObstacleWarning)
    }

    @Test(arguments: [
        (0, 0, 0, I2CBusStatus.healthy),
        (2, 1, 0, .warning),
        (0, 0, 1, .error),
        (4, 2, 0, .error),
    ])
    func i2cStatus(nacks: Int, timeouts: Int, resets: Int, expected: I2CBusStatus) {
        #expect(I2CHealth.status(nacks: nacks, timeouts: timeouts, resets: resets) == expected)
    }

    @Test func timelineKeepsNewestSamples() {
        var timeline = Timeline<Int>(capacity: 3)
        for value in 1...5 {
            timeline.append(value)
        }
        #expect(timeline.samples == [3, 4, 5])
        #expect(timeline.latest == 5)
    }

    @Test(arguments: [
        (100, StatusTone.good),
        (51, .good),
        (50, .warning),
        (21, .warning),
        (20, .critical),
    ])
    func batteryTone(percent: Int, expected: StatusTone) {
        #expect(BatteryStatus(percent: percent).tone == expected)
    }
}
