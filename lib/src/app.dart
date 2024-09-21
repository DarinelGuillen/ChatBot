import 'package:flutter/material.dart';
import 'chatbot/chat_message.dart';
import 'chatbot/chat_input.dart';
import 'settings/settings_controller.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.settingsController});

  final SettingsController settingsController;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];

  // Lista para almacenar el historial de mensajes que será enviado a la API
  final List<Map<String, String>> _chatHistory = [];

  // Límite de mensajes en el historial para evitar el envío de demasiados tokens
  final int _messageHistoryLimit = 10;

  @override
  void initState() {
    super.initState();

    // Añadimos el mensaje del sistema para configurar el tono sarcástico y el contexto inicial
    _chatHistory.add({
      'role': 'system',
      'content': 'You are a sarcastic and playful assistant.'
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text;
    if (text.isEmpty) return;

    // Agrega el mensaje del usuario a la interfaz de usuario
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });

    // Agrega el mensaje del usuario al historial que será enviado a la API
    _chatHistory.add({'role': 'user', 'content': text});

    // Limita el historial a los últimos 10 mensajes
    if (_chatHistory.length > _messageHistoryLimit * 2) {
      _chatHistory.removeRange(0, _chatHistory.length - _messageHistoryLimit * 2);
    }

    _controller.clear();

    // Llama a la API para obtener la respuesta de ChatGPT
    final response = await _getChatGPTResponse();

    setState(() {
      _messages.add(ChatMessage(text: response, isUser: false));
    });

    // Agrega la respuesta de ChatGPT al historial
    _chatHistory.add({'role': 'assistant', 'content': response});
  }

  Future<String> _getChatGPTResponse() async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return 'Error: La clave de API no está configurada.';
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': 'gpt-3.5-turbo',
      'messages': _chatHistory,  // Envía solo los últimos mensajes del historial
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        return 'Error: ${response.statusCode} - ${response.reasonPhrase}';
      }
    } catch (e) {
      return 'Error al conectar con la API de OpenAI: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatbot con ChatGPT',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: widget.settingsController.themeMode,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Chatbot con ChatGPT'),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final messageBackground = message.isUser
                      ? Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue[300]
                          : Colors.blue[100]
                      : Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]
                          : Colors.grey[300];

                  return ListTile(
                    title: Align(
                      alignment: message.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: messageBackground,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(message.text),
                      ),
                    ),
                  );
                },
              ),
            ),
            ChatInput(
              controller: _controller,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
