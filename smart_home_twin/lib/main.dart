// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';

// Screens
import 'screens/twin_screen.dart';            // HOME
import 'screens/lights_screen.dart';          // LIGHTS
import 'screens/av_screen.dart';              // AV
import 'screens/scenes_screen.dart' as scenes; // SCENES
import 'screens/climate_screen.dart';         // CLIMATE
import 'screens/motion_screen.dart';          // MOTION
import 'screens/devices_screen.dart';         // DEVICES
import 'screens/energy_screen.dart';          // ENERGY
import 'widgets/home_panel.dart';

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

  static const _tabs = [
    'HOME','LIGHTS','AV','SCENES','CLIMATE','MOTION','DEVICES','ENERGY'
  ];

  static const _pages = <Widget>[
    TwinScreen(),           // 0 HOME
    LightsScreen(),         // 1 LIGHTS
    AVScreen(),             // 2 AV
    scenes.ScenesScreen(),  // 3 SCENES
    ClimateScreen(),        // 4 CLIMATE
    MotionScreen(),         // 5 MOTION
    DevicesScreen(),        // 6 DEVICES
    EnergyScreen(),         // 7 ENERGY
  ];

  @override
  Widget build(BuildContext context) {
    assert(_tabs.length == _pages.length);
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          title: const Text('Elhood'),
          actions: [
            IconButton(
              icon: const Icon(Icons.dashboard_customize),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              tooltip: 'Home status',
            )
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [for (final t in _tabs) Tab(text: t)],
          ),
        ),
        endDrawer: const HomePanel(),   // <— right-side panel
        body: const TabBarView(children: _pages),
      ),
    );
  }
}
