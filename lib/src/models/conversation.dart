import 'package:hive/hive.dart';
import '../chatbot/chat_message.dart';

part 'conversation.g.dart';

@HiveType(typeId: 0)
class Conversation {
  @HiveField(0)
  final String id; // Identificador único de la conversación

  @HiveField(1)
  final String title; // Título de la conversación

  @HiveField(2)
  final List<ChatMessage> messages; // Lista de mensajes

  Conversation({required this.id, required this.title, required this.messages});
}
