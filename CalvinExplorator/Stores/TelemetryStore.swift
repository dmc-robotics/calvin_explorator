import Foundation
import Observation

/// Latest sensor state and history, fed by messages from cogitator's gateway
@Observable
final class TelemetryStore {
    private(set) var tofFront = ToFSensor()
    private(set) var tofRear = ToFSensor()
    private(set) var i2cHealth = I2CHealth()
    private(set) var imuBalancer = IMUSensor()
    private(set) var imuOakD = IMUSensor()
    private(set) var balance = BalanceState()

    @ObservationIgnored private let decoder = JSONDecoder()

    /// Applies one raw gateway message. Unknown topics and malformed messages are ignored
    /// (they still show up in the Logger)
    func handle(message text: String, receivedAt time: Date = .now) {
        let json = Data(text.utf8)
        guard let header = try? decoder.decode(GatewayTopic.self, from: json),
              let topic = Topic(rawValue: header.topic)
        else { return }

        do {
            switch topic {
            case .tof:
                apply(try payload(ToFPayload.self, from: json), at: time)
            case .imu:
                apply(try payload(IMUPayload.self, from: json), at: time)
            case .i2cHealth:
                apply(try payload(I2CHealthPayload.self, from: json), at: time)
            case .balance:
                apply(try payload(BalancePayload.self, from: json), at: time)
            }
        } catch {
            // Malformed payload for a known topic; nothing to update
        }
    }

    private func payload<Payload: Decodable>(_ type: Payload.Type, from json: Data) throws -> Payload {
        try decoder.decode(GatewayEnvelope<Payload>.self, from: json).data
    }

    private func apply(_ payload: ToFPayload, at time: Date) {
        if let front = payload.front {
            tofFront.record(distance: front, at: time)
        }
        if let rear = payload.rear {
            tofRear.record(distance: rear, at: time)
        }
    }

    private func apply(_ payload: IMUPayload, at time: Date) {
        let reading = IMUReading(
            time: time,
            accel: Vector3(x: payload.ax ?? 0, y: payload.ay ?? 0, z: payload.az ?? 0),
            gyro: Vector3(x: payload.gx ?? 0, y: payload.gy ?? 0, z: payload.gz ?? 0),
            mag: Vector3(x: payload.mx ?? 0, y: payload.my ?? 0, z: payload.mz ?? 0)
        )
        switch IMUSource(tag: payload.source) {
        case .balancer: imuBalancer.record(reading)
        case .oakD: imuOakD.record(reading)
        }
    }

    private func apply(_ payload: I2CHealthPayload, at time: Date) {
        i2cHealth.record(
            nacks: payload.nacks ?? 0,
            timeouts: payload.timeouts ?? 0,
            resets: payload.resets ?? 0,
            at: time
        )
    }

    private func apply(_ payload: BalancePayload, at time: Date) {
        balance.record(BalanceSample(
            time: time,
            tilt: payload.tilt,
            tiltRate: payload.tiltRate,
            targetVelocity: payload.targetVel,
            motorLeft: payload.motorL,
            motorRight: payload.motorR,
            loopCount: payload.loopCount
        ))
    }
}
