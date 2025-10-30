import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import '../app_state.dart';
import '../models.dart';

class LightsScreen extends StatelessWidget {
  const LightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final rooms = state.rooms.values.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: rooms.length,
      itemBuilder: (c, i) {
        final r = rooms[i];
        final roomDevices = r.deviceIds
          .map((id) => state.devices[id]!)
          .where((d) => d.type == DeviceType.light || d.type == DeviceType.fan)
          .toList();
        if (roomDevices.isEmpty) return const SizedBox.shrink();

        return Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 18, runSpacing: 18,
                  children: roomDevices.map((d) => _DeviceDimmer(d.id)).toList(),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DeviceDimmer extends StatelessWidget {
  const _DeviceDimmer(this.deviceId);
  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final d = state.devices[deviceId]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120, height: 120,
          child: SleekCircularSlider(
            min: 0, max: 100,
            initialValue: d.state.level * 100,
            onChange: (v) => state.setLevel(deviceId, v/100),
            appearance: CircularSliderAppearance(customColors: CustomSliderColors(
              dotColor: Colors.white, trackColor: Colors.black12,
              progressBarColor: d.state.on ? Colors.blue : Colors.grey)),
          ),
        ),
        const SizedBox(height: 6),
        Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        Switch(
          value: d.state.on,
          onChanged: (v) => state.toggleDevice(deviceId, on: v),
        ),
      ],
    );
  }
}
