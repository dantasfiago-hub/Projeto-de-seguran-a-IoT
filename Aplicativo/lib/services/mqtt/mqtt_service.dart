import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final String broker;
  final int port;
  final String clientId;

  MqttServerClient? _client;
  bool _isConnecting = false;

  final _messageStreamController =
      StreamController<MqttReceivedMessage<MqttMessage>>.broadcast();
  Stream<MqttReceivedMessage<MqttMessage>> get messageStream =>
      _messageStreamController.stream;

  VoidCallback? onConnectedCallback;
  VoidCallback? onDisconnectedCallback;

  void Function(String error)? onErrorCallback;

  MqttService(
      {required this.broker, required this.port, required this.clientId});

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<bool> connect() async {
    if (isConnected || _isConnecting) return true;
    _isConnecting = true;

    debugPrint('--- [MQTT] Tentando conectar em: $broker:$port ---');
    _client = MqttServerClient.withPort(broker, clientId, port);

    _client!.logging(on: false);
    _client!.keepAlivePeriod = 20;
    _client!.autoReconnect = true;

    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;

    final connMessage =
        MqttConnectMessage().withClientIdentifier(clientId).startClean();
    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();

      _client!.updates?.listen((messages) {
        for (var msg in messages) {
          _messageStreamController.add(msg);
        }
      });

      return true;
    } catch (e) {
      debugPrint('--- [MQTT] Erro de conexão física: $e ---');
      onErrorCallback?.call(e.toString());
      disconnect();
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  void disconnect() {
    _client?.disconnect();
    _client = null;
  }

  void subscribe(String topic) {
    if (!isConnected) {
      debugPrint(
          '--- [MQTT] Falha ao assinar: Cliente não está conectado. ---');
      return;
    }
    debugPrint('--- [MQTT] Inscrito com sucesso no tópico: $topic ---');
    _client!.subscribe(topic, MqttQos.atLeastOnce);
  }

  void publish(String topic, String payload) {
    if (!isConnected) return;
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void _onConnected() {
    onConnectedCallback?.call();
  }

  void _onDisconnected() {
    debugPrint('--- [MQTT] Callback: Desconectado do servidor. ---');
    onDisconnectedCallback?.call();
  }

  void dispose() {
    _messageStreamController.close();
    disconnect();
  }
}
