## 0.1.0

* Initial release: Flutter wrapper for the Bearound Telemetry Android SDK (native `v0.1.3`).
* Beacon-hardware telemetry only (battery, temperature, movement, firmware, signal) — no tracking, no location permission (`BLUETOOTH_SCAN` with `neverForLocation`).
* Automatic companion handoff when the Bearound tracking SDK is present in the same app (shared business token and device id).
* `configure`, `requestPermissions`, `startScanning`, `stopScanning`, `deviceId`, `beaconsStream`.
* Example app with a live telemetry dashboard (Android only).
