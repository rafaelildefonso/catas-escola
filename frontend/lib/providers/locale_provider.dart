import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/token_holder.dart';
import '../l10n/app_localizations.dart';

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;
  static const String _prefsKey = 'selected_language_code';

  Locale? get locale => _locale;

  LocaleProvider() {
    // Não chama loadStoredLocale() no construtor para evitar race condition
    // O main.dart vai chamar loadStoredLocale() antes do runApp
  }

  Future<void> loadStoredLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? languageCode = prefs.getString(_prefsKey);
      
      debugPrint('LocaleProvider: Loading stored locale: $languageCode');
      
      if (languageCode != null) {
        _locale = Locale(languageCode);
      } else {
        _locale = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('LocaleProvider: Error loading stored locale: $e');
    }
  }

  Future<void> loadLocaleFromDatabase(String? languageCode) async {
    try {
      debugPrint('LocaleProvider: Loading locale from database: $languageCode');
      
      if (languageCode != null && languageCode.isNotEmpty) {
        final isSupported = AppLocalizations.supportedLocales.any(
          (l) => l.languageCode == languageCode,
        );
        
        if (isSupported) {
          _locale = Locale(languageCode);
          await _saveLocaleToPrefs(_locale);
          notifyListeners();
          debugPrint('LocaleProvider: Successfully loaded locale from database: $languageCode');
        } else {
          debugPrint('LocaleProvider: Language from database not supported: $languageCode');
        }
      } else {
        debugPrint('LocaleProvider: No language in database, keeping current locale');
      }
    } catch (e) {
      debugPrint('LocaleProvider: Error loading locale from database: $e');
    }
  }

  void setLocale(Locale? locale) {
    debugPrint('LocaleProvider: Setting locale to: ${locale?.languageCode}');
    
    if (_locale?.languageCode == locale?.languageCode) return;

    if (locale != null) {
      final isSupported = AppLocalizations.supportedLocales.any(
        (l) => l.languageCode == locale.languageCode,
      );
      if (!isSupported) {
        debugPrint('LocaleProvider: Locale ${locale.languageCode} not supported');
        return;
      }
    }

    _locale = locale;
    notifyListeners();
    _saveLocaleToPrefs(locale);
    _saveLocaleToDatabase(locale);
  }

  Future<void> _saveLocaleToPrefs(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
  }

  Future<void> _saveLocaleToDatabase(Locale? locale) async {
    try {
      if (AppConfig.isDemoMode) {
        debugPrint('LocaleProvider: Skipping database save in demo mode');
        return;
      }
      final token = TokenHolder().token;
      if (token == null) {
        debugPrint('LocaleProvider: No user logged in, skipping database save');
        return;
      }

      final languageCode = locale?.languageCode;
      await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/profiles/me'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"language": languageCode}),
      );
      debugPrint('LocaleProvider: Saved locale to database: $languageCode');
    } catch (e) {
      debugPrint('LocaleProvider: Error saving locale to database: $e');
    }
  }

  void clearLocale() {
    _locale = null;
    notifyListeners();
    _saveLocaleToPrefs(null);
    _saveLocaleToDatabase(null);
  }
}
