class Sensor {
  final String id;
  final String name;
  bool enabled;
  bool isViolated;
  dynamic state;

  Sensor({
    required this.id,
    required this.name,
    required this.enabled,
    this.isViolated = false,
    this.state = 'fechado',
  });

  factory Sensor.fromJson(Map<String, dynamic> json) {
    final bool violated = json['isViolated'] ??
        (json['status'] == 'aberto' ||
            json['state'] == 'aberto' ||
            json['state'] == true);

    return Sensor(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Sensor Indefinido',
      enabled: json['enabled'] ?? true,
      isViolated: violated,
      state:
          json['state'] ?? json['status'] ?? (violated ? 'aberto' : 'fechado'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'enabled': enabled,
      'isViolated': isViolated,
      'state': state,
    };
  }
}
