import 'package:flutter/material.dart';
import 'chatbot/chat_message.dart';
import 'chatbot/chat_input.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import 'models/conversation.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  static const routeName = '/chat';

  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  // Lista de mensajes actuales
  List<ChatMessage> _messages = [];

  // Lista para almacenar el historial de mensajes que será enviado a la API
  List<Map<String, String>> _chatHistory = [];

  // Límite de mensajes en el historial para evitar el envío de demasiados tokens
  final int _messageHistoryLimit = 10;

  // Instancia de FlutterTts
  final FlutterTts _flutterTts = FlutterTts();

  // Lista de voces disponibles
  List<dynamic> _voices = [];

  // Estado para indicar si el modo de voz está activo
  bool _voiceModeActive = false;

  // Voz seleccionada
  String? _selectedVoice;

  // Caja de Hive para conversaciones
  late Box _conversationBox;

  // Identificador único para la conversación actual
  late String _currentConversationId;

  // Título de la conversación actual
  String _currentConversationTitle = '+ Nueva Conversación';

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

    // Inicializar Hive
    _conversationBox = Hive.box('chat_histories');

    // Iniciar nueva conversación
    _startNewConversation();
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

    // Agrega el mensaje del usuario a la interfaz de usuario
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });

    // Agrega el mensaje del usuario al historial que será enviado a la API
    _chatHistory.add({'role': 'user', 'content': text});

    // Limita el historial a los últimos mensajes
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

    // Guarda la conversación actualizada en Hive
    _saveCurrentConversation();

    // Reproducir la respuesta de ChatGPT
    await _speak(response);
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
        await _flutterTts
            .setVoice({"name": voice['name'], "locale": voice['locale']});
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
                    await _flutterTts.setVoice(
                        {"name": voice['name'], "locale": voice['locale']});
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

  // Iniciar una nueva conversación
  void _startNewConversation() {
    setState(() {
      _currentConversationId = const Uuid().v4();
      _currentConversationTitle = 'Conversación ${_conversationBox.length + 1}';
      _messages = [];
      _chatHistory = [];

      // Mensaje del sistema para contexto
      _chatHistory.add({
        'role': 'system',
        'content':
            'You are a friendly English teacher who helps users learn English. Always respond in English and encourage the user to practice.'
      });
    });
  }

  // Guardar la conversación actual en Hive
  void _saveCurrentConversation() {
    final conversation = Conversation(
      id: _currentConversationId,
      title: _currentConversationTitle,
      messages: _messages,
    );
    _conversationBox.put(_currentConversationId, conversation);
  }

  // Cargar una conversación desde Hive
  void _loadConversation(String conversationId) {
    final conversation = _conversationBox.get(conversationId) as Conversation;
    setState(() {
      _currentConversationId = conversation.id;
      _currentConversationTitle = conversation.title;
      _messages = conversation.messages;
      _chatHistory = [];

      // Reconstruir el chatHistory para el contexto de la API
      _chatHistory.add({
        'role': 'system',
        'content':
            'You are a friendly English teacher who helps users learn English. Always respond in English and encourage the user to practice.'
      });

      for (var message in conversation.messages) {
        _chatHistory.add({
          'role': message.isUser ? 'user' : 'assistant',
          'content': message.text,
        });
      }
    });
  }

  // Mostrar el menú lateral con las conversaciones guardadas
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            child: Text('Historial de Conversaciones'),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Nueva Conversación'),
            onTap: () {
              Navigator.pop(context);
              _startNewConversation();
            },
          ),
          ..._conversationBox.values.map((conversation) {
            final conv = conversation as Conversation;
            return ListTile(
              leading: const Icon(Icons.chat),
              title: Text(conv.title),
              onTap: () {
                Navigator.pop(context);
                _loadConversation(conv.id);
              },
            );
          }),
        ],
      ),
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
        title: Text(_currentConversationTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.voice_over_off),
            onPressed: _showVoiceSelectionDialog,
            tooltip: 'Seleccionar Voz',
          ),
        ],
      ),
      drawer: _buildDrawer(),
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
              // Campo de texto y botón de enviar
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
