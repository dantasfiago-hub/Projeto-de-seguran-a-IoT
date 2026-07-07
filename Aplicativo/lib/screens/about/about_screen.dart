import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sobre')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Column(
                children: [
                  Icon(Icons.shield_rounded, size: 72, color: Colors.blue),
                  SizedBox(height: 12),
                  Text('Guardian IoT v2.0.0',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                    'Desenvolvido utilizando Flutter e arquitetura desacoplada (SOLID/Clean), projetado para operação contínua e em tempo real com microcontroladores ESP32 nativos através do protocolo leve MQTT.'),
              ),
            ),
            const Spacer(),
            ListTile(
              title: const Text('Repositório do Projeto'),
              subtitle: const Text('Acessar código fonte no GitHub'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () async {
                final url = Uri.parse('https://github.com/');
                if (await canLaunchUrl(url)) await launchUrl(url);
              },
            )
          ],
        ),
      ),
    );
  }
}
