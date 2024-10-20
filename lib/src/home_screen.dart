import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  final String universityLogo = 'assets/LOGO.jpg';
  final String degree = 'IDS';
  final String subject = 'Programación para móviles';
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
            Image.asset(universityLogo),
            const SizedBox(height: 16),
            Text(
              'Carrera: $degree',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Materia: $subject',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Grupo: $group',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Nombre del alumno: $studentName',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Matrícula: $studentId',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
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
                    SnackBar(content: Text('No se pudo abrir el enlace al repositorio: $e')),
                  );
                }
              },
              icon: const Icon(Icons.link),
              label: const Text('Ver repositorio'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, ChatScreen.routeName);
              },
              icon: const Icon(Icons.chat),
              label: const Text('Ir al Chat'),
            ),
          ],
        ),
      ),
    );
  }
}
