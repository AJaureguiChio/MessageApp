import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class LanguageService {
  static int selection = 0;
  static Map<String, dynamic> _language = {};
  static final List<String> _languageOption = ["es", "en"];

  static ValueNotifier<int> languageNotifier = ValueNotifier<int>(selection);

  static Future<void> loadJson() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/language.json',
      );
      final data = await json.decode(response);

      _language = data[_languageOption[selection]];

      print(_language["go_to_login"]);
    } catch (e) {
      print("Error cargando Json: $e");
    }
  }

  static Future<void> changeLanguage() async {
    if (selection <= 0) {
      selection += 1;
    } else {
      selection = 0;
    }

    languageNotifier.value = selection;
  }

  static String textJsonReference(stringReference) {
    return _language[stringReference] ?? "??$stringReference??";
  }
}
