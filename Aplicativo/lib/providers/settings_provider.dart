import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/storage/storage_service.dart';
import '../services/background/background_manager.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService;

  SettingsProvider(this._storageService);

  ThemeMode get themeMode {
    switch (_storageService.themeModeIndex) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  int get themeIndex => _storageService.themeModeIndex;
  bool get notificationsEnabled => _storageService.notificationsEnabled;
  bool get alarmSoundEnabled => _storageService.alarmSoundEnabled;
  String get broker => _storageService.broker;
  int get port => _storageService.port;
  String get clientId => _storageService.clientId;
  String get statusTopic => _storageService.statusTopic;
  String get commandTopic => _storageService.commandTopic;

  Future<void> updateTheme(int index) async {
    await _storageService.setThemeModeIndex(index);
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    await _storageService.setNotificationsEnabled(value);
    notifyListeners();
  }

  Future<void> toggleAlarmSound(bool value) async {
    await _storageService.setAlarmSoundEnabled(value);
    notifyListeners();
  }

  Future<void> saveMqttSettings({
    required String broker,
    required int port,
    required String clientId,
    required String statusTopic,
    required String commandTopic,
  }) async {
    await _storageService.setMqttConfig(
        broker, port, clientId, statusTopic, commandTopic);
    notifyListeners();

    if (!kIsWeb) {
      BackgroundManager.reloadConfig();
    }
  }
}
