import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../services/webrtc_service.dart';
import '../screens/call_screen.dart';
import 'chat_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  late final String currentUid;

  @override
  void initState() {
    super.initState();
    currentUid = FirebaseAuth.instance.currentUser!.uid;
    // Borrar offers viejas ANTES de que el Stream las vea
    FirebaseFirestore.instance
        .collectionGroup('signals')
        .where('calleeId', isEqualTo: currentUid)
        .where('type', isEqualTo: 'offer')
        .get()
        .then(
          (snap) => Future.wait(snap.docs.map((d) => d.reference.delete())),
        );
  }

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: chatService.getUsers(),
              builder: (context, snap) {
                if (snap.hasError)
                  return Center(child: Text('Error: ${snap.error}'));
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
          ),
          // INDICADOR DE LLAMADA ENTRANTE
          StreamBuilder<bool>(
            stream: _incomingCallStream(currentUid),
            builder: (_, callSnap) {
              final hasCall = callSnap.data ?? false;
              if (hasCall) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showMaterialBanner(
                    MaterialBanner(
                      content: const Text('📹 Llamada entrante'),
                      leading: const Icon(
                        Icons.video_call,
                        color: Colors.white,
                      ),
                      backgroundColor: Colors.blue,
                      actions: [
                        TextButton(
                          onPressed: () async {
                            ScaffoldMessenger.of(
                              context,
                            ).hideCurrentMaterialBanner();
                            try {
                              await _acceptCall(context, currentUid);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error al unirse: $e')),
                              );
                            }
                          },
                          child: const Text(
                            'VER',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        TextButton(
                          onPressed: () => ScaffoldMessenger.of(
                            context,
                          ).hideCurrentMaterialBanner(),
                          child: const Text(
                            'IGNORAR',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                });
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Stream<bool> _incomingCallStream(String myUid) {
    return FirebaseFirestore.instance
        .collectionGroup('signals')
        .where('calleeId', isEqualTo: myUid)
        .where('type', isEqualTo: 'offer')
        .snapshots()
        .map((snap) {
          print(
            '🔎 Docs encontrados por Stream: ${snap.docs.length}',
          ); // ← nuevo
          return snap.docs.isNotEmpty;
        });
  }

  Future<void> _acceptCall(BuildContext context, String myUid) async {
    final snap = await FirebaseFirestore.instance
        .collectionGroup('signals')
        .where('calleeId', isEqualTo: myUid)
        .where('type', isEqualTo: 'offer')
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return;

    final doc = snap.docs.first;
    final data = doc.data();
    final callerId = data['callerId'] as String;
    final roomId = ([myUid, callerId]..sort()).join('_');

    await doc.reference.delete(); // borrar offer

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CallScreen(roomId: roomId, otherUid: callerId, amICaller: false),
      ),
    );
  }
}
