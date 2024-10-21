// lib/src/app.dart
import 'package:flutter/material.dart';
import 'settings/settings_controller.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'gps_screen.dart';
import 'qr_scanner_screen.dart';
import 'sensor_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.settingsController});

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppMovil que utiliza las herramientas del teléfono',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: settingsController.themeMode,
      initialRoute: HomeScreen.routeName,
      routes: {
        HomeScreen.routeName: (context) => const HomeScreen(),
        ChatScreen.routeName: (context) => const ChatScreen(),
        GPSScreen.routeName: (context) => const GPSScreen(),
        QRScannerScreen.routeName: (context) => const QRScannerScreen(),
        SensorScreen.routeName: (context) => const SensorScreen(),
      },
    );
  }
}
