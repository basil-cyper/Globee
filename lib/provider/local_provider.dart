import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  void _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('Lang') ?? 'eng';
    _locale = Locale(langCode == 'arb' ? 'ar' : 'en');
    notifyListeners();
  }

  void setLocale(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('Lang', code);
    _locale = Locale(code == 'arb' ? 'ar' : 'en');
    notifyListeners();
  }
}
