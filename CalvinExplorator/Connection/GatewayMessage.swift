import Foundation

/// Topics the gateway forwards that this app understands.
/// Cogitator forwards everything under `sensor.` and `instinctus.`; see its `config/settings.py`.
enum Topic: String {
    /// `{"front": mm, "rear": mm}` — either side may be missing
    case tof = "sensor.tof"
    /// `{"source": "oakd"?, "ax"…"mz"}` — no source means the balancer IMU
    case imu = "sensor.imu"
    /// `{"nacks", "timeouts", "resets"}`
    case i2cHealth = "sensor.i2c_health"
    /// Instinctus balance loop at 50 Hz — see cogitator's PROTOCOL.md `telemetry`
    case balance = "sensor.telemetry"
}

/// Every gateway message, in both directions, is wrapped as `{"topic": "...", "data": {...}}`
struct GatewayEnvelope<Payload> {
    let topic: String
    let data: Payload
}

extension GatewayEnvelope: Decodable where Payload: Decodable {}
extension GatewayEnvelope: Encodable where Payload: Encodable {}

/// Just the topic, read first to decide how to decode `data`
struct GatewayTopic: Decodable {
    let topic: String
}

struct ToFPayload: Decodable {
    let front: Double?
    let rear: Double?
}

struct IMUPayload: Decodable {
    let source: String?
    let ax, ay, az: Double?
    let gx, gy, gz: Double?
    let mx, my, mz: Double?
}

struct I2CHealthPayload: Decodable {
    let nacks: Int?
    let timeouts: Int?
    let resets: Int?
}

/// Field names follow the serial protocol
struct BalancePayload: Decodable {
    let tilt: Double
    let tiltRate: Double
    let targetVel: Double
    let motorL: Double
    let motorR: Double
    let loopCount: Int
}
