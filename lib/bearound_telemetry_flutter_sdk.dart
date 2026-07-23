/// Bearound Telemetry SDK for Flutter — beacon-hardware telemetry (battery,
/// temperature, movement, firmware, signal) with NO location permission.
/// Android only. This SDK does not track people.
library;

import 'dart:async';

import 'package:flutter/services.dart';

/// One telemetry reading from a Bearound beacon — hardware health only.
class TelemetryBeacon {
  const TelemetryBeacon({
    required this.uuid,
    required this.major,
    required this.minor,
    required this.rssi,
    required this.lastSeen,
    this.battery,
    this.temperature,
    this.movements,
    this.firmware,
  });

  final String uuid;
  final int major;
  final int minor;

  /// Signal strength of the encounter, in dBm.
  final int rssi;

  /// When this beacon was last seen.
  final DateTime lastSeen;

  /// Battery reading advertised by the beacon (unit is firmware-defined, mV).
  final int? battery;

  /// Temperature in °C from the beacon's onboard sensor.
  final int? temperature;

  /// Accelerometer movement counter.
  final int? movements;

  /// Beacon firmware version.
  final String? firmware;

  factory TelemetryBeacon.fromMap(Map<dynamic, dynamic> map) => TelemetryBeacon(
        uuid: map['uuid'] as String? ?? '',
        major: (map['major'] as num?)?.toInt() ?? 0,
        minor: (map['minor'] as num?)?.toInt() ?? 0,
        rssi: (map['rssi'] as num?)?.toInt() ?? 0,
        lastSeen: DateTime.fromMillisecondsSinceEpoch(
          (map['lastSeen'] as num?)?.toInt() ?? 0,
        ),
        battery: (map['battery'] as num?)?.toInt(),
        temperature: (map['temperature'] as num?)?.toInt(),
        movements: (map['movements'] as num?)?.toInt(),
        firmware: map['firmware'] as String?,
      );

  @override
  String toString() =>
      'TelemetryBeacon($major.$minor rssi=$rssi battery=$battery temp=$temperature)';
}

/// Bearound Telemetry — static facade, mirroring the Bearound SDK plugin's shape.
class BearoundTelemetry {
  BearoundTelemetry._();

  static const MethodChannel _channel =
      MethodChannel('bearound_telemetry_flutter_sdk');
  static const EventChannel _beaconsChannel =
      EventChannel('bearound_telemetry_flutter_sdk/beacons');

  static Stream<List<TelemetryBeacon>>? _beaconsStream;

  /// Configures the SDK with your Bearound business token.
  ///
  /// Returns `true` when the **companion handoff** happened: the Bearound
  /// tracking SDK is present in this app and already configured, so credentials
  /// and the device id were taken from its instance (both SDKs report as the
  /// same device) and [businessToken] was not needed. Returns `false` on a
  /// standalone configure using [businessToken].
  static Future<bool> configure({required String businessToken}) async =>
      await _channel.invokeMethod<bool>(
        'configure',
        {'businessToken': businessToken},
      ) ??
      false;

  /// Requests the "Nearby devices" runtime permission on Android 12+.
  /// No location permission exists in this SDK — none is ever requested.
  static Future<void> requestPermissions() =>
      _channel.invokeMethod('requestPermissions');

  /// Starts telemetry collection (foreground + background).
  static Future<void> startScanning() => _channel.invokeMethod('startScanning');

  /// Stops telemetry collection.
  static Future<void> stopScanning() => _channel.invokeMethod('stopScanning');

  /// Effective device id — the tracking SDK's id after a companion handoff,
  /// otherwise self-generated.
  static Future<String?> get deviceId =>
      _channel.invokeMethod<String>('getDeviceId');

  /// Live telemetry readings, one list per scan delivery.
  static Stream<List<TelemetryBeacon>> get beaconsStream =>
      _beaconsStream ??= _beaconsChannel.receiveBroadcastStream().map(
            (event) => (event as List)
                .map((e) => TelemetryBeacon.fromMap(e as Map))
                .toList(),
          );
}
