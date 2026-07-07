import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  Future<void> reloadPrefs() => _prefs.reload();

  static const _keyBroker = 'mqtt_broker';
  static const _keyPort = 'mqtt_port';
  static const _keyClientId = 'mqtt_client_id';
  static const _keyStatusTopic = 'mqtt_status_topic';
  static const _keyCommandTopic = 'mqtt_command_topic';
  static const _keyThemeMode = 'app_theme_mode';
  static const _keyNotifications = 'app_notifications_enabled';
  static const _keyAlarmSound = 'app_alarm_sound_enabled';

  String get broker => _prefs.getString(_keyBroker) ?? 'broker.hivemq.com';
  int get port => _prefs.getInt(_keyPort) ?? 1883;
  String get clientId =>
      _prefs.getString(_keyClientId) ?? 'esp32_flutter_client';
  String get statusTopic =>
      _prefs.getString(_keyStatusTopic) ?? 'home/security/status';
  String get commandTopic =>
      _prefs.getString(_keyCommandTopic) ?? 'home/security/command';
  int get themeModeIndex => _prefs.getInt(_keyThemeMode) ?? 0;
  bool get notificationsEnabled => _prefs.getBool(_keyNotifications) ?? true;
  bool get alarmSoundEnabled => _prefs.getBool(_keyAlarmSound) ?? true;

  Future<void> setMqttConfig(String broker, int port, String clientId,
      String status, String command) async {
    await _prefs.setString(_keyBroker, broker);
    await _prefs.setInt(_keyPort, port);
    await _prefs.setString(_keyClientId, clientId);
    await _prefs.setString(_keyStatusTopic, status);
    await _prefs.setString(_keyCommandTopic, command);
  }

  Future<void> setThemeModeIndex(int index) async =>
      await _prefs.setInt(_keyThemeMode, index);
  Future<void> setNotificationsEnabled(bool value) async =>
      await _prefs.setBool(_keyNotifications, value);
  Future<void> setAlarmSoundEnabled(bool value) async =>
      await _prefs.setBool(_keyAlarmSound, value);
}
