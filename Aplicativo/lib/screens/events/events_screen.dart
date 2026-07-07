import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/event_provider.dart';
import '../../models/security_event.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Eventos',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (eventProvider.events.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => eventProvider.clearHistory(),
            ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                FilterChip(
                    label: const Text('Todos'),
                    selected: eventProvider.currentFilter == null,
                    onSelected: (_) => eventProvider.setFilter(null)),
                const SizedBox(width: 8),
                FilterChip(
                    label: const Text('Violações'),
                    selected:
                        eventProvider.currentFilter == EventType.violation,
                    onSelected: (_) =>
                        eventProvider.setFilter(EventType.violation)),
                const SizedBox(width: 8),
                FilterChip(
                    label: const Text('Sensores'),
                    selected:
                        eventProvider.currentFilter == EventType.sensorChange,
                    onSelected: (_) =>
                        eventProvider.setFilter(EventType.sensorChange)),
              ],
            ),
          ),
          Expanded(
            child: eventProvider.events.isEmpty
                ? const Center(child: Text('Nenhum log registrado.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: eventProvider.events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final event = eventProvider.events[index];
                      final isViolation = event.type == EventType.violation;
                      return ListTile(
                        tileColor: isViolation
                            ? theme.colorScheme.errorContainer.withOpacity(0.2)
                            : theme.colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        leading: Icon(
                            isViolation ? Icons.gpp_bad : Icons.sensors,
                            color: isViolation
                                ? Colors.red
                                : theme.colorScheme.primary),
                        title: Text(event.description,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${event.sensorName} • ${DateFormat('HH:mm:ss').format(event.timestamp)}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
