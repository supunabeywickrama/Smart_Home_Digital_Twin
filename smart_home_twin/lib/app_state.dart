import 'dart:async'; 
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'models.dart';

class HomeStatus {
  bool inBed = false;
  bool cooking = false;
  bool showering = false;
  bool washing = false;
  bool houseOccupied = true;
}

class AppState extends ChangeNotifier {
  double tariff = 0.33;
  double yesterdayKwh = 11.0;
  double yesterdayCost = 3.63;

  final Map<String, Room> rooms = {
    'living': Room(id: 'living', name: 'Living',  temp: 20, setpoint: 24),
    'kitchen':Room(id: 'kitchen',name: 'Kitchen', temp: 19, setpoint: 24),
    'bath':   Room(id: 'bath',   name: 'Bathroom',temp: 17, setpoint: 23),
    'bed':    Room(id: 'bed',    name: 'Bedroom', temp: 19, setpoint: 24),
  };
  final Map<String, Device> devices = {};
  final List<EnergyPoint> energy = [];
  final List<Alert> alerts = [];
  final List<Scene> scenes = [];
  final List<MotionEvent> motion = [];

  final Map<String, bool> _prevOcc = {};
  final Map<String, DateTime> _lastActivity = {};
  final Duration occupancyHold = const Duration(minutes: 5);

  double kwhDay = 0, costDay = 0;

  Timer? _tick;
  final _rnd = Random();
  final Duration step = const Duration(seconds: 3);
  int _ticks = 0;

  final HomeStatus status = HomeStatus();

  AppState() {
    _seedDevices();
    _linkRooms();
    _seedScenes();
    final t0 = DateTime.now().subtract(const Duration(minutes: 10));
    for (final r in rooms.values) {
      _prevOcc[r.id] = r.occupied;
      _lastActivity[r.id] = t0;
    }
    start();
  }

  void _seedDevices() {
    _add(Device(id: 'living.main',  name: 'Main',    roomId: 'living', type: DeviceType.light,      wattRated: 10));
    _add(Device(id: 'living.fan',   name: 'Fan',     roomId: 'living', type: DeviceType.fan,        wattRated: 30));
    _add(Device(id: 'living.tv',    name: 'TV',      roomId: 'living', type: DeviceType.tv,         wattRated: 90));
    _add(Device(id: 'living.spk',   name: 'Speaker', roomId: 'living', type: DeviceType.speaker,    wattRated: 25));
    _add(Device(id: 'kitchen.main', name: 'Main',    roomId: 'kitchen',type: DeviceType.light,      wattRated: 9));
    _add(Device(id: 'bath.mirror',  name: 'Mirror',  roomId: 'bath',   type: DeviceType.light,      wattRated: 6));
    _add(Device(id: 'bed.shelf',    name: 'Shelf',   roomId: 'bed',    type: DeviceType.light,      wattRated: 7));
    _add(Device(id: 'bed.ac',       name: 'AC',      roomId: 'bed',    type: DeviceType.thermostat, wattRated: 650));
  }
  void _add(Device d) => devices[d.id] = d;

  void _linkRooms() {
    for (final r in rooms.values) {
      r.deviceIds = devices.values.where((d) => d.roomId == r.id).map((d) => d.id).toList();
    }
  }

  void _seedScenes() {
    scenes.addAll([
      Scene(
        id: 'scene.night', name: 'Night',
        actions: const [
          SceneAction(deviceId: 'living.main',  level: 0.0),
          SceneAction(deviceId: 'kitchen.main', level: 0.0),
          SceneAction(deviceId: 'bath.mirror',  level: 0.0),
          SceneAction(deviceId: 'bed.shelf',    level: .2),
          SceneAction(deviceId: 'bed.ac',       level: .3, on: true),
        ],
      ),
      Scene(
        id: 'scene.away', name: 'Away',
        actions: const [
          SceneAction(deviceId: 'living.main',  level: 0.0),
          SceneAction(deviceId: 'living.fan',   level: 0.0),
          SceneAction(deviceId: 'kitchen.main', level: 0.0),
          SceneAction(deviceId: 'bath.mirror',  level: 0.0),
          SceneAction(deviceId: 'bed.shelf',    level: 0.0),
          SceneAction(deviceId: 'bed.ac',       level: 0.0, on: false),
          SceneAction(deviceId: 'living.tv',    level: 0.0, on: false),
          SceneAction(deviceId: 'living.spk',   level: 0.0, on: false),
        ],
      ),
      Scene(
        id: 'scene.movie', name: 'Movie',
        actions: const [
          SceneAction(deviceId: 'living.main', level: .15, on: true),
          SceneAction(deviceId: 'living.fan',  level: .3,  on: true),
          SceneAction(deviceId: 'living.tv',   level: 1.0, on: true),
          SceneAction(deviceId: 'living.spk',  level: .7,  on: true),
        ],
      ),
      Scene(
        id: 'scene.workcall', name: 'Work Call',
        actions: const [
          SceneAction(deviceId: 'living.main', level: .6, on: true),
          SceneAction(deviceId: 'living.spk',  level: 0.0, on: false),
        ],
      ),
    ]);
  }

  // ---- internal helpers ----
  void _pokeRoom(String roomId) {
    _lastActivity[roomId] = DateTime.now();
    rooms[roomId]!.occupied = true;
  }

  String _roomOfDevice(String deviceId) => devices[deviceId]!.roomId;

  // ---- NEW HELPERS (added as per instruction) ----
  String _iconNameFor(Device d) {
    switch (d.type) {
      case DeviceType.light:       return 'lightbulb';
      case DeviceType.fan:         return 'air';
      case DeviceType.tv:          return 'tv';
      case DeviceType.speaker:     return 'speaker';
      case DeviceType.thermostat:  return 'ac_unit';
      case DeviceType.plug:        return 'power';
    }
  }

  void _pushDeviceChangeAlert(Device d, {bool levelChanged = false, double? prevLevel}) {
    final room = rooms[d.roomId]?.name ?? d.roomId;
    final icon = _iconNameFor(d);
    if (levelChanged) {
      final p = ((d.state.level) * 100).round();
      pushAlert('$room • ${d.name} set to $p%', icon);
    } else {
      pushAlert('$room • ${d.name} turned ${d.state.on ? "ON" : "OFF"}', icon);
    }
  }

  // ---- mutations ----
  void toggleDevice(String id, {bool? on}) {
    final d = devices[id]!;
    final bool newOn = on ?? !d.state.on;
    final double nextLevel = newOn
        ? (d.state.level == 0.0 ? 1.0 : d.state.level)
        : 0.0;
    d.state = d.state.copyWith(on: newOn, level: nextLevel);
    _pokeRoom(d.roomId);
    _pushDeviceChangeAlert(d);               // <-- push alert
    notifyListeners();
  }

  void setLevel(String id, double level) {
    final d = devices[id]!;
    final double prev = d.state.level;
    final double clamped = level.clamp(0.0, 1.0).toDouble();
    d.state = d.state.copyWith(on: clamped > 0.0, level: clamped);
    _pokeRoom(d.roomId);
    if ((clamped - prev).abs() >= 0.05 || (clamped == 0.0 && prev != 0.0)) {
      _pushDeviceChangeAlert(d, levelChanged: true, prevLevel: prev);
    }
    notifyListeners();
  }

  void setSetpoint(String roomId, double sp) {
    rooms[roomId]!.setpoint = sp;
    notifyListeners();
  }

  void setHold(String roomId, bool v) {
    rooms[roomId]!.hold = v;
    notifyListeners();
  }

  void runScene(String sceneId) {
    final sc = scenes.firstWhere((s) => s.id == sceneId);
    for (final a in sc.actions) {
      final d = devices[a.deviceId]!;
      final double baseLevel = (a.level ?? d.state.level);
      final double newLevel = baseLevel.clamp(0.0, 1.0).toDouble();
      final bool newOn = a.on ?? (newLevel > 0.0);
      d.state = d.state.copyWith(on: newOn, level: newLevel);
      _pokeRoom(d.roomId);
    }
    pushAlert('Scene "${sc.name}" activated', 'play_circle');
    notifyListeners();
  }

  void pushAlert(String msg, String icon) {
    alerts.insert(0, Alert(ts: DateTime.now(), msg: msg, icon: icon));
    if (alerts.length > 40) alerts.removeLast();
    notifyListeners();
  }

  double devicePowerW(Device d) {
    if (!d.state.on) return 0.0;
    final double lvl = d.state.level.clamp(0.0, 1.0).toDouble();
    switch (d.type) {
      case DeviceType.light:
      case DeviceType.fan:
      case DeviceType.speaker:
      case DeviceType.thermostat:
        return d.wattRated * lvl;
      case DeviceType.tv:
        return d.wattRated;
      case DeviceType.plug:
        return d.wattRated * (lvl == 0.0 ? 1.0 : lvl);
    }
  }

  void markActivity(String roomId) {
    _pokeRoom(roomId);
    notifyListeners();
  }

  void toggleStatus(String key, bool v) {
    switch (key) {
      case 'inBed':
        status.inBed = v;
        if (v) { markActivity('bed'); pushAlert('In Bed', 'bed'); }
        break;
      case 'cooking':
        status.cooking = v;
        if (v) { markActivity('kitchen'); pushAlert('Someone Cooking', 'soup_kitchen'); }
        break;
      case 'showering':
        status.showering = v;
        if (v) { markActivity('bath'); pushAlert('Showering', 'shower'); }
        break;
      case 'washing':
        status.washing = v;
        if (v) { markActivity('bath'); pushAlert('Laundry Running', 'local_laundry_service'); }
        break;
      case 'house':
        status.houseOccupied = v;
        break;
    }
    notifyListeners();
  }

  void start() => _tick = Timer.periodic(step, (_) => _step());

  void _step() {
    _ticks++;
    final now = DateTime.now();
    final hour = now.hour + now.minute / 60.0;
    final double dayPhase = (2 * pi) * (hour / 24.0);

    rooms.forEach((_, r) {
      final last = _lastActivity[r.id] ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bool occ = now.difference(last) < occupancyHold;

      if (_prevOcc[r.id] != occ) {
        motion.insert(0, MotionEvent(ts: now, roomId: r.id, entered: occ));
        if (motion.length > 60) motion.removeLast();
        _prevOcc[r.id] = occ;
      }
      r.occupied = occ;

      final double base = 20 + 3 * sin(dayPhase) + (_rnd.nextDouble() - .5) * 0.2;

      double hvacGain = r.hold ? 0.25 : 0.0;
      if (r.id == 'bed') {
        final ac = devices['bed.ac']!;
        final double acLvl = ac.state.level.clamp(0.0, 1.0).toDouble();
        hvacGain *= (0.4 + acLvl);
      }
      r.temp = base + hvacGain * (r.setpoint - base);
    });

    final double pW = devices.values.fold<double>(0.0, (sum, d) => sum + devicePowerW(d));
    final double dtHrs = step.inSeconds / 3600.0;
    kwhDay += (pW / 1000.0) * dtHrs;
    costDay = kwhDay * tariff;

    energy.add(EnergyPoint(ts: now, powerW: pW, kwhDay: kwhDay, costDay: costDay));
    if (energy.length > 1200) energy.removeAt(0);

    if (_ticks % 40 == 0) pushAlert('Garden watering complete • 10 min', 'local_florist');
    if (_ticks % 60 == 0) pushAlert('Laundry finished • Please hang', 'local_laundry_service');

    notifyListeners();
  }

  @override
  void dispose() { _tick?.cancel(); super.dispose(); }
}
