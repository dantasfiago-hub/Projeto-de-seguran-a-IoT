import 'package:flutter/material.dart';
import '../models/security_event.dart';

class SensorActivity {
  final String name;
  final int count;
  SensorActivity(this.name, this.count);
}

class HourlyActivity {
  final int hour;
  final int count;
  HourlyActivity(this.hour, this.count);
}

class StatsProvider extends ChangeNotifier {
  List<SensorActivity> getMostTriggeredSensors(List<SecurityEvent> events) {
    final Map<String, int> counter = {};
    for (var e in events) {
      if (e.type == EventType.sensorChange || e.type == EventType.violation) {
        counter[e.sensorName] = (counter[e.sensorName] ?? 0) + 1;
      }
    }
    final sortedList = counter.entries
        .map((entry) => SensorActivity(entry.key, entry.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return sortedList.take(5).toList();
  }

  List<HourlyActivity> getEventsByHour(List<SecurityEvent> events) {
    final Map<int, int> hourlyCounter = {for (int i = 0; i < 24; i += 4) i: 0};
    for (var e in events) {
      final hour = e.timestamp.hour;
      final bucket = (hour / 4).floor() * 4;
      hourlyCounter[bucket] = (hourlyCounter[bucket] ?? 0) + 1;
    }
    return hourlyCounter.entries
        .map((entry) => HourlyActivity(entry.key, entry.value))
        .toList();
  }

  int getTotalViolations(List<SecurityEvent> events) {
    return events.where((e) => e.type == EventType.violation).length;
  }
}
