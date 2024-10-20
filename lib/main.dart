import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';
import 'src/chatbot/chat_message.dart';
import 'src/models/conversation.dart';

Future<void> main() async {
  print('Current Directory: ${Directory.current.path}');

  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Registra los adaptadores de Hive
  Hive.registerAdapter(ChatMessageAdapter());
  Hive.registerAdapter(ConversationAdapter());

  // Abre la caja de Hive
  await Hive.openBox('chat_histories');

  final settingsController = SettingsController(SettingsService());
  await settingsController.loadSettings();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Error al cargar el archivo .env: $e');
    return;
  }

  // Verificar si la clave API existe
  final apiKey = dotenv.env['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Error: La clave de API no está configurada. Por favor, agrégala en el archivo .env');
    return;
  }

  runApp(MyApp(settingsController: settingsController));
}
