import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromFirestore(Map<String, dynamic> data, String id) =>
      ChatMessage(
        id: id,
        senderId: data['senderId'],
        text: data['text'],
        timestamp: (data['timestamp'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toFirestore() => {
    'senderId': senderId,
    'text': text,
    'timestamp': FieldValue.serverTimestamp(),
  };
}
