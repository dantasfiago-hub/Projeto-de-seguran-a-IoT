import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tema do Aplicativo',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Auto')),
                        ButtonSegment(value: 1, label: Text('Claro')),
                        ButtonSegment(value: 2, label: Text('Escuro')),
                      ],
                      selected: {settings.themeIndex},
                      onSelectionChanged: (set) =>
                          settings.updateTheme(set.first),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Notificações Push'),
                  value: settings.notificationsEnabled,
                  onChanged: settings.toggleNotifications,
                ),
                SwitchListTile(
                  title: const Text('Som do Alarme'),
                  value: settings.alarmSoundEnabled,
                  onChanged: settings.toggleAlarmSound,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            child: ListTile(
              leading: const Icon(Icons.dns),
              title: const Text('Configurar Conexão MQTT'),
              subtitle: Text('${settings.broker}:${settings.port}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => _showMqttDialog(context, settings),
            ),
          )
        ],
      ),
    );
  }

  void _showMqttDialog(BuildContext context, SettingsProvider settings) {
    final brokerCtrl = TextEditingController(text: settings.broker);
    final portCtrl = TextEditingController(text: settings.port.toString());
    final clientIdCtrl = TextEditingController(text: settings.clientId);
    final statusTopicCtrl = TextEditingController(text: settings.statusTopic);
    final commandTopicCtrl = TextEditingController(text: settings.commandTopic);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajustes Broker MQTT'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: brokerCtrl,
                  decoration: const InputDecoration(labelText: 'Broker')),
              TextField(
                  controller: portCtrl,
                  decoration: const InputDecoration(labelText: 'Porta'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: clientIdCtrl,
                  decoration: const InputDecoration(labelText: 'Client ID')),
              TextField(
                  controller: statusTopicCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Tópico de Status')),
              TextField(
                  controller: commandTopicCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Tópico de Comando')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              settings.saveMqttSettings(
                broker: brokerCtrl.text,
                port: int.parse(portCtrl.text),
                clientId: clientIdCtrl.text,
                statusTopic: statusTopicCtrl.text,
                commandTopic: commandTopicCtrl.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
