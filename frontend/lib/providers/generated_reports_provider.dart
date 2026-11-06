import 'package:flutter/foundation.dart';

import '../data/generated_reports_repository.dart';

class GeneratedReportsProvider extends ChangeNotifier {
  final GeneratedReportsRepository _repository = GeneratedReportsRepository();
  List<Map<String, dynamic>> _reports = const [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _reports = await _repository.listar();
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
