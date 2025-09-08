import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'firebase_options.dart'; // generado por flutterfire configure
import 'services/language_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await [Permission.camera, Permission.microphone].request();

  await LanguageService.loadJson();
  runApp(
  ValueListenableBuilder<int>(
    valueListenable: LanguageService.languageNotifier,
    builder: (_, __, ___) => const MyApp(),
  ),
);
}
