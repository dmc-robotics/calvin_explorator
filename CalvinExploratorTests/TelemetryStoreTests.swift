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

    @Test func imuRoutesBySource() throws {
        store.handle(message: #"{"topic":"sensor.imu","data":{"ax":0.1,"ay":-0.02,"az":0.98,"gx":1,"gy":2,"gz":3}}"#)
        store.handle(message: #"{"topic":"sensor.imu","data":{"source":"oakd","ax":0.5}}"#)

        let balancer = try #require(store.imuBalancer.latest)
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

    @Test func balanceTelemetryFromProtocolExample() throws {
        // Example line from cogitator's PROTOCOL.md, as the gateway wraps it
        let message = #"{"topic":"sensor.telemetry","data":{"type":"telemetry","ms":12345,"tilt":1.23,"tiltRate":-0.45,"targetVel":0.0,"motorL":0.0,"motorR":0.0,"loopCount":12345}}"#
        store.handle(message: message)

        let latest = try #require(store.balance.latest)
        #expect(latest.tilt == 1.23)
        #expect(latest.tiltRate == -0.45)
        #expect(latest.loopCount == 12345)
    }

    @Test(arguments: [
        "not json",
        #"{"topic":"sensor.tof"}"#,
        #"{"topic":"sensor.telemetry","data":{"tilt":1}}"#,
        #"{"topic":"instinctus.log","data":{"level":"INFO","msg":"heartbeat"}}"#,
        // Values that would crash or break charts if accepted
        #"{"topic":"sensor.tof","data":{"front":1e300,"rear":-5}}"#,
        #"{"topic":"sensor.i2c_health","data":{"nacks":9223372036854775807,"timeouts":1}}"#,
        #"{"topic":"sensor.i2c_health","data":{"nacks":-1}}"#,
        #"{"topic":"sensor.imu","data":{"ax":1e300}}"#,
        #"{"topic":"sensor.telemetry","data":{"tilt":-1e300,"tiltRate":0,"targetVel":0,"motorL":0,"motorR":0,"loopCount":1}}"#,
    ])
    func ignoresMalformedUnknownAndImplausibleMessages(message: String) {
        store.handle(message: message)

        #expect(!store.tofFront.hasData)
        #expect(!store.tofRear.hasData)
        #expect(store.balance.latest == nil)
        #expect(!store.i2cHealth.hasData)
        #expect(store.imuBalancer.latest == nil)
        #expect(store.imuOakD.latest == nil)
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

    @Test(arguments: [
        (0.0, ObstacleAlert.close),
        (30, .close),
        (199, .close),
        (200, .none),
        (1500, .none),
    ])
    func tofObstacleAlert(distance: Double, expected: ObstacleAlert) {
        let now = Date.now
        var sensor = ToFSensor()
        sensor.record(distance: distance, at: now)
        #expect(sensor.obstacleAlert(at: now) == expected)
    }

    @Test func tofAlertGoesStaleWithoutNewReadings() {
        let start = Date.now
        var sensor = ToFSensor()
        #expect(sensor.obstacleAlert(at: start) == .none)

        sensor.record(distance: 1500, at: start)
        #expect(sensor.obstacleAlert(at: start + ToFSensor.staleAfter) == .none)
        #expect(sensor.obstacleAlert(at: start + ToFSensor.staleAfter + 0.1) == .stale)
    }

    @Test func tofIgnoresUnreportableDistances() {
        var sensor = ToFSensor()
        sensor.record(distance: 70_000, at: .now)
        sensor.record(distance: -1, at: .now)
        #expect(!sensor.hasData)
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

    @Test func sensorLimits() {
        #expect(SensorLimits.arePlausible([1, -1, nil, SensorLimits.maximumMagnitude]))
        #expect(!SensorLimits.arePlausible([1, SensorLimits.maximumMagnitude * 2]))
    }
}

struct ServicesStoreTests {
    @Test func savesAndRestoresSwitches() throws {
        let testDefaults = TestDefaults()
        let service = try #require(ServicesStore.definitions.first)

        let store = ServicesStore(defaults: testDefaults.defaults)
        #expect(store.isEnabled(service) == service.enabledByDefault)
        store.setEnabled(true, for: service)

        #expect(ServicesStore(defaults: testDefaults.defaults).isEnabled(service))
    }
}
