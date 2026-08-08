import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

enum AppPage {
  chat,
  automations,
  integrations,
  settings,
  history,
  pricing,
  dashboard,
  crud,
  relatorios,
}

class NavigationProvider with ChangeNotifier {
  AppPage _currentPage = AppPage.chat;
  static const String _kLastPageKey = 'last_app_page';

  NavigationProvider() {
    _loadState();
  }

  Future<void> _loadState() async {
    if (kIsWeb) return; 
    try {
      final prefs = await SharedPreferences.getInstance();
      final pageIndex = prefs.getInt(_kLastPageKey);
      if (pageIndex != null && pageIndex < AppPage.values.length) {
        _currentPage = AppPage.values[pageIndex];
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveState() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLastPageKey, _currentPage.index);
    } catch (_) {}
  }

  AppPage get currentPage => _currentPage;

  int get currentIndex => _currentPage.index;

  void setPage(AppPage page) {
    if (_currentPage != page) {
      _currentPage = page;
      notifyListeners();
      _saveState();
    }
  }

  void reset() {
    if (_currentPage != AppPage.chat) {
      _currentPage = AppPage.chat;
      notifyListeners();
    }
  }

  void setIndex(int index) {
    if (index >= 0 && index < AppPage.values.length) {
      setPage(AppPage.values[index]);
    }
  }

  bool isCurrentPage(AppPage page) => _currentPage == page;
}
