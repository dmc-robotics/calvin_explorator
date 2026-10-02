# Calvin Explorator

Big picture (systems, wiring, working rules): see `../CLAUDE.md`.

## Overview

The native macOS (SwiftUI) monitoring and control app for Calvin. It follows macOS conventions. It connects to cogitator's WebSocket gateway (port 5560). Data flows in only: the gateway ignores inbound messages, so nothing the app sends reaches the robot yet.

Single-user app for one personal Mac. Only needs to support macOS 27.

## Tech Stack

- **SwiftUI** app, **Swift 6** language mode, macOS 27 deployment target
- **Default actor isolation = MainActor** and approachable concurrency are on. Code is main-actor unless marked `nonisolated` (only `Connection/WebSocket.swift` runs off the main actor)
- **Observation** (`@Observable`) for state; `AppModel` is injected with `.environment(model)`
- **Swift Charts** for all charts, **URLSessionWebSocketTask** for the gateway connection
- **Swift Testing** for unit tests
- **No third-party packages.** Only Apple frameworks. Ask before adding any dependency
- App Sandbox + outgoing network connections, hardened runtime, ad-hoc signed ("Sign to Run Locally")

## Building

Open `CalvinExplorator.xcodeproj` in Xcode 27, or from the terminal:

```bash
xcodebuild -project CalvinExplorator.xcodeproj -scheme CalvinExplorator build
xcodebuild -project CalvinExplorator.xcodeproj -scheme CalvinExplorator test
```

If `xcode-select -p` points at the Command Line Tools, prefix with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` (or run `sudo xcode-select -s /Applications/Xcode.app`).

The project uses **synchronized folders**: any file added under `CalvinExplorator/` or `CalvinExploratorTests/` is picked up automatically — no project file edits needed. Keys with no `INFOPLIST_KEY_` build setting (local network usage, ATS) live in `Config/Info.plist`, which is merged into the generated Info.plist.

### Testing against live data

Run cogitator locally with dummy data (needs `pyzmq` and `websockets`):

```bash
cd ../calvin_cogitator/cogitator && ./run.sh --dummy
```

The dummy service only sends `sensor.telemetry` (balance) and `instinctus.log`. ToF, IMU, and I2C cards stay on "Waiting for data…" unless something publishes those topics.

Launch arguments go into UserDefaults, so `-selectedPage telemetry` opens a specific page (`dashboard`, `services`, `telemetry`, `motorControl`, `diagnostics`, `logger`).

## Project Structure

```
CalvinExplorator/
├── App/            CalvinExploratorApp (scenes), AppModel (app-wide state), Page (sidebar), AppCommands (menus)
├── Connection/     GatewaySocket (protocol) + WebSocket (real socket), CogitatorConnection (reconnect loop + watchdog),
│                   LinkMonitor (timeouts), ReconnectPolicy, ConnectionStatus, CogitatorEndpoint (host/port + persistence),
│                   GatewayMessage (topics, payloads, SensorLimits)
├── Models/         Value types: Timeline, ToFSensor, I2CHealth, IMUSensor, BalanceState, BatteryStatus, PlaceholderSpectrum
├── Stores/         TelemetryStore (parses gateway messages), MessageLog (Logger page), ServicesStore
└── Views/          ContentView (NavigationSplitView + toolbar), one folder per page, Components/ (Card, Metric,
                    StatusBadge, SeriesChart, Layout constants), Toolbar/ (battery, connection, obstacle warnings, STOP)
CalvinExploratorTests/   Swift Testing suites; `FakeSocket` in TestSupport.swift drives CogitatorConnection with millisecond timings
Config/Info.plist        Extra Info.plist keys
```

## Gateway Protocol

Every WebSocket message is `{"topic": "...", "data": {...}}` in both directions (`GatewayEnvelope`). Topics handled (`Topic` enum in `Connection/GatewayMessage.swift`):

| Topic | Payload | Shown on |
|---|---|---|
| `sensor.telemetry` | instinctus balance loop, 50 Hz: `tilt`, `tiltRate`, `targetVel`, `motorL`, `motorR`, `loopCount` | Telemetry → Balance |
| `sensor.tof` | `front`, `rear` (mm, either optional) | Telemetry, toolbar warnings |
| `sensor.imu` | `ax`…`mz`, `source: "oakd"` for the camera IMU | Telemetry |
| `sensor.i2c_health` | `nacks`, `timeouts`, `resets` | Diagnostics |

Everything else (e.g. `instinctus.log`, `instinctus.event`, `instinctus.ack`) only appears in the Logger. `sensor.tof`/`imu`/`i2c_health` come from an earlier plan and aren't sent by cogitator yet; `sensor.telemetry` is what cogitator actually sends today.

To handle a new topic: add a case to `Topic`, a `Decodable` payload struct, a model in `Models/`, and an `apply` in `TelemetryStore`.

## Key Behaviors

- **Connection:** `CogitatorConnection` retries with backoff 1s → 2s → 4s … capped at 30s, goes **Offline** after 5 consecutive failures (manual Retry in the toolbar, or Robot ▸ Reconnect ⇧⌘R). Only a connection that stayed open ≥5s resets the count, so a gateway that accepts and drops clients still ends up offline. Host/port are set in Settings (⌘,) and saved in UserDefaults; the host must be a hostname, IPv4, or bracketed IPv6 address
- **Dead-link detection:** a watchdog (`LinkMonitor`, every 1s) closes the socket if the handshake takes >5s or an open connection hears nothing — no message and no pong — for 5s, and pings it otherwise. Pings (answered automatically by Python `websockets`) keep a quiet-but-alive gateway connected, e.g. when the Teensy is unplugged
- **Untrusted input:** frames over 64 KB fail the connection; I2C counts decode as `UInt16`; ToF distances outside 0–65535 mm and other readings beyond ±1,000,000 (`SensorLimits`) are ignored. Backlogs are capped (socket buffer 1000 events, `AppModel` 2000 pending messages — drops are counted in the Logger header) and log entries are cut at 4096 characters
- **Obstacle warnings:** red when a ToF reading is under 200 mm (0 included), gray "stale" when a sensor hasn't reported for 2s (including after a disconnect)
- **UI refresh batching:** `AppModel` queues received messages and applies them every 100 ms (`refreshInterval`). Charts redraw at that rate instead of per message — this matters for CPU (instinctus alone sends 50 msg/s)
- **Charts:** use `SeriesChart` (vectorized `LinePlot`/`AreaPlot`). Timelines plot seconds relative to the newest sample. Colors come from `ChartStyle`: accent color for single series, red/green/blue for X/Y/Z
- **Logger:** a `List` (table-backed; a `LazyVStack` was ~4× more CPU at 5000 rows). Keeps the newest 5000 messages; pause stops recording
- **STOP** (toolbar, Robot ▸ Emergency Stop ⌘.): **UI only** — shows an alert that nothing was sent. Wire it up once the gateway accepts commands; `AppModel.send(topic:data:)` is the send path (async; logs TX only after the send succeeds, TX! in red if it fails). Before it sends anything safety-related, plan for an ack from instinctus (`instinctus.ack`) and some gateway authentication — today anything on the LAN can pose as cogitator

## Placeholders (dummy data until real sources exist)

- Battery % in the toolbar (random 65–74% at launch) — `BatteryStatus.placeholder()`
- ToF signal quality (random by distance) — `ToFSensor.placeholderSignalQuality`
- IMU FFT spectra on Diagnostics — `PlaceholderSpectrum`
- Services switches — saved locally, not sent anywhere
- Video area and Motor Control page

## Conventions

- **Follow the system**: light/dark appearance and accent color come from macOS; no custom themes. Use semantic colors (`.secondary`, `Color.accentColor`, `.background.secondary`) and status colors via `StatusTone.color`
- Settings live in the standard Settings window, not the sidebar
- Menu shortcuts: ⌘1–⌘6 switch pages, ⌃⌘S toggles the sidebar, ⌘. STOP, ⇧⌘R reconnect
- Named constants instead of magic numbers (`Layout`, `ChartStyle`, static lets on models)
- Keep models as plain value types with the threshold logic as `static func`s so it's unit-testable
- Match the surrounding code's comment density and naming; avoid abbreviations in new names
