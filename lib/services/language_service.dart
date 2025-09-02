import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:async';

class LanguageService {
  Map <String, dynamic> _language = {};

  Future<void> _loadJson() async {
    try {
      final String response = await rootBundle.loadString('assets/language.json');
    final data = await json.decode(response);

    _language = data["es"];

    print(_language["registro_boton"]);
    }
    catch (e) {
      print ("Error cargando Json: $e");
    }
    
  }
}