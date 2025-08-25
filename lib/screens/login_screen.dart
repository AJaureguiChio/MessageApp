import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isPasswordVisible = false;

  void _login() async {
    try {
      final user = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
  if (!user.emailVerified) {
    await _authService.logout(); // cerrar sesión

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text('Debes verificar tu correo antes de iniciar sesión.'),
            ),
            TextButton(
              onPressed: () async {
                await user.sendEmailVerification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Correo de verificación reenviado.'),
                  ),
                );
              },
              child: const Text(
                'Reenviar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
    return;
  }

  Navigator.pushReplacementNamed(context, '/home');
}
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }


  void _goToRegister() => Navigator.pushNamed(context, '/register');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FlutterLogo(size: 100),
              const SizedBox(height: 32),
              CustomTextField(controller: _emailController, label: 'Correo electrónico'),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: 'Contraseña',
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _login, child: const Text('Iniciar sesión')),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _goToRegister, child: const Text('¿No tienes cuenta? Regístrate')),
            ],
          ),
        ),
      ),
    );
  }
}
