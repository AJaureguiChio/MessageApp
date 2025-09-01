import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/role_service.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final roleService = RoleService();
    final email = authService.currentUser?.email ?? 'Administrador';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.red, // Color distintivo para admin
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
            const Icon(Icons.admin_panel_settings, size: 100, color: Colors.red),
            const SizedBox(height: 20),
            Text('¡Bienvenido, administrador $email! 👑', 
                 style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('Funciones exclusivas de administrador:',
                 style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Aquí puedes agregar funciones específicas de admin
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Función de administrador'))
                );
              },
              child: const Text('Gestionar usuarios'),
            ),
          ],
        ),
      ),
    );
  }
}