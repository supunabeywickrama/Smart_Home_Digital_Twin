enum DeviceType { light, fan, plug, tv, speaker, thermostat }

class DeviceState {
  final bool on;
  final double level; // 0..1 dimmer/speed
  const DeviceState({this.on = false, this.level = 0});
  DeviceState copyWith({bool? on, double? level}) =>
      DeviceState(on: on ?? this.on, level: level ?? this.level);
}

class Device {
  final String id, name, roomId;
  final DeviceType type;
  final double wattRated; // max draw in watts
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
  double temp;         // °C
  bool occupied;
  List<String> deviceIds;
  Room({
    required this.id,
    required this.name,
    this.temp = 20,
    this.occupied = false,
    this.deviceIds = const [],
  });
}

class EnergyPoint {
  final DateTime ts;
  final double powerW;  // instantaneous total power
  final double kwhDay;  // accumulated today
  final double costDay; // currency-agnostic
  EnergyPoint({required this.ts, required this.powerW, required this.kwhDay, required this.costDay});
}
