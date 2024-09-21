import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(String) onVoiceInput;

  const ChatInput({
    required this.controller,
    required this.onSend,
    required this.onVoiceInput,
    super.key,
  });

  @override
  _ChatInputState createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _isListening = false;
  late stt.SpeechToText _speech;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (errorNotification) {
          setState(() => _isListening = false);
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: 'en_US', // Aseguramos que el reconocimiento de voz sea en inglés
          onResult: (result) {
            if (result.finalResult) {
              widget.onVoiceInput(result.recognizedWords);
              _speech.stop();
              setState(() => _isListening = false);
            }
          },
        );
      }
    } else {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          // Campo de texto para el mensaje
          Expanded(
            child: TextField(
              controller: widget.controller,
              maxLines: 3,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Type a message...', // Texto en inglés
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.send,
              onSubmitted: (value) {
                widget.onSend();
              },
            ),
          ),
          const SizedBox(width: 8),
          // Botón de micrófono
          GestureDetector(
            onTap: _listen,
            child: Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: _isListening ? Colors.redAccent : Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 24.0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Botón de enviar
          GestureDetector(
            onTap: widget.onSend,
            child: Container(
              padding: const EdgeInsets.all(10.0),
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 24.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
