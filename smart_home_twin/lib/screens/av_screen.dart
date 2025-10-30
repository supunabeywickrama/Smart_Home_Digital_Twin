import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class AVScreen extends StatelessWidget {
  const AVScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tv = state.devices['living.tv']!;
    final sp = state.devices['living.spk']!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DeviceCard(dev: tv, icon: Icons.tv),
        const SizedBox(height: 10),
        _DeviceCard(dev: sp, icon: Icons.speaker),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.dev, required this.icon});
  final Device dev; final IconData icon;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(icon, size: 22),
              const SizedBox(width: 8),
              Text(dev.name, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              Text('• ${dev.roomId}', style: const TextStyle(color: Colors.black54)),
            ]),
            Switch(value: dev.state.on, onChanged: (v) => context.read<AppState>().toggleDevice(dev.id, on: v)),
          ]),
          const SizedBox(height: 8),
          const Text('Level / Volume'),
          Slider(value: dev.state.level, onChanged: (v) => context.read<AppState>().setLevel(dev.id, v)),
        ]),
      ),
    );
  }
}
