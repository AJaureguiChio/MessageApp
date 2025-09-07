import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: chatService.getUsers(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());

          final users = snap.data!;
          if (users.isEmpty)
            return const Center(child: Text('No hay usuarios'));

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (_, i) => ListTile(
              leading: const Icon(Icons.person),
              title: Text(users[i]['email']),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    otherUid: users[i]['uid'],
                    otherEmail: users[i]['email'],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
