import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/role_service.dart';
import '../widgets/custom_textfield.dart';
import '../services/language_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final RoleService _roleService = RoleService();
  bool _isPasswordVisible = false;

  void _login() async {
    await LanguageService.loadJson();

    try {
      final user = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        // if (!user.emailVerified) {
        //   await _authService.logout();
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: Row(
        //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //         children: [
        //           const Expanded(
        //             child: Text('Debes verificar tu correo antes de iniciar sesión.'),
        //           ),
        //           TextButton(
        //             onPressed: () async {
        //               await user.sendEmailVerification();
        //               ScaffoldMessenger.of(context).showSnackBar(
        //                 const SnackBar(
        //                   content: Text('Correo de verificación reenviado.'),
        //                 ),
        //               );
        //             },
        //             child: const Text(
        //               'Reenviar',
        //               style: TextStyle(color: Colors.white),
        //             ),
        //           ),
        //         ],
        //       ),
        //     ),
        //   );
        //   return;
        // }

        // Verificar el rol del usuario y redirigir según corresponda
        final role = await _roleService.getUserRole(user.uid);
        
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/adminHome');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'))
      );
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
              Icon(
                Icons.question_answer,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              CustomTextField(controller: _emailController, label: LanguageService.textJsonReference("email_address")),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: LanguageService.textJsonReference("password"),
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _login, child: Text(LanguageService.textJsonReference("login_button"))),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _goToRegister, child: Text(LanguageService.textJsonReference("go_to_register"))),
            ],
          ),
        ),
      ),
    );
  }
}