# Calvin Explorator for macOS

Native macOS monitoring console for Calvin, the self-balancing robot. It connects to cogitator's WebSocket gateway (`ws://<host>:5560`) and shows live balance, IMU, ToF, and I2C data, plus a raw message log.

Replaces the earlier Electron app.

## Requirements

- macOS 27
- Xcode 27

## Build and run

Open `CalvinExplorator.xcodeproj` and press ⌘R, or:

```bash
xcodebuild -project CalvinExplorator.xcodeproj -scheme CalvinExplorator build
xcodebuild -project CalvinExplorator.xcodeproj -scheme CalvinExplorator test
```

Set the cogitator host and port in **Calvin Explorator ▸ Settings… (⌘,)**. The default is `localhost:5560`.

To try it without the robot, run cogitator with dummy data:

```bash
cd ../calvin_cogitator/cogitator && ./run.sh --dummy
```

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| ⌘1 – ⌘6 | Dashboard, Services, Telemetry, Motor Control, Diagnostics, Logger |
| ⌃⌘S | Show/hide sidebar |
| ⌘. | STOP (UI only for now) |
| ⇧⌘R | Reconnect to cogitator |
| ⌘, | Settings |
