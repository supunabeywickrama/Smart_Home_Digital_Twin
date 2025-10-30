enum DeviceType { light, fan, plug, tv, speaker, thermostat }

class DeviceState {
  final bool on;
  final double level; // 0..1 dimmer/speed/power/volume
  const DeviceState({this.on = false, this.level = 0});
  DeviceState copyWith({bool? on, double? level}) =>
      DeviceState(on: on ?? this.on, level: level ?? this.level);
}

class Device {
  final String id, name, roomId;
  final DeviceType type;
  final double wattRated; // rated/max draw in Watts
  DeviceState state;
  Device({
    required this.id,
    required this.name,
    required this.roomId,
    required this.type,
    required this.wattRated,
    this.state = const DeviceState(),
  });
}

class Room {
  final String id, name;
  double temp;                 // °C (simulated)
  bool occupied;               // simulated
  double setpoint;             // °C (user target)
  bool hold;                   // if true, simulator drives temp -> setpoint
  List<String> deviceIds;
  Room({
    required this.id,
    required this.name,
    this.temp = 20,
    this.occupied = false,
    this.setpoint = 24,
    this.hold = false,
    this.deviceIds = const [],
  });
}

class EnergyPoint {
  final DateTime ts;
  final double powerW;  // instantaneous total power
  final double kwhDay;  // accumulated today
  final double costDay; // today’s cost
  EnergyPoint({required this.ts, required this.powerW, required this.kwhDay, required this.costDay});
}

// ---- scenes / alerts ----
class SceneAction {
  final String deviceId;
  final bool? on;
  final double? level; // 0..1
  const SceneAction({required this.deviceId, this.on, this.level});
}

class Scene {
  final String id, name;
  final List<SceneAction> actions;
  const Scene({required this.id, required this.name, required this.actions});
}

class Alert {
  final DateTime ts;
  final String msg;
  final String icon; // material icon name
  const Alert({required this.ts, required this.msg, required this.icon});
}

// ---- motion events (for feed) ----
class MotionEvent {
  final DateTime ts;
  final String roomId;
  final bool entered; // true=became occupied, false=vacant
  const MotionEvent({required this.ts, required this.roomId, required this.entered});
}
