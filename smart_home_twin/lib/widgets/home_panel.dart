import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class HomePanel extends StatelessWidget {
  const HomePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.status;

    Widget tile(String title, bool value, void Function(bool) onChanged, IconData icon) {
      return SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        title: Text(title),
        secondary: Icon(icon),
        dense: true,
        visualDensity: VisualDensity.compact,
      );
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const ListTile(
              title: Text('Elhood', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              subtitle: Text('Home status'),
              leading: Icon(Icons.home),
            ),
            const Divider(),
            // Power summary (matches the video content)
            Card(
              child: ListTile(
                leading: const Icon(Icons.bolt),
                title: Text("Yesterday's power usage: ${state.yesterdayKwh.toStringAsFixed(1)} kWh"),
                subtitle: Text("Yesterday's power cost: ₹${state.yesterdayCost.toStringAsFixed(2)}"),
              ),
            ),
            const SizedBox(height: 6),
            Card(
              child: ListTile(
                leading: const Icon(Icons.today),
                title: Text("Today so far: ${state.kwhDay.toStringAsFixed(2)} kWh"),
                subtitle: Text("Cost: ₹${state.costDay.toStringAsFixed(2)}"),
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 4),
              child: Text('Our House', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            Card(
              child: Column(
                children: [
                  tile('In Bed', s.inBed, (v) => context.read<AppState>().toggleStatus('inBed', v), Icons.bed),
                  tile('Someone Cooking', s.cooking, (v) => context.read<AppState>().toggleStatus('cooking', v), Icons.soup_kitchen),
                  tile('Someone Showering', s.showering, (v) => context.read<AppState>().toggleStatus('showering', v), Icons.shower),
                  tile('Someone Washing Clothes', s.washing, (v) => context.read<AppState>().toggleStatus('washing', v), Icons.local_laundry_service),
                  tile('House Occupied', s.houseOccupied, (v) => context.read<AppState>().toggleStatus('house', v), Icons.people),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
