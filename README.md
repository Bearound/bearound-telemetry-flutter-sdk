# Bearound Telemetry — Flutter SDK

Flutter wrapper for the [Bearound Telemetry Android SDK](https://github.com/Bearound/bearound-telemetry-android-sdk) — beacon-**hardware** telemetry (battery, temperature, movement, firmware version, signal) using Bluetooth scanning with `neverForLocation`.

> **IMPORTANT — no tracking.** This SDK does not track people. It requires **no location permission** and produces no positioning data. It collects exclusively the health telemetry advertised by Bearound beacons. For presence/positioning, use the main [`bearound_flutter_sdk`](https://github.com/Bearound/bearound-flutter-sdk) — both can (and should) run side by side.

**Android only.** On iOS the telemetry fields already travel through the main Bearound SDK.

## Architecture

Two SDKs, one integration:

| | `bearound_flutter_sdk` (tracking) | `bearound_telemetry_flutter_sdk` (this) |
|---|---|---|
| Purpose | Presence & positioning | Beacon hardware health |
| Permissions | Location + Bluetooth | Bluetooth only (`neverForLocation`) |
| Works without location permission | No | **Yes** |

When both are installed, `configure()` performs an automatic **companion handoff**: the telemetry SDK reuses the tracking SDK's business token and device id, so both report as the same device. If the user denies location, tracking stops — telemetry keeps working.

## Installation

```yaml
dependencies:
  bearound_telemetry_flutter_sdk: ^0.1.0
```

The Android native SDK is resolved from JitPack. Add JitPack to your app's `android/build.gradle(.kts)` repositories if not present:

```kotlin
allprojects {
    repositories {
        maven(url = "https://jitpack.io")
    }
}
```

Requires `minSdk 26`. If your release build uses R8/minify, add the usual Tink rule to your `proguard-rules.pro`:

```
-dontwarn javax.annotation.**
```

## Usage

```dart
import 'package:bearound_telemetry_flutter_sdk/bearound_telemetry_flutter_sdk.dart';

await BearoundTelemetry.requestPermissions(); // "Nearby devices" on Android 12+

// If the Bearound tracking SDK is installed and configured, the token is
// taken from it automatically (companion handoff) — returns true.
final companion = await BearoundTelemetry.configure(businessToken: 'YOUR_BUSINESS_TOKEN');

await BearoundTelemetry.startScanning();

final sub = BearoundTelemetry.beaconsStream.listen((beacons) {
  for (final b in beacons) {
    print('${b.major}.${b.minor}: ${b.battery} mV, ${b.temperature} °C, '
        '${b.movements} movements, fw ${b.firmware}');
  }
});

// later
await sub.cancel();
await BearoundTelemetry.stopScanning();
```

## API

| Member | Returns | Notes |
|---|---|---|
| `configure(businessToken:)` | `Future<bool>` | `true` = companion handoff happened |
| `requestPermissions()` | `Future<void>` | `BLUETOOTH_SCAN` on Android 12+, never location |
| `startScanning()` | `Future<void>` | Foreground + background collection |
| `stopScanning()` | `Future<void>` | |
| `deviceId` | `Future<String?>` | Tracking SDK's id after handoff |
| `beaconsStream` | `Stream<List<TelemetryBeacon>>` | Live readings |

`TelemetryBeacon`: `uuid`, `major`, `minor`, `rssi`, `lastSeen`, `battery?`, `temperature?`, `movements?`, `firmware?`.

## Example

[`example/`](example/) is a complete telemetry dashboard (collection toggle, live per-beacon cards) — device-validated against production beacons.

## License

MIT © Bearound
