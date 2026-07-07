import 'package:flutter/material.dart';
import '../models/security_event.dart';

class EventProvider extends ChangeNotifier {
  final List<SecurityEvent> _allEvents = [];
  EventType? _selectedFilter;

  List<SecurityEvent> get events {
    if (_selectedFilter == null) {
      return List.unmodifiable(_allEvents.reversed);
    }
    return List.unmodifiable(
      _allEvents.where((e) => e.type == _selectedFilter).toList().reversed,
    );
  }

  List<SecurityEvent> get rawEvents => _allEvents;
  EventType? get currentFilter => _selectedFilter;

  void addEvent(SecurityEvent event) {
    _allEvents.add(event);
    notifyListeners();
  }

  void setFilter(EventType? filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void clearHistory() {
    _allEvents.clear();
    _selectedFilter = null;
    notifyListeners();
  }
}
