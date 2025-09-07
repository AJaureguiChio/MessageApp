import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  /* ---------- 1. Obtener usuarios disponibles (todos menos yo) ---------- */
  Stream<List<Map<String, dynamic>>> getUsers() {
    return _db
        .collection('users')
        .where(FieldPath.documentId, isNotEqualTo: currentUid)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => {'uid': d.id, 'email': d['email']}).toList(),
        );
  }

  /* ---------- 2. Obtener / crear chatId único entre dos personas ---------- */
  Future<String> _getChatId(String otherUid) async {
    final ids = [currentUid, otherUid]..sort();
    return ids.join('_'); // ej: "aaa_bbb"
  }

  /* ---------- 3. Enviar mensaje ---------- */
  Future<void> sendMessage(String text, String otherUid) async {
    final chatId = await _getChatId(otherUid);
    final msg = ChatMessage(
      id: '',
      senderId: currentUid,
      text: text.trim(),
      timestamp: DateTime.now(),
    );
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(msg.toFirestore());
  }

  /* ---------- 4. Escuchar mensajes ---------- */
  Stream<List<ChatMessage>> messagesStream(String otherUid) async* {
    final chatId = await _getChatId(otherUid);
    yield* _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ChatMessage.fromFirestore(d.data(), d.id))
              .toList(),
        );
  }
}
