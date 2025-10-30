import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import '../app_state.dart';

class TwinScreen extends StatefulWidget {
  const TwinScreen({super.key});
  @override State<TwinScreen> createState() => _TwinScreenState();
}

class _TwinScreenState extends State<TwinScreen> {
  Map<String, dynamic>? hotspots;
  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/hotspots_default.json').then((s) {
      setState(() => hotspots = json.decode(s));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (hotspots == null) return const Center(child: CircularProgressIndicator());

    Widget pos(String key, Widget child, Size sz, {double dx=0, double dy=0}) {
      final hx = (hotspots![key]['nx'] as num).toDouble();
      final hy = (hotspots![key]['ny'] as num).toDouble();
      return Positioned(left: hx*sz.width + dx, top: hy*sz.height + dy, child: child);
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: Center(
        child: AspectRatio(
          aspectRatio: 3840/2165, // image ratio
          child: LayoutBuilder(
            builder: (context, bc) {
              final sz = Size(bc.maxWidth, bc.maxHeight);
              return Stack(children: [
                Positioned.fill(
                  child: Image.asset('assets/floorplan_isometric.png', fit: BoxFit.contain),
                ),
                // temps from state.rooms
                pos('kitchen_temp', _temp(state.rooms['kitchen']!.temp), sz, dx:-28, dy:-28),
                pos('bath_temp',    _temp(state.rooms['bath']!.temp),    sz, dx:-28, dy:-28),
                pos('bedroom_temp', _temp(state.rooms['bed']!.temp),     sz, dx:-28, dy:-28),
                // motion icons (demo)
                pos('living_motion', _motion(state.rooms['living']!.occupied), sz, dx:-14, dy:-14),
                pos('hall_motion',   _motion(true), sz, dx:-14, dy:-14),
              ]);
            },
          ),
        ),
      ),
    );
  }

  Widget _temp(double t) => Container(
    width: 56, height: 56,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.92),
      shape: BoxShape.circle,
      boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
    ),
    alignment: Alignment.center,
    child: Text('${t.toStringAsFixed(0)}°C',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
  );

  Widget _motion(bool active) => Container(
    width: 28, height: 28,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: active ? Colors.green : Colors.blue.shade700, width: 2),
      boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
    ),
    child: Icon(Icons.directions_run, size: 16, color: active ? Colors.green : Colors.blue),
  );
}
