import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class EnergyScreen extends StatelessWidget {
  const EnergyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final points = state.energy;
    final spots = <FlSpot>[];
    final now = DateTime.now();

    for (final p in points.takeLast(600)) {
      final dt = now.difference(p.ts).inSeconds.toDouble();
      spots.add(FlSpot(-dt / 60.0, p.powerW)); // minutes ago, power W
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatRow(todayCost: state.costDay, todayKwh: state.kwhDay, yKwh: state.yesterdayKwh, yCost: state.yesterdayCost),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              minY: 0,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                  return Text('${(-v).toStringAsFixed(0)}m', style: const TextStyle(fontSize: 10));
                })),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true, barWidth: 3,
                  spots: spots,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

extension _TakeLast<T> on List<T> {
  Iterable<T> takeLast(int n) => skip(length > n ? length - n : 0);
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.todayCost, required this.todayKwh, required this.yKwh, required this.yCost});
  final double todayCost, todayKwh, yKwh, yCost;

  @override
  Widget build(BuildContext context) {
    TextStyle h = const TextStyle(fontWeight: FontWeight.w800, fontSize: 22);
    TextStyle s = const TextStyle(color: Colors.black54);
    return Row(
      children: [
        Expanded(child: _CardStat(title: 'Today cost',  big: '₹${todayCost.toStringAsFixed(2)}', sub: '${todayKwh.toStringAsFixed(2)} kWh', h: h, s: s)),
        const SizedBox(width: 12),
        Expanded(child: _CardStat(title: 'Yesterday',   big: '${yKwh.toStringAsFixed(1)} kWh',    sub: '₹${yCost.toStringAsFixed(2)}', h: h, s: s)),
      ],
    );
  }
}

class _CardStat extends StatelessWidget {
  const _CardStat({required this.title, required this.big, required this.sub, required this.h, required this.s});
  final String title, big, sub; final TextStyle h, s;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: s),
          const SizedBox(height: 8),
          Text(big, style: h),
          const SizedBox(height: 4),
          Text(sub, style: s),
        ]),
      ),
    );
  }
}
