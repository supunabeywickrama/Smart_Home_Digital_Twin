import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'screens/twin_screen.dart';
import 'screens/lights_screen.dart';
import 'screens/energy_screen.dart';

void main() => runApp(const TwinApp());

class TwinApp extends StatelessWidget {
  const TwinApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Elhood',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
          useMaterial3: true,
        ),
        home: const _Tabs(),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({super.key});
  @override
  Widget build(BuildContext context) {
    const tabs = ['HOME','LIGHTS','AV','SCENES','CLIMATE','MOTION','DEVICES','ENERGY'];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          title: const Text('Elhood'),
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [for (final t in tabs) Tab(text: t)],
          ),
        ),
        body: const TabBarView(
          children: [
            TwinScreen(),
            LightsScreen(),
            Center(child: Text('AV')),
            Center(child: Text('Scenes')),
            Center(child: Text('Climate')),
            Center(child: Text('Motion')),
            Center(child: Text('Devices')),
            EnergyScreen(),
          ],
        ),
      ),
    );
  }
}
