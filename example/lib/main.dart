import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bearound_telemetry_flutter_sdk/bearound_telemetry_flutter_sdk.dart';

/// Bearound Telemetry — Flutter sample. Shows EXCLUSIVELY beacon-hardware
/// telemetry, in the same visual family as the Bearound sample apps.
/// Includes the BearoundScan-style detection log (detailed + per-minute counts)
/// and beacon pinning (tap a card to keep it on top).
void main() => runApp(const TelemetryExampleApp());

const _bearoundBlue = Color(0xFF0066CC);

// Public test token (same fallback as the native samples). Real apps load it
// from secure config — never hardcode production tokens.
const _businessToken = 'ee2ec9c46d2b2ad99bddcdd0afe224e6';

/// One observed detection (a fresh advertisement processed by the SDK).
class DetectionLogEntry {
  DetectionLogEntry({
    required this.timestamp,
    required this.major,
    required this.minor,
    required this.rssi,
    required this.source,
    required this.isBackground,
  });

  final DateTime timestamp;
  final int major;
  final int minor;
  final int rssi;

  /// "BEAD" when the sensor payload was captured, "iBeacon" for identity-only.
  final String source;
  final bool isBackground;
}

class TelemetryExampleApp extends StatelessWidget {
  const TelemetryExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Bearound Telemetry',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: _bearoundBlue),
          useMaterial3: true,
        ),
        home: const RootScreen(),
      );
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> with WidgetsBindingObserver {
  static const _maxLogEntries = 500;

  final Map<String, TelemetryBeacon> _beacons = {};
  final Map<String, DateTime> _lastLoggedAt = {};
  final List<DetectionLogEntry> _foregroundLog = [];
  final List<DetectionLogEntry> _backgroundLog = [];
  final Set<String> _pinned = {};

  StreamSubscription<List<TelemetryBeacon>>? _sub;
  bool _collecting = false;
  bool _companionHandoff = false;
  bool _isBackground = false;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = BearoundTelemetry.beaconsStream.listen((list) {
      setState(() {
        // MIRROR the SDK's list: expired beacons are already removed from the
        // emission (including an empty list) — upsert-only kept ghosts around.
        final currentKeys = list.map((b) => '${b.major}/${b.minor}').toSet();
        _beacons.removeWhere((key, _) => !currentKeys.contains(key));
        for (final b in list) {
          final key = '${b.major}/${b.minor}';
          _beacons[key] = b;
          // Log only FRESH observations: the stream re-emits the whole list on
          // every delivery, so an entry is recorded only when lastSeen advanced.
          if (_lastLoggedAt[key] != b.lastSeen) {
            _lastLoggedAt[key] = b.lastSeen;
            final entry = DetectionLogEntry(
              timestamp: DateTime.now(),
              major: b.major,
              minor: b.minor,
              rssi: b.rssi,
              source: b.battery != null ? 'BEAD' : 'iBeacon',
              isBackground: _isBackground,
            );
            final target = _isBackground ? _backgroundLog : _foregroundLog;
            target.insert(0, entry);
            if (target.length > _maxLogEntries) target.removeRange(_maxLogEntries, target.length);
          }
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isBackground = state != AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  void _togglePin(String key) {
    setState(() {
      if (!_pinned.add(key)) _pinned.remove(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    final beacons = _beacons.values.toList()
      ..sort((a, b) {
        final ap = _pinned.contains('${a.major}/${a.minor}') ? 0 : 1;
        final bp = _pinned.contains('${b.major}/${b.minor}') ? 0 : 1;
        if (ap != bp) return ap - bp;
        return a.minor.compareTo(b.minor);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bearound Telemetry',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.sensors), label: 'Beacons'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Log'),
        ],
      ),
      body: _tab == 0
          ? _BeaconsPage(
              beacons: beacons,
              pinned: _pinned,
              collecting: _collecting,
              companionHandoff: _companionHandoff,
              onStart: _start,
              onStop: _stop,
              onTogglePin: _togglePin,
            )
          : _LogPage(
              foregroundLog: _foregroundLog,
              backgroundLog: _backgroundLog,
              onClear: () => setState(() {
                _foregroundLog.clear();
                _backgroundLog.clear();
              }),
            ),
    );
  }
}

// =============================================================================
// Beacons tab
// =============================================================================

class _BeaconsPage extends StatelessWidget {
  const _BeaconsPage({
    required this.beacons,
    required this.pinned,
    required this.collecting,
    required this.companionHandoff,
    required this.onStart,
    required this.onStop,
    required this.onTogglePin,
  });

  final List<TelemetryBeacon> beacons;
  final Set<String> pinned;
  final bool collecting;
  final bool companionHandoff;
  final Future<void> Function() onStart;
  final Future<void> Function() onStop;
  final void Function(String key) onTogglePin;

  @override
  Widget build(BuildContext context) {
    return ListView(
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
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                      collecting ? 'Coletando' : 'Parada',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: collecting
                            ? _bearoundBlue
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                if (collecting)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      companionHandoff
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
                        onPressed: collecting ? null : onStart,
                        child: const Text('Iniciar coleta'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: collecting ? onStop : null,
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (beacons.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Nenhum beacon detectado ainda.')),
            ),
          ),
        for (final b in beacons)
          _BeaconCard(
            beacon: b,
            isPinned: pinned.contains('${b.major}/${b.minor}'),
            onTap: () => onTogglePin('${b.major}/${b.minor}'),
          ),
      ],
    );
  }
}

class _BeaconCard extends StatelessWidget {
  const _BeaconCard({
    required this.beacon,
    required this.isPinned,
    required this.onTap,
  });

  final TelemetryBeacon beacon;
  final bool isPinned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final age = DateTime.now().difference(beacon.lastSeen).inSeconds;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.sensors, color: _bearoundBlue),
                  const SizedBox(width: 8),
                  Text('Beacon ${beacon.major}.${beacon.minor}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  if (isPinned) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.push_pin,
                        size: 16, color: _bearoundBlue),
                  ],
                  const Spacer(),
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
                      value:
                          beacon.battery != null ? '${beacon.battery} mV' : '—',
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

// =============================================================================
// Log tab — detailed entries + per-minute detection counts
// =============================================================================

enum _LogViewMode { detail, grouped }

enum _LogModeFilter { all, fg, bg }

enum _LogTypeFilter { all, bead, ibeacon }

class _MinuteGroup {
  _MinuteGroup(this.date, this.total, this.fg, this.bg, this.uniqueBeacons);

  final DateTime date;
  final int total;
  final int fg;
  final int bg;
  final int uniqueBeacons;
}

class _LogPage extends StatefulWidget {
  const _LogPage({
    required this.foregroundLog,
    required this.backgroundLog,
    required this.onClear,
  });

  final List<DetectionLogEntry> foregroundLog;
  final List<DetectionLogEntry> backgroundLog;
  final VoidCallback onClear;

  @override
  State<_LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<_LogPage> {
  _LogViewMode _view = _LogViewMode.detail;
  _LogModeFilter _mode = _LogModeFilter.all;
  _LogTypeFilter _type = _LogTypeFilter.all;

  String _two(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final source = switch (_mode) {
      _LogModeFilter.all => [...widget.foregroundLog, ...widget.backgroundLog]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
      _LogModeFilter.fg => widget.foregroundLog,
      _LogModeFilter.bg => widget.backgroundLog,
    };
    final filtered = source.where((e) {
      return switch (_type) {
        _LogTypeFilter.all => true,
        _LogTypeFilter.bead => e.source == 'BEAD',
        _LogTypeFilter.ibeacon => e.source == 'iBeacon',
      };
    }).toList();

    final groups = <int, List<DetectionLogEntry>>{};
    for (final e in filtered) {
      final t = e.timestamp;
      final minute =
          DateTime(t.year, t.month, t.day, t.hour, t.minute).millisecondsSinceEpoch;
      groups.putIfAbsent(minute, () => []).add(e);
    }
    final minuteGroups = groups.entries
        .map((g) => _MinuteGroup(
              DateTime.fromMillisecondsSinceEpoch(g.key),
              g.value.length,
              g.value.where((e) => !e.isBackground).length,
              g.value.where((e) => e.isBackground).length,
              g.value.map((e) => '${e.major}.${e.minor}').toSet().length,
            ))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              SegmentedButton<_LogViewMode>(
                segments: const [
                  ButtonSegment(
                      value: _LogViewMode.detail, label: Text('Detalhado')),
                  ButtonSegment(
                      value: _LogViewMode.grouped, label: Text('Por Minuto')),
                ],
                selected: {_view},
                onSelectionChanged: (s) => setState(() => _view = s.first),
              ),
              const SizedBox(height: 8),
              SegmentedButton<_LogModeFilter>(
                segments: const [
                  ButtonSegment(value: _LogModeFilter.all, label: Text('Tudo')),
                  ButtonSegment(value: _LogModeFilter.fg, label: Text('FG')),
                  ButtonSegment(value: _LogModeFilter.bg, label: Text('BG')),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
              const SizedBox(height: 8),
              SegmentedButton<_LogTypeFilter>(
                segments: const [
                  ButtonSegment(value: _LogTypeFilter.all, label: Text('Tudo')),
                  ButtonSegment(
                      value: _LogTypeFilter.bead, label: Text('BEAD')),
                  ButtonSegment(
                      value: _LogTypeFilter.ibeacon, label: Text('iBeacon')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'FG:${widget.foregroundLog.length} '
                    'BG:${widget.backgroundLog.length}',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: widget.foregroundLog.isEmpty &&
                            widget.backgroundLog.isEmpty
                        ? null
                        : widget.onClear,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Limpar', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list_alt,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 8),
                      Text('Nenhuma detecção registrada',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.outline)),
                    ],
                  ),
                )
              : _view == _LogViewMode.grouped
                  ? ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: minuteGroups.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final g = minuteGroups[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${_two(g.date.day)}/${_two(g.date.month)} '
                                    '${_two(g.date.hour)}:${_two(g.date.minute)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  Text('${g.total} detecções',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (g.fg > 0)
                                    _Badge('FG ${g.fg}',
                                        const Color(0xFF4CAF50)),
                                  if (g.bg > 0) ...[
                                    const SizedBox(width: 8),
                                    _Badge('BG ${g.bg}',
                                        const Color(0xFFFF9800)),
                                  ],
                                  const Spacer(),
                                  Text(
                                    '${g.uniqueBeacons} beacon'
                                    '${g.uniqueBeacons == 1 ? '' : 's'}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final e = filtered[i];
                        final t = e.timestamp;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('${e.major}.${e.minor}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const Spacer(),
                                  Text(
                                    '${_two(t.day)}/${_two(t.month)} '
                                    '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text('RSSI: ${e.rssi}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline)),
                                  const SizedBox(width: 6),
                                  _Badge(
                                      e.source,
                                      e.source == 'BEAD'
                                          ? const Color(0xFF9C27B0)
                                          : const Color(0xFF3F51B5)),
                                  const SizedBox(width: 6),
                                  _Badge(
                                      e.isBackground ? 'BG' : 'FG',
                                      e.isBackground
                                          ? const Color(0xFFFF9800)
                                          : const Color(0xFF4CAF50)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w500)),
      );
}
