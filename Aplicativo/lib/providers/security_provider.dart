import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_background_service/flutter_background_service.dart';

import '../models/sensor.dart';
import '../models/device.dart';
import '../models/security_event.dart';
import 'event_provider.dart';

class SecurityProvider extends ChangeNotifier {
  final Map<String, Device> _devices = {};
  bool _isBrokerConnected = false;
  bool _isSystemArmed = false;
  String? _lastError;
  String? _lastStage;

  EventProvider? _eventProvider;

  bool get isBrokerConnected => _isBrokerConnected;
  bool get isSystemArmed => _isSystemArmed;
  String? get lastError => _lastError;
  String? get lastStage => _lastStage;
  Map<String, Device> get devices => _devices;

  SecurityProvider() {
    if (kIsWeb) {
      _loadMockData();
    } else {
      _initSecuritySystem();
    }
  }

  void updateEventProvider(dynamic eventProvider) {
    if (eventProvider is EventProvider) {
      _eventProvider = eventProvider;
    }
    debugPrint("EventProvider sincronizado.");
  }

  void _loadMockData() {
    _isBrokerConnected = true;

    final sensor1 = Sensor(
        id: 'sensor_porta',
        name: 'Porta Principal',
        enabled: true,
        isViolated: false,
        state: 'fechado');
    final sensor2 = Sensor(
        id: 'sensor_janela',
        name: 'Janela Cozinha',
        enabled: true,
        isViolated: true,
        state: 'aberto');

    _devices['esp32_central'] = Device(
      id: 'esp32_central',
      name: 'Central Sertão IoT',
      sensors: [sensor1, sensor2],
    );

    notifyListeners();
  }

  void _initSecuritySystem() {
    final service = FlutterBackgroundService();

    service.on('mqtt_status').listen((event) {
      debugPrint('--- [UI] mqtt_status recebido: $event ---');
      if (event != null) {
        _isBrokerConnected = event['connected'] ?? false;
        _lastError = event['error'];
        if (event['stage'] != null) _lastStage = event['stage'];
        notifyListeners();
      }
    });

    service.on('mqtt_message_received').listen((event) {
      debugPrint('--- [UI] mqtt_message_received recebido: $event ---');
      if (event != null && event['payload'] != null) {
        _processIncomingPayload(event['payload']);
      }
    });

    _requestStatusWithRetries(service);
  }

  void _requestStatusWithRetries(FlutterBackgroundService service) {
    for (final delayMs in [0, 500, 1500, 3000]) {
      Future.delayed(Duration(milliseconds: delayMs), () {
        debugPrint('--- [UI] Enviando request_status (delay ${delayMs}ms) ---');
        service.invoke('request_status');
      });
    }
  }

  void _processIncomingPayload(String payload) {
    debugPrint('--- [UI] Processando payload: $payload ---');
    try {
      final data = jsonDecode(payload);
      if (data['type'] == 'status') {
        final String deviceId = data['deviceId'] ?? 'esp32_central';
        final sensorJson = data['sensor'];
        final updatedSensor = Sensor.fromJson(sensorJson);
        final String eventType = data['event'] ?? 'normal';

        if (data['armed'] is bool) {
          _isSystemArmed = data['armed'];
        }

        if (!_devices.containsKey(deviceId)) {
          _devices[deviceId] = Device(
            id: deviceId,
            name: 'Central Guardian',
            sensors: [],
          );
        }

        final device = _devices[deviceId]!;
        final index =
            device.sensors.indexWhere((s) => s.id == updatedSensor.id);

        final bool isNewSensor = index == -1;

        if (index != -1) {
          device.sensors[index] = updatedSensor;
        } else {
          device.sensors.add(updatedSensor);
        }

        if (_eventProvider != null) {
          final bool isViolation = eventType == 'violacao';
          _eventProvider!.addEvent(
            SecurityEvent(
              id: '${DateTime.now().microsecondsSinceEpoch}',
              timestamp: DateTime.now(),
              deviceId: deviceId,
              sensorId: updatedSensor.id,
              sensorName: updatedSensor.name,
              type: isViolation
                  ? EventType.violation
                  : (isNewSensor ? EventType.system : EventType.sensorChange),
              description: isViolation
                  ? '${updatedSensor.name} foi violado!'
                  : '${updatedSensor.name}: ${updatedSensor.state}',
            ),
          );
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro ao processar payload hierárquico na UI: $e');
    }
  }

  void toggleSystemSecurity(bool value) {
    _isSystemArmed = value;

    for (final device in _devices.values) {
      for (final sensor in device.sensors) {
        sensor.enabled = value;
      }
    }
    notifyListeners();

    if (!kIsWeb) {
      final service = FlutterBackgroundService();

      for (final device in _devices.values) {
        for (final sensor in device.sensors) {
          final command = {
            'type': 'command',
            'command': 'set_sensor_enabled',
            'deviceId': device.id,
            'sensorId': sensor.id,
            'enabled': value,
          };

          service.invoke('send_command', {
            'command': jsonEncode(command),
          });
        }
      }
    }
  }

  void toggleSensor(String deviceId, String sensorId, bool value) {
    final device = _devices[deviceId];
    if (device != null) {
      try {
        final sensor = device.sensors.firstWhere((s) => s.id == sensorId);
        sensor.enabled = value;
        notifyListeners();
      } catch (e) {
        debugPrint("Sensor não localizado.");
      }
    }

    if (!kIsWeb) {
      final command = {
        'type': 'command',
        'command': 'set_sensor_enabled',
        'deviceId': deviceId,
        'sensorId': sensorId,
        'enabled': value,
      };

      FlutterBackgroundService().invoke('send_command', {
        'command': jsonEncode(command),
      });
    }
  }
}
