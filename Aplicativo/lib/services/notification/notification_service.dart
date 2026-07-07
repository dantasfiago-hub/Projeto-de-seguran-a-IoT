import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelCriticalSoundId =
      'guardian_critical_alerts_sound';
  static const String _channelCriticalSilentId =
      'guardian_critical_alerts_silent';
  static const String _channelInfoId = 'guardian_info_alerts';

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
    );

    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      const AndroidNotificationChannel criticalSoundChannel =
          AndroidNotificationChannel(
        _channelCriticalSoundId,
        'Alertas Críticos de Segurança (com som)',
        description: 'Disparado em caso de invasão ou violação de perímetro.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      const AndroidNotificationChannel criticalSilentChannel =
          AndroidNotificationChannel(
        _channelCriticalSilentId,
        'Alertas Críticos de Segurança (silencioso)',
        description: 'Disparado em caso de invasão ou violação de perímetro.',
        importance: Importance.max,
        playSound: false,
        enableVibration: true,
      );

      const AndroidNotificationChannel infoChannel = AndroidNotificationChannel(
        _channelInfoId,
        'Status do Sistema',
        description: 'Notificações de sistema armado, desarmado ou conexão.',
        importance: Importance.defaultImportance,
        playSound: true,
      );

      await androidImplementation
          .createNotificationChannel(criticalSoundChannel);
      await androidImplementation
          .createNotificationChannel(criticalSilentChannel);
      await androidImplementation.createNotificationChannel(infoChannel);
    }
  }

  Future<void> showCriticalAlert({
    required int id,
    required String title,
    required String body,
    bool playSound = true,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      playSound ? _channelCriticalSoundId : _channelCriticalSilentId,
      playSound
          ? 'Alertas Críticos de Segurança (com som)'
          : 'Alertas Críticos de Segurança (silencioso)',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.red,
      playSound: playSound,
      styleInformation: const BigTextStyleInformation(''),
    );

    final NotificationDetails details =
        NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(id, title, body, details);
  }

  Future<void> showInfoAlert(
      {required int id, required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelInfoId,
      'Status do Sistema',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(id, title, body, details);
  }
}
