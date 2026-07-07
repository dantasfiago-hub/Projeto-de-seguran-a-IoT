import 'sensor.dart';

class Device {
  final String id;
  final String name;
  final List<Sensor> sensors;

  Device({
    required this.id,
    required this.name,
    required this.sensors,
  });
}
