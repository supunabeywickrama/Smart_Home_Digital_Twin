import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  // tariff (e.g., LKR/kWh). Keep unit-less for UI.
  double tariff = 0.33;

  // Rooms (ids match your floorplan order)
  final Map<String, Room> rooms = {
    'living': Room(id: 'living', name: 'Living', temp: 20),
    'kitchen': Room(id: 'kitchen', name: 'Kitchen', temp: 19),
    'bath': Room(id: 'bath', name: 'Bathroom', temp: 17),
    'bed': Room(id: 'bed', name: 'Bedroom', temp: 19),
  };

  // Devices
  final Map<String, Device> devices = {};
  // Energy series for charts
  final List<EnergyPoint> energy = [];
  double kwhDay = 0, costDay = 0;

  Timer? _tick;
  final _rnd = Random();
  final Duration step = const Duration(seconds: 3);

  AppState() {
    _seedDevices();
    _linkRooms();
    start();
  }

  void _seedDevices() {
    // simple demo set
    _add(Device(id: 'living.main',   name: 'Main',     roomId: 'living', type: DeviceType.light, wattRated: 10));
    _add(Device(id: 'living.fan',    name: 'Fan',      roomId: 'living', type: DeviceType.fan,   wattRated: 30));
    _add(Device(id: 'kitchen.main',  name: 'Main',     roomId: 'kitchen',type: DeviceType.light, wattRated: 9));
    _add(Device(id: 'bath.mirror',   name: 'Mirror',   roomId: 'bath',   type: DeviceType.light, wattRated: 6));
    _add(Device(id: 'bed.shelf',     name: 'Shelf',    roomId: 'bed',    type: DeviceType.light, wattRated: 7));
    _add(Device(id: 'bed.ac',        name: 'AC',       roomId: 'bed',    type: DeviceType.thermostat, wattRated: 650));
  }

  void _add(Device d) => devices[d.id] = d;

  void _linkRooms() {
    for (final r in rooms.values) {
      r.deviceIds = devices.values.where((d) => d.roomId == r.id).map((d) => d.id).toList();
    }
  }

  // ---- mutations ----
  void toggleDevice(String id, {bool? on}) {
    final d = devices[id]!;
    final newOn = on ?? !d.state.on;
    d.state = d.state.copyWith(on: newOn, level: newOn ? (d.state.level == 0 ? 1 : d.state.level) : 0);
    notifyListeners();
  }

  void setLevel(String id, double level) {
    final d = devices[id]!;
    d.state = d.state.copyWith(on: level > 0, level: level.clamp(0, 1));
    notifyListeners();
  }

  // ---- simulator ----
  void start() {
    _tick = Timer.periodic(step, (_) => _step());
  }

  void _step() {
    final now = DateTime.now();
    final hour = now.hour + now.minute/60.0;
    final dayPhase = (2 * pi) * (hour / 24.0);

    // 1) room temp + occupancy
    rooms.forEach((_, r) {
      final base = 20 + 3 * sin(dayPhase);         // day curve
      final occupancy = _rnd.nextDouble() < (r.id == 'bed' ? (hour >= 22 || hour < 6 ? .85 : .2) : .4);
      r.occupied = occupancy;

      // AC effect (bedroom.ac)
      double acCool = 0;
      if (r.id == 'bed') {
        final ac = devices['bed.ac']!;
        acCool = ac.state.on ? (1.2 * ac.state.level) : 0;
      }
      // add a tiny noise
      r.temp = base - acCool + (_rnd.nextDouble() - .5) * 0.2;
    });

    // 2) power & energy integration
    final pW = devices.values.fold<double>(0, (sum, d) {
      final draw = (d.state.on ? d.wattRated * (d.type == DeviceType.light ? d.state.level : 1 * d.state.level.clamp(0, 1)) : 0);
      return sum + draw;
    });

    final dtHrs = step.inSeconds / 3600.0;
    kwhDay += (pW / 1000.0) * dtHrs;
    costDay = kwhDay * tariff;
    energy.add(EnergyPoint(ts: now, powerW: pW, kwhDay: kwhDay, costDay: costDay));
    if (energy.length > 1200) energy.removeAt(0); // cap

    notifyListeners();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }
}

