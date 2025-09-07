import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../widgets/custom_textfield.dart';
import '../services/language_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isPasswordVisible = false;
  String _selectedRole = 'user'; // Valor por defecto

  void _register() async {
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    try {
      final user = await _authService.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _selectedRole,
      );

      if (user != null) {
        // await user.sendEmailVerification();
        // await _authService.logout();

        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text(
        //       'Registro exitoso. Te enviamos un correo de verificación.',
        //     ),
        //   ),
        // );

        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'))
      );
    }
  }

  void _goToLogin() => Navigator.pop(context);
  @override


  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LanguageService.textJsonReference("register_button"))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomTextField(
                controller: _emailController,
                label:LanguageService.textJsonReference("email_address"),
                // keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: LanguageService.textJsonReference("password"),
                obscureText: !_isPasswordVisible,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _confirmController,
                label: LanguageService.textJsonReference("confirm_password"),
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              const SizedBox(height: 16),
              // Selector de rol
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: LanguageService.textJsonReference("user_type"),
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'user',
                    child: Text(LanguageService.textJsonReference("user_type_normal")),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text(LanguageService.textJsonReference("user_type_admin")),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _register,
                  child: Text(LanguageService.textJsonReference("register_button")),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _goToLogin,
                child: Text(LanguageService.textJsonReference("go_to_login")),
              ),
              
              ElevatedButton(
                onPressed: (){
                  LanguageService.loadJson();
                  LanguageService.changeLanguage();
                  setState(() {});
              },
              child : Center(child: Text("Idioma")),)

            ],
          ),
        ),
      ),
    );
  }
}