import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';

class TwinScreen extends StatelessWidget {
  const TwinScreen({super.key});

  // Normalized overlay positions (0..1) for your PNG
  static const _marks = {
    'living':  Offset(0.18, 0.35),
    'kitchen': Offset(0.40, 0.32),
    'bath':    Offset(0.56, 0.33),
    'bed':     Offset(0.80, 0.33),
  };

  bool _hasSlider(Device d) =>
      d.type == DeviceType.light ||
      d.type == DeviceType.fan ||
      d.type == DeviceType.speaker ||
      d.type == DeviceType.thermostat;

  IconData _iconForType(DeviceType t) {
    switch (t) {
      case DeviceType.light:       return Icons.lightbulb;
      case DeviceType.fan:         return Icons.air;
      case DeviceType.tv:          return Icons.tv;
      case DeviceType.speaker:     return Icons.speaker;
      case DeviceType.thermostat:  return Icons.ac_unit;
      case DeviceType.plug:        return Icons.power;
    }
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'lightbulb': return Icons.lightbulb;
      case 'air':       return Icons.air;
      case 'tv':        return Icons.tv;
      case 'speaker':   return Icons.speaker;
      case 'ac_unit':   return Icons.ac_unit;
      case 'power':     return Icons.power;
      default:          return Icons.notifications;
    }
  }

  String _ago(DateTime ts) {
    final d = DateTime.now().difference(ts);
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    Widget tempBadge(double t) => Container(
      width: 50, height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.95),
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
      ),
      alignment: Alignment.center,
      child: Text('${t.toStringAsFixed(0)}°C',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
    );

    Widget motionDot(bool on) => Container(
      width: 18, height: 18,
      decoration: BoxDecoration(
        color: on ? Colors.green : Colors.grey.shade400,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.black26)],
      ),
    );

    // --- HEADER SUMMARY -------------------------------------------------------
    Widget header() {
      final double powerW = state.devices.values
          .fold(0.0, (s, d) => s + state.devicePowerW(d));

      Widget stat(String title, String big, String sub) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 6),
                Text(big, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                const SizedBox(height: 2),
                Text(sub, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ),
      );

      return Row(children: [
        stat('Power now', '${powerW.toStringAsFixed(0)} W', 'Live total'),
        const SizedBox(width: 10),
        stat('Today', '${state.kwhDay.toStringAsFixed(2)} kWh', '₹${state.costDay.toStringAsFixed(2)}'),
      ]);
    }

    // --- FLOORPLAN WITH OVERLAYS ---------------------------------------------
    Widget floorplan() => AspectRatio(
      aspectRatio: 3840/2165,
      child: LayoutBuilder(
        builder: (context, bc) {
          final w = bc.maxWidth, h = bc.maxHeight;
          return Stack(children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset('assets/floorplan_isometric.png', fit: BoxFit.cover),
              ),
            ),
            for (final e in _marks.entries) ...[
              Positioned(
                left: e.value.dx * w - 25,
                top:  e.value.dy * h - 25,
                child: tempBadge(state.rooms[e.key]!.temp),
              ),
              Positioned(
                left: e.value.dx * w + 24,
                top:  e.value.dy * h - 24,
                child: motionDot(state.rooms[e.key]!.occupied),
              ),
            ],
          ]);
        },
      ),
    );

    // --- DEVICE GRID (compact) -----------------------------------------------
    final devices = state.devices.values.toList()
      ..sort((a,b)=>a.roomId.compareTo(b.roomId));

    Widget deviceCard(Device d) {
      final watts = state.devicePowerW(d).toStringAsFixed(0);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(_iconForType(d.type), size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                // FIX: Switch has no `visualDensity` → use shrinkWrap + scale
                Transform.scale(
                  scale: 0.9,
                  child: Switch.adaptive(
                    value: d.state.on,
                    onChanged: (v) => context.read<AppState>().toggleDevice(d.id, on: v),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ]),
              Text('${d.roomId} • ${d.wattRated.round()}W rated',
                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
              if (_hasSlider(d)) ...[
                const SizedBox(height: 6),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  ),
                  child: Slider(
                    value: d.state.level,
                    onChanged: (v) => context.read<AppState>().setLevel(d.id, v),
                  ),
                ),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: Text('$watts W', style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      );
    }

    // --- RECENT ACTIVITY (alerts) --------------------------------------------
    Widget alertsList() {
      final items = state.alerts.take(8).toList();
      if (items.isEmpty) return const SizedBox.shrink();
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text('Recent activity', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              for (final a in items)
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: Icon(_iconFromName(a.icon), color: Colors.blue),
                  title: Text(a.msg),
                  subtitle: Text(_ago(a.ts)),
                ),
            ],
          ),
        ),
      );
    }

    // --- PAGE LAYOUT ----------------------------------------------------------
    return Container(
      color: const Color(0xFFF3F6FA),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          header(),
          const SizedBox(height: 12),
          floorplan(),
          const SizedBox(height: 12),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text('All devices', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 1.65, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: devices.length,
            itemBuilder: (_, i) => deviceCard(devices[i]),
          ),

          const SizedBox(height: 12),
          alertsList(),
        ],
      ),
    );
  }
}
