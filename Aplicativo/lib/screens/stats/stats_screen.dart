import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/event_provider.dart';
import '../../providers/stats_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rawEvents = context.watch<EventProvider>().rawEvents;
    final stats = context.watch<StatsProvider>();

    final topSensors = stats.getMostTriggeredSensors(rawEvents);
    final hourlyData = stats.getEventsByHour(rawEvents);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: rawEvents.isEmpty
          ? const Center(child: Text('Sem dados suficientes.'))
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Atividade por Período',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        AspectRatio(
                          aspectRatio: 2,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: hourlyData
                                      .map((d) => FlSpot(d.hour.toDouble(),
                                          d.count.toDouble()))
                                      .toList(),
                                  isCurved: true,
                                  color: theme.colorScheme.primary,
                                  barWidth: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Top Sensores Acionados',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        AspectRatio(
                          aspectRatio: 2,
                          child: BarChart(
                            BarChartData(
                              borderData: FlBorderData(show: false),
                              barGroups:
                                  topSensors.asMap().entries.map((entry) {
                                return BarChartGroupData(
                                  x: entry.key,
                                  barRods: [
                                    BarChartRodData(
                                        toY: entry.value.count.toDouble(),
                                        color: theme.colorScheme.secondary,
                                        width: 16),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
