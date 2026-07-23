import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bearound_telemetry_flutter_sdk/bearound_telemetry_flutter_sdk.dart';

/// Bearound Telemetry — Flutter sample. Shows EXCLUSIVELY beacon-hardware
/// telemetry, in the same visual family as the Bearound sample apps.
void main() => runApp(const TelemetryExampleApp());

const _bearoundBlue = Color(0xFF0066CC);

// Public test token (same fallback as the native samples). Real apps load it
// from secure config — never hardcode production tokens.
const _businessToken = 'ee2ec9c46d2b2ad99bddcdd0afe224e6';

class TelemetryExampleApp extends StatelessWidget {
  const TelemetryExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Bearound Telemetry',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: _bearoundBlue),
          useMaterial3: true,
        ),
        home: const TelemetryScreen(),
      );
}

class TelemetryScreen extends StatefulWidget {
  const TelemetryScreen({super.key});

  @override
  State<TelemetryScreen> createState() => _TelemetryScreenState();
}

class _TelemetryScreenState extends State<TelemetryScreen> {
  final Map<String, TelemetryBeacon> _beacons = {};
  StreamSubscription<List<TelemetryBeacon>>? _sub;
  bool _collecting = false;
  bool _companionHandoff = false;

  @override
  void initState() {
    super.initState();
    _sub = BearoundTelemetry.beaconsStream.listen((list) {
      setState(() {
        for (final b in list) {
          _beacons['${b.major}/${b.minor}'] = b;
        }
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    await BearoundTelemetry.requestPermissions();
    final handoff =
        await BearoundTelemetry.configure(businessToken: _businessToken);
    await BearoundTelemetry.startScanning();
    setState(() {
      _collecting = true;
      _companionHandoff = handoff;
    });
  }

  Future<void> _stop() async {
    await BearoundTelemetry.stopScanning();
    setState(() => _collecting = false);
  }

  @override
  Widget build(BuildContext context) {
    final beacons = _beacons.values.toList()
      ..sort((a, b) => a.minor.compareTo(b.minor));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bearound Telemetry',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.monitor_heart,
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Saúde da frota de beacons: bateria, temperatura, '
                      'movimento e sinal. Este SDK não faz rastreio de pessoas.',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Coleta',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      Text(
                        _collecting ? 'Coletando' : 'Parada',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _collecting
                              ? _bearoundBlue
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  if (_collecting)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _companionHandoff
                            ? 'Modo companion (handoff do rastreio)'
                            : 'Modo standalone',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _collecting ? null : _start,
                          child: const Text('Iniciar coleta'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _collecting ? _stop : null,
                          child: const Text('Parar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Telemetria dos beacons (${beacons.length})',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (beacons.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Nenhum beacon detectado ainda.')),
              ),
            ),
          for (final b in beacons) _BeaconCard(beacon: b),
        ],
      ),
    );
  }
}

class _BeaconCard extends StatelessWidget {
  const _BeaconCard({required this.beacon});

  final TelemetryBeacon beacon;

  @override
  Widget build(BuildContext context) {
    final age = DateTime.now().difference(beacon.lastSeen).inSeconds;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.sensors, color: _bearoundBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Beacon ${beacon.major}.${beacon.minor}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Text('há ${age}s',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Metric(
                    icon: Icons.battery_full,
                    value: beacon.battery != null ? '${beacon.battery} mV' : '—',
                    label: 'Bateria'),
                _Metric(
                    icon: Icons.thermostat,
                    value: beacon.temperature != null
                        ? '${beacon.temperature} °C'
                        : '—',
                    label: 'Temperatura'),
                _Metric(
                    icon: Icons.vibration,
                    value: beacon.movements?.toString() ?? '—',
                    label: 'Movimentos'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Metric(
                    icon: Icons.bluetooth,
                    value: '${beacon.rssi} dB',
                    label: 'Sinal'),
                _Metric(
                    icon: Icons.memory,
                    value: beacon.firmware ?? '—',
                    label: 'Firmware'),
                const SizedBox(width: 64),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, size: 20, color: _bearoundBlue),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: Theme.of(context).colorScheme.outline)),
        ],
      );
}
