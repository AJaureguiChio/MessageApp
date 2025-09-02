import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    LanguageService.loadJson();

    final authService = AuthService();
    final email = authService.currentUser?.email ?? 'Usuario';

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
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            Text(LanguageService.textJsonReference("welcome") + email, 
                 style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            Text(LanguageService.textJsonReference("you_regular"),
                 style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}