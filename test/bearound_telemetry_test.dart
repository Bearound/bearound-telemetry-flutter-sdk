import 'package:flutter_test/flutter_test.dart';
import 'package:bearound_telemetry_flutter_sdk/bearound_telemetry_flutter_sdk.dart';

void main() {
  test('TelemetryBeacon.fromMap parses a full reading', () {
    final b = TelemetryBeacon.fromMap({
      'uuid': 'E25B8D3C-947A-452F-A13F-589CB706D2E5',
      'major': 0,
      'minor': 200,
      'rssi': -45,
      'lastSeen': 1753000000000,
      'battery': 3216,
      'temperature': 25,
      'movements': 125,
      'firmware': '5',
    });
    expect(b.minor, 200);
    expect(b.battery, 3216);
    expect(b.temperature, 25);
    expect(b.movements, 125);
    expect(b.firmware, '5');
    expect(b.lastSeen.millisecondsSinceEpoch, 1753000000000);
  });

  test('TelemetryBeacon.fromMap tolerates missing telemetry fields', () {
    final b = TelemetryBeacon.fromMap(
        {'uuid': 'x', 'major': 0, 'minor': 82, 'rssi': -60, 'lastSeen': 0});
    expect(b.minor, 82);
    expect(b.battery, isNull);
    expect(b.firmware, isNull);
  });
}
