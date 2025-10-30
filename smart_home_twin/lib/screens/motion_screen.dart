import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class MotionScreen extends StatelessWidget {
  const MotionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final events = state.motion;

    String roomName(String id) => state.rooms[id]?.name ?? id;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: events.length,
      itemBuilder: (c, i) {
        final e = events[i];
        final when = TimeOfDay.fromDateTime(e.ts).format(context);
        return ListTile(
          leading: Icon(e.entered ? Icons.sensor_occupied : Icons.sensor_door, color: e.entered ? Colors.green : Colors.orange),
          title: Text('${roomName(e.roomId)} • ${e.entered ? "Occupied" : "Vacant"}'),
          subtitle: Text(when),
        );
      },
    );
  }
}
