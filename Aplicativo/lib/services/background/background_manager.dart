import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mqtt/mqtt_service.dart';
import '../storage/storage_service.dart';
import '../notification/notification_service.dart';

class BackgroundManager {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel foregroundChannel =
        AndroidNotificationChannel(
      'guardian_foreground_service',
      'Guardian IoT - Serviço em Segundo Plano',
      description: 'Mantém o monitoramento MQTT ativo em segundo plano.',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(foregroundChannel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'guardian_foreground_service',
        initialNotificationTitle: 'Guardian IoT Ativo',
        initialNotificationContent: 'Protegendo em segundo plano...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: (s) async => true,
      ),
    );
  }

  static void reloadConfig() {
    FlutterBackgroundService().invoke('reload_config');
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    DartPluginRegistrant.ensureInitialized();
    service.invoke(
        'mqtt_status', {'connected': false, 'stage': '1_isolate_started'});

    final prefs = await SharedPreferences.getInstance();
    StorageService storageService = StorageService(prefs);
    service.invoke('mqtt_status', {'connected': false, 'stage': '2_prefs_ok'});

    final notificationService = NotificationService();
    try {
      await notificationService.init();
      service.invoke(
          'mqtt_status', {'connected': false, 'stage': '3_notifications_ok'});
    } catch (e) {
      service.invoke('mqtt_status', {
        'connected': false,
        'stage': '3_notifications_failed_but_continuing: $e'
      });
    }

    MqttService? mqttService;

    Future<void> connectMqtt() async {
      mqttService?.dispose();

      final newMqttService = MqttService(
        broker: storageService.broker,
        port: storageService.port,
        clientId: '${storageService.clientId}_bg',
      );
      mqttService = newMqttService;

      service.invoke('mqtt_status',
          {'connected': false, 'stage': '4_mqtt_client_created'});

      newMqttService.onConnectedCallback = () {
        debugPrint(
            '--- [ISOLATE] Conectado! Inscrevendo no tópico: ${storageService.statusTopic} ---');
        newMqttService.subscribe(storageService.statusTopic);
        service.invoke('mqtt_status', {'connected': true});
      };

      newMqttService.onDisconnectedCallback = () {
        service.invoke('mqtt_status', {'connected': false});
      };

      newMqttService.onErrorCallback = (error) {
        service.invoke('mqtt_status', {'connected': false, 'error': error});
      };

      newMqttService.messageStream.listen((event) {
        final recMessage = event.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
            recMessage.payload.message);

        debugPrint(
            '--- [ISOLATE] Mensagem MQTT recebida no tópico ${event.topic}: $payload ---');

        service.invoke('mqtt_message_received', {'payload': payload});

        _handleIncomingMessageForAlerts(
          payload: payload,
          storageService: storageService,
          notificationService: notificationService,
        );
      });

      service.invoke(
          'mqtt_status', {'connected': false, 'stage': '5_calling_connect'});
      await newMqttService.connect();
    }

    service.on('request_status').listen((event) {
      service.invoke(
          'mqtt_status', {'connected': mqttService?.isConnected ?? false});
    });

    service.on('send_command').listen((event) {
      if (event != null && mqttService != null) {
        mqttService!.publish(storageService.commandTopic, event['command']);
      }
    });

    service.on('reload_config').listen((event) async {
      await prefs.reload();
      service.invoke('mqtt_status',
          {'connected': false, 'stage': 'reconnecting_with_new_config'});
      await connectMqtt();
    });

    await connectMqtt();
  } catch (e, stack) {
    service.invoke('mqtt_status', {
      'connected': false,
      'error': 'CRASH no onStart: $e',
    });
    debugPrint('--- [BackgroundManager] CRASH: $e\n$stack ---');
  }
}

Future<void> _handleIncomingMessageForAlerts({
  required String payload,
  required StorageService storageService,
  required NotificationService notificationService,
}) async {
  try {
    final Map<String, dynamic> data = jsonDecode(payload);
    if (data['event'] == 'violacao') {
      await storageService.reloadPrefs();

      if (storageService.notificationsEnabled) {
        notificationService.showCriticalAlert(
          id: DateTime.now().millisecond,
          title: '🚨 PERÍMETRO VIOLADO!',
          body:
              'O sensor ${data['sensor']['name'] ?? 'desconhecido'} disparou!',
          playSound: storageService.alarmSoundEnabled,
        );
      }
    }
  } catch (_) {}
}
