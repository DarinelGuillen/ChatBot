// lib/src/chat_screen.dart
import 'package:flutter/material.dart';
import 'chatbot/chat_input.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

class ChatScreen extends StatefulWidget {
  static const routeName = '/chat';

  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  // Lista de mensajes actuales
  List<Map<String, dynamic>> _messages = [];

  // Lista para almacenar el historial de mensajes que será enviado a la API
  List<Map<String, String>> _chatHistory = [];

  // Límite de mensajes en el historial para evitar el envío de demasiados tokens
  final int _messageHistoryLimit = 1;

  // Instancia de FlutterTts
  final FlutterTts _flutterTts = FlutterTts();

  // Lista de voces disponibles
  List<dynamic> _voices = [];

  // Estado para indicar si el modo de voz está activo
  bool _voiceModeActive = false;

  // Estado para indicar si se está obteniendo una respuesta
  bool _isFetchingResponse = false;

  // Voz seleccionada
  String? _selectedVoice;

  @override
  void initState() {
    super.initState();

    // Solicitar permisos
    _requestPermissions();

    // Configurar FlutterTts
    _initializeTts();

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

    // Seleccionar una voz específica por defecto (inglés)
    var selectedVoice = _voices.firstWhere(
        (voice) => voice['locale'].toString().contains('en-US'),
        orElse: () => null);

    if (selectedVoice != null) {
      await _flutterTts.setVoice({
        "name": selectedVoice['name'],
        "locale": selectedVoice['locale']
      });
      _selectedVoice = selectedVoice['name'];
    }

    await _flutterTts.setLanguage("en-US"); // Inglés
    await _flutterTts.setPitch(1.2); // Ajusta el tono
    await _flutterTts.setSpeechRate(0.5); // Ajusta la velocidad
    await _flutterTts.setVolume(1.0); // Asegura que el volumen esté al máximo
    await _flutterTts.awaitSpeakCompletion(true); // Espera a que termine de hablar
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.speech.request();
  }

  Future<void> _sendMessage({String? voiceText}) async {
    final text = voiceText ?? _controller.text;
    if (text.isEmpty) return;

    // Indicar que se está procesando la solicitud
    setState(() {
      _isFetchingResponse = true;
      _messages.add({'text': text, 'isUser': true});
      _chatHistory.add({'role': 'user', 'content': text});
    });

    // Limitar el historial a los últimos mensajes
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
      _messages.add({'text': response, 'isUser': false});
      _chatHistory.add({'role': 'assistant', 'content': response});
      _isFetchingResponse = false; // Finalizar el estado de carga
    });

    // Condicionalmente reproducir la respuesta si fue enviada por voz
    if (voiceText != null) {
      await _speak(response);
    }
  }

  Future<String> _getChatGPTResponse() async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return 'Error: La clave API no está configurada.';
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    // Construye el cuerpo de la solicitud con el historial completo
    final body = jsonEncode({
      'model': 'gpt-3.5-turbo',
      'messages': _chatHistory,
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

  Future<void> _speak(String text) async {
    if (_selectedVoice != null) {
      var voice = _voices.firstWhere(
          (voice) => voice['name'] == _selectedVoice,
          orElse: () => null);
      if (voice != null) {
        await _flutterTts.setVoice({
          "name": voice['name'],
          "locale": voice['locale']
        });
      }
    }

    setState(() {
      _voiceModeActive = true;
    });

    _flutterTts.setErrorHandler((msg) {
      print("Error de TTS: $msg");
      setState(() {
        _voiceModeActive = false;
      });
    });

    await _flutterTts.speak(text);
  }

  void _handleVoiceInput(String voiceText) {
    _sendMessage(voiceText: voiceText);
  }

  // Función para mostrar un diálogo con las voces disponibles
  void _showVoiceSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar Voz'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _voices.length,
              itemBuilder: (context, index) {
                var voice = _voices[index];
                return ListTile(
                  title: Text("${voice['name']} (${voice['locale']})"),
                  onTap: () async {
                    await _flutterTts.setVoice({
                      "name": voice['name'],
                      "locale": voice['locale']
                    });
                    setState(() {
                      _selectedVoice = voice['name'];
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.voice_over_off),
            onPressed: _showVoiceSelectionDialog,
            tooltip: 'Seleccionar Voz',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Área de historial de conversación
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final messageBackground = message['isUser']
                        ? Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue[300]
                            : Colors.blue[100]
                        : Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[700]
                            : Colors.grey[300];

                    return ListTile(
                      title: Align(
                        alignment: message['isUser']
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: messageBackground,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(message['text']),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Campo de texto y botón de enviar
              ChatInput(
                controller: _controller,
                onSend: () => _sendMessage(),
                onVoiceInput: _handleVoiceInput,
              ),
            ],
          ),
          // Superposición para indicar que se está esperando una respuesta
          if (_isFetchingResponse)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpinKitCircle(
                      color: Colors.white,
                      size: 50.0,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Obteniendo respuesta...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
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
                      'Modo Voz Activo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Escuchando...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
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
