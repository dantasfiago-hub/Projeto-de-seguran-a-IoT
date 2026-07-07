enum EventType { violation, system, sensorChange }

class SecurityEvent {
  final String id;
  final DateTime timestamp;
  final String deviceId;
  final String sensorId;
  final String sensorName;
  final EventType type;
  final String description;

  SecurityEvent({
    required this.id,
    required this.timestamp,
    required this.deviceId,
    required this.sensorId,
    required this.sensorName,
    required this.type,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'deviceId': deviceId,
        'sensorId': sensorId,
        'sensorName': sensorName,
        'type': type.index,
        'description': description,
      };

  factory SecurityEvent.fromJson(Map<String, dynamic> json) => SecurityEvent(
        id: json['id'],
        timestamp: DateTime.parse(json['timestamp']),
        deviceId: json['deviceId'],
        sensorId: json['sensorId'],
        sensorName: json['sensorName'],
        type: EventType.values[json['type']],
        description: json['description'],
      );
}
