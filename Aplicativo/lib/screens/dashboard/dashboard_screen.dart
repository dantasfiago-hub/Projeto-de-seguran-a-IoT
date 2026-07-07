import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';

import '../../providers/security_provider.dart';
import '../../services/notification/notification_service.dart';
import '../../services/background/background_manager.dart';

import '../events/events_screen.dart';
import '../stats/stats_screen.dart';
import '../settings/settings_screen.dart';
import '../about/about_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  String? _initError;

  final List<Widget> _screens = [
    const DashboardView(),
    const EventsScreen(),
    const StatsScreen(),
    const SettingsScreen(),
    const AboutScreen(),
  ];

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final notificationService = NotificationService();
          await notificationService.init();
          debugPrint("--- [Guardian IoT] Notificações prontas ---");
        } catch (e, stack) {
          debugPrint("Aviso: notificações locais falharam: $e\n$stack");
          if (mounted) {
            setState(() {
              _initError = 'Notificações desativadas: $e';
            });
          }
        }

        try {
          await BackgroundManager.initializeService();
          debugPrint("--- [Guardian IoT] Serviço de background pronto ---");
        } catch (e, stack) {
          debugPrint("Erro crítico ao subir serviço de background: $e\n$stack");
          if (mounted) {
            setState(() {
              _initError = 'Falha no serviço de background: $e';
            });
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_initError != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(10),
              child: Text(
                'Falha ao iniciar serviços: $_initError',
                style: TextStyle(color: Colors.red.shade900, fontSize: 12),
              ),
            ),
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield),
              label: 'Painel'),
          NavigationDestination(
              icon: Icon(Icons.history_toggle_off),
              selectedIcon: Icon(Icons.history),
              label: 'Logs'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Análise'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Ajustes'),
          NavigationDestination(
              icon: Icon(Icons.info_outline),
              selectedIcon: Icon(Icons.info),
              label: 'Sobre'),
        ],
      ),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecurityProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian IoT',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: Icon(Icons.circle,
                  color: security.isBrokerConnected ? Colors.green : Colors.red,
                  size: 12),
              label: Text(security.isBrokerConnected ? 'Online' : 'Offline'),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (!security.isBrokerConnected)
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  security.lastError != null
                      ? 'Erro: ${security.lastError}'
                      : 'Última etapa alcançada: ${security.lastStage ?? "nenhuma (isolate não reportou nada ainda)"}',
                  style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                ),
              ),
            ),
          if (!security.isBrokerConnected) const SizedBox(height: 8),
          Card(
            color: security.isSystemArmed
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(security.isSystemArmed ? Icons.gpp_bad : Icons.gpp_good,
                      size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            security.isSystemArmed
                                ? 'Sistema Armado'
                                : 'Sistema Desarmado',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                            security.isSystemArmed
                                ? 'Monitores ativos sob alerta.'
                                : 'Monitoramento em modo pacífico.',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Switch(
                    value: security.isSystemArmed,
                    onChanged: (val) => security.toggleSystemSecurity(val),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Dispositivos e Sensores',
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          if (security.devices.isEmpty)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Nenhum sensor reportando.')))
          else
            ...security.devices.entries.map((entry) {
              final device = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: device.sensors.map((sensor) {
                  final isAlerta =
                      sensor.state == 'aberto' || sensor.state == 'alerta';
                  return Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    child: SwitchListTile(
                      secondary: Icon(
                          isAlerta
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline_rounded,
                          color: isAlerta ? Colors.red : Colors.green),
                      title: Text(sensor.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Estado: ${sensor.state.toUpperCase()}',
                          style: TextStyle(
                              color: isAlerta ? Colors.red : Colors.green)),
                      value: sensor.enabled,
                      onChanged: (val) =>
                          security.toggleSensor(device.id, sensor.id, val),
                    ),
                  );
                }).toList(),
              );
            }),
        ],
      ),
    );
  }
}
