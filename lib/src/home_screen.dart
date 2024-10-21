// lib/src/home_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_screen.dart';
import 'gps_screen.dart';
import 'qr_scanner_screen.dart';
import 'sensor_screen.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  final String universityLogo = 'assets/LOGO.jpg';
  final String degree = 'Ingeniería en Desarrollo de Software';
  final String subject = 'Programación para Móviles';
  final String group = '9B';
  final String studentName = 'CHRISTIAN DARINEL ESCOBAR GUILLEN';
  final String studentId = '221192';
  final String repositoryLink = 'https://github.com/DarinelGuillen/ChatBot';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información del Estudiante'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Logo de la universidad
            CircleAvatar(
              radius: 80,
              backgroundImage: AssetImage(universityLogo),
            ),
            const SizedBox(height: 16),
            // Datos del estudiante
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text(studentName),
                subtitle: Text('Matrícula: $studentId'),
              ),
            ),
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.school),
                title: Text(degree),
                subtitle: Text('Grupo: $group'),
              ),
            ),
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.book),
                title: Text(subject),
              ),
            ),
            const SizedBox(height: 16),
            // Botón para ver el repositorio
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final Uri url = Uri.parse(repositoryLink);
                  if (!await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  )) {
                    throw 'No se pudo abrir la URL: $url';
                  }
                } catch (e) {
                  print('Error al abrir el enlace: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'No se pudo abrir el enlace al repositorio: $e')),
                  );
                }
              },
              icon: const Icon(Icons.link),
              label: const Text('Ver repositorio'),
            ),
            const SizedBox(height: 16),
            // Menú de navegación
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, ChatScreen.routeName);
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Chat'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(16),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, GPSScreen.routeName);
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text('GPS'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(16),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, QRScannerScreen.routeName);
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Escanear QR'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(16),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, SensorScreen.routeName);
                  },
                  icon: const Icon(Icons.sensors),
                  label: const Text('Sensores'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(16),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
