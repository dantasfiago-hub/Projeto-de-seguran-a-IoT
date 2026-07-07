import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/storage/storage_service.dart';
import 'providers/settings_provider.dart';
import 'providers/event_provider.dart';
import 'providers/stats_provider.dart';
import 'providers/security_provider.dart';

import 'screens/dashboard/dashboard_screen.dart';

String? _fatalError;
String? _fatalStack;

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      _fatalError = details.exceptionAsString();
      _fatalStack = details.stack.toString();
      FlutterError.presentError(details);
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
                create: (_) => SettingsProvider(storageService)),
            ChangeNotifierProvider(create: (_) => EventProvider()),
            ChangeNotifierProvider(create: (_) => StatsProvider()),
            ChangeNotifierProxyProvider<EventProvider, SecurityProvider>(
              create: (_) => SecurityProvider(),
              update: (_, eventProv, secProv) {
                secProv!.updateEventProvider(eventProv);
                return secProv;
              },
            ),
          ],
          child: const MyApp(),
        ),
      );
    } catch (e, stack) {
      _fatalError = e.toString();
      _fatalStack = stack.toString();
      runApp(_BootErrorApp(error: _fatalError!, stack: _fatalStack!));
    }
  }, (error, stack) {
    debugPrint('--- [FATAL] Erro não tratado: $error\n$stack ---');
    _fatalError = error.toString();
    _fatalStack = stack.toString();
  });
}

class _BootErrorApp extends StatelessWidget {
  final String error;
  final String stack;

  const _BootErrorApp({required this.error, required this.stack});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Falha crítica ao iniciar o app',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900)),
                const SizedBox(height: 12),
                Text(error, style: TextStyle(color: Colors.red.shade900)),
                const SizedBox(height: 12),
                Text(stack,
                    style: TextStyle(fontSize: 10, color: Colors.red.shade700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Guardian IoT',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
          brightness: Brightness.dark),
      home: const DashboardScreen(),
    );
  }
}
