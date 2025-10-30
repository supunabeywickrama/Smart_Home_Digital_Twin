import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  bool _hasSlider(Device d) =>
      d.type == DeviceType.light ||
      d.type == DeviceType.fan ||
      d.type == DeviceType.speaker ||
      d.type == DeviceType.thermostat; // AC level

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final devs = state.devices.values.toList()
      ..sort((a, b) => a.roomId.compareTo(b.roomId));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: devs.length,
      itemBuilder: (c, i) {
        final d = devs[i];
        final w = state.devicePowerW(d);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // LEFT: title + meta + (optional) slider
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${d.name} • ${d.roomId}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${d.type.name}  |  Rated ${d.wattRated.round()}W',
                          style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      if (_hasSlider(d)) ...[
                        const SizedBox(height: 6),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape:
                                const RoundSliderThumbShape(enabledThumbRadius: 8),
                          ),
                          child: Slider(
                            value: d.state.level,
                            onChanged: (v) =>
                                context.read<AppState>().setLevel(d.id, v),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // RIGHT: watts + switch (constrained so it never overflows)
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 80),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${w.toStringAsFixed(0)} W',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Switch(
                        value: d.state.on,
                        onChanged: (v) =>
                            context.read<AppState>().toggleDevice(d.id, on: v),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
