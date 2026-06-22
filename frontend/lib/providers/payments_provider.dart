import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/payments_service.dart';

class PaymentsProvider extends ChangeNotifier {
  final PaymentsService _paymentsService = PaymentsService();
  
  bool _isLoading = false;
  String? _lastSelectedPlan;
  String? _error;
  
  bool get isLoading => _isLoading;
  String? get lastSelectedPlan => _lastSelectedPlan;
  String? get error => _error;

  /// Carrega o último plano selecionado do armazenamento local
  Future<void> loadLastSelectedPlan() async {
    final prefs = await SharedPreferences.getInstance();
    _lastSelectedPlan = prefs.getString('last_selected_plan');
    notifyListeners();
  }

  /// Salva o plano selecionado no armazenamento local
  Future<void> _saveLastSelectedPlan(String plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_selected_plan', plan);
    _lastSelectedPlan = plan;
  }

  /// Limpa o último plano selecionado
  Future<void> clearLastSelectedPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_selected_plan');
    _lastSelectedPlan = null;
    notifyListeners();
  }

  /// Cria uma sessão de checkout para o plano selecionado
  Future<String?> createCheckoutSession(String plan) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _saveLastSelectedPlan(plan);
      final checkoutUrl = await _paymentsService.createPlanCheckout(plan);
      _isLoading = false;
      notifyListeners();
      return checkoutUrl;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Cria uma sessão do portal de cobrança para o usuário
  Future<String?> createBillingPortalSession() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final portalUrl = await _paymentsService.createPortalSession();
      _isLoading = false;
      notifyListeners();
      return portalUrl;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
