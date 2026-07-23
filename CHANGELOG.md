## 0.2.0

* Native SDK `v0.1.3` → `v0.2.0`: continuous scan architecture (one hardware-managed registration per precision, no scan-start-quota starvation), foreground always LOW_LATENCY, weak-receiver SoC compensation, zombie-scan self-heal. Bench realme C61: 7-10× more readings, max gaps from ~60s down to 10-14s.
* `configure(scanPrecision:)` — `'high'`/`'medium'`/`'low'` prices the background radio duty and sync cadence.
* Example: detection log tab (detailed + per-minute observed counts, FG/BG and frame filters), beacon pinning, ghost-beacon fix (list now mirrors SDK emissions).

## 0.1.0

* Initial release: Flutter wrapper for the Bearound Telemetry Android SDK (native `v0.1.3`).
* Beacon-hardware telemetry only (battery, temperature, movement, firmware, signal) — no tracking, no location permission (`BLUETOOTH_SCAN` with `neverForLocation`).
* Automatic companion handoff when the Bearound tracking SDK is present in the same app (shared business token and device id).
* `configure`, `requestPermissions`, `startScanning`, `stopScanning`, `deviceId`, `beaconsStream`.
* Example app with a live telemetry dashboard (Android only).
