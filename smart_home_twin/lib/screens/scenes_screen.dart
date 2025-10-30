import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models.dart';

class ScenesScreen extends StatelessWidget {
  const ScenesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: state.scenes.map((s) => _SceneCard(scene: s)).toList(),
    );
  }
}

class _SceneCard extends StatelessWidget {
  const _SceneCard({required this.scene});
  final Scene scene;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Card(
      child: ListTile(
        title: Text(scene.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${scene.actions.length} actions'),
        trailing: FilledButton(
          onPressed: () => state.runScene(scene.id),
          child: const Text('Run'),
        ),
      ),
    );
  }
}
