import 'package:flutter/material.dart';
import 'chatbot/chat_message.dart';
import 'chatbot/chat_input.dart';
import 'settings/settings_controller.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Para animaciones

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

  // Instancia de FlutterTts
  final FlutterTts _flutterTts = FlutterTts();

  // Lista de voces disponibles
  List<dynamic> _voices = [];

  // Estado para indicar si el modo de voz está activo
  bool _voiceModeActive = false;

  @override
  void initState() {
    super.initState();

    // Actualizar el mensaje del sistema para que actúe como un profesor de inglés amigable
    _chatHistory.add({
      'role': 'system',
      'content': 'You are a friendly English teacher who helps users learn English. Always respond in English and encourage the user to practice.'
    });

    // Configurar FlutterTts
    _initializeTts();

    // Solicitar permisos
    _requestPermissions();

    // Agregar listeners para FlutterTts
    _flutterTts.setStartHandler(() {
      setState(() {
        _voiceModeActive = true;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _voiceModeActive = false;
      });
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _voiceModeActive = false;
      });
    });
  }

  Future<void> _initializeTts() async {
    // Obtener todas las voces disponibles
    _voices = await _flutterTts.getVoices;

    // Seleccionar una voz específica (por ejemplo, una voz femenina en inglés)
    // Puedes imprimir las voces disponibles para elegir una
    // print(_voices);

    // Aquí seleccionamos la primera voz en inglés disponible
    var selectedVoice = _voices.firstWhere(
        (voice) => voice['locale'].toString().contains('en'),
        orElse: () => null);

    if (selectedVoice != null) {
      await _flutterTts.setVoice({"name": selectedVoice['name'], "locale": selectedVoice['locale']});
    }

    await _flutterTts.setLanguage("en-US"); // Aseguramos que la síntesis de voz sea en inglés
    await _flutterTts.setPitch(1.2); // Ajusta el tono según prefieras
    await _flutterTts.setSpeechRate(0.5); // Ajusta la velocidad según prefieras
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.speech.request();
  }

  Future<void> _sendMessage({String? voiceText}) async {
    final text = voiceText ?? _controller.text;
    if (text.isEmpty) return;

    // Agrega el mensaje del usuario a la interfaz de usuario
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });

    // Agrega el mensaje del usuario al historial que será enviado a la API
    _chatHistory.add({'role': 'user', 'content': text});

    // Limita el historial a los últimos 10 mensajes
    if (_chatHistory.length > _messageHistoryLimit * 2) {
      _chatHistory.removeRange(
          0, _chatHistory.length - _messageHistoryLimit * 2);
    }

    if (voiceText == null) {
      _controller.clear();
    }

    // Llama a la API para obtener la respuesta de ChatGPT
    final response = await _getChatGPTResponse();

    setState(() {
      _messages.add(ChatMessage(text: response, isUser: false));
    });

    // Agrega la respuesta de ChatGPT al historial
    _chatHistory.add({'role': 'assistant', 'content': response});

    // Reproducir la respuesta de ChatGPT
    _speak(response);
  }

  Future<String> _getChatGPTResponse() async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return 'Error: The API key is not configured.';
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': 'gpt-3.5-turbo',
      'messages': _chatHistory, // Envía solo los últimos mensajes del historial
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
      return 'Error connecting to OpenAI API: $e';
    }
  }

  Future<void> _speak(String text) async {
    setState(() {
      _voiceModeActive = true;
    });
    await _flutterTts.speak(text);
  }

  void _handleVoiceInput(String voiceText) {
    _sendMessage(voiceText: voiceText);
  }

  @override
  void dispose() {
    _controller.dispose();
    _flutterTts.stop();
    super.dispose();
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
        body: Stack(
          children: [
            Column(
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
                  onSend: () => _sendMessage(),
                  onVoiceInput: _handleVoiceInput,
                ),
              ],
            ),
            // Superposición para indicar modo de voz activo
            if (_voiceModeActive)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SpinKitWave(
                        color: Colors.white,
                        size: 50.0,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Voice Mode Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
