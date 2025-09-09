import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    LanguageService.loadJson();

    final authService = AuthService();
    // final email = authService.currentUser?.email ?? 'Usuario';

    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService.textJsonReference("home")),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/users'),
          child: const Text('Ver chats'),
        ),
      ),
    );
  }
}
