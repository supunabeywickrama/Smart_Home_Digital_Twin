import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class ClimateScreen extends StatelessWidget {
  const ClimateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final rooms = state.rooms.values.toList();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: rooms.length,
      itemBuilder: (c, i) {
        final r = rooms[i];
        final isBed = r.id == 'bed';
        final ac = isBed ? state.devices['bed.ac'] : null;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Tile(label: 'Now', value: '${r.temp.toStringAsFixed(1)}°C'),
                    const SizedBox(width: 12),
                    _Tile(label: 'Target', value: '${r.setpoint.toStringAsFixed(0)}°C'),
                    const SizedBox(width: 12),
                    _Tile(label: 'Hold', value: r.hold ? 'On' : 'Off'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Setpoint'),
                    Expanded(
                      child: Slider(
                        value: r.setpoint.clamp(16, 30),
                        min: 16, max: 30, divisions: 14,
                        label: '${r.setpoint.toStringAsFixed(0)}°C',
                        onChanged: (v) => context.read<AppState>().setSetpoint(r.id, v),
                      ),
                    ),
                    Switch(
                      value: r.hold,
                      onChanged: (v) => context.read<AppState>().setHold(r.id, v),
                    ),
                  ],
                ),
                if (isBed && ac != null) ...[
                  const SizedBox(height: 6),
                  const Text('Bedroom AC Power'),
                  Slider(
                    value: ac.state.level,
                    onChanged: (v) => context.read<AppState>().setLevel(ac.id, v),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ac.state.on ? 'On' : 'Off'),
                      Text('${(ac.state.level*100).round()}%'),
                      Switch(value: ac.state.on, onChanged: (v) => context.read<AppState>().toggleDevice(ac.id, on: v)),
                    ],
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}
