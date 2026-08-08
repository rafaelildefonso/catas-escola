import 'package:flutter/foundation.dart';
import '../data/relatorio_repository.dart';

/// Estado das funcionalidades de relatório/busca (além do CRUD básico).
class RelatorioProvider extends ChangeNotifier {
  final RelatorioRepository _repo = RelatorioRepository();

  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _runsFiltrados = [];
  int _runsTotal = 0;
  Map<String, dynamic>? _chat;
  List<Map<String, dynamic>> _mensagens = [];
  int _mensagensTotal = 0;

  bool _carregandoDashboard = false;
  bool _carregandoRuns = false;
  bool _carregandoChat = false;
  bool _carregandoBusca = false;
  String? _erro;

  String? _statusFiltro;
  String? _buscaFiltro;

  // ───────────────────────── Estado público ─────────────────────────

  Map<String, dynamic>? get dashboard => _dashboard;
  List<Map<String, dynamic>> get runsFiltrados => _runsFiltrados;
  int get runsTotal => _runsTotal;
  Map<String, dynamic>? get chat => _chat;
  List<Map<String, dynamic>> get mensagens => _mensagens;
  int get mensagensTotal => _mensagensTotal;

  bool get carregandoDashboard => _carregandoDashboard;
  bool get carregandoRuns => _carregandoRuns;
  bool get carregandoChat => _carregandoChat;
  bool get carregandoBusca => _carregandoBusca;
  String? get erro => _erro;

  bool get filtroRunsAtivo =>
      (_statusFiltro != null && _statusFiltro!.isNotEmpty) ||
      (_buscaFiltro != null && _buscaFiltro!.isNotEmpty);

  bool get temMaisRuns => _runsFiltrados.length < _runsTotal;

  // ─────────────────────────── Ações ─────────────────────────

  Future<void> carregarDashboard(String userId, {int dias = 7}) async {
    if (_carregandoDashboard) return;
    _carregandoDashboard = true;
    _erro = null;
    notifyListeners();
    try {
      _dashboard = await _repo.estatisticasDashboard(userId, dias: dias);
    } catch (e) {
      _erro = e.toString();
    } finally {
      _carregandoDashboard = false;
      notifyListeners();
    }
  }

  String _ordem = 'created_at';

  String get ordem => _ordem;

  Future<void> buscarRuns(
    String userId, {
    String? status,
    String? busca,
    String? ordem,
    bool carregarMais = false,
  }) async {
    if (_carregandoRuns) return;
    _carregandoRuns = true;
    _statusFiltro = status;
    _buscaFiltro = (busca ?? '').trim().isNotEmpty ? busca!.trim() : null;
    if (ordem != null) _ordem = ordem;
    _erro = null;
    notifyListeners();

    final deslocamento = carregarMais ? _runsFiltrados.length : 0;

    try {
      final resultado = await _repo.relatorioAutomacoes(
        userId: userId,
        status: _statusFiltro,
        busca: _buscaFiltro,
        ordem: _ordem,
        limite: 50,
        deslocamento: deslocamento,
      );
      final items = (resultado['items'] as List? ?? []).cast<Map<String, dynamic>>();
      _runsTotal = resultado['total'] as int? ?? items.length;
      _runsFiltrados = carregarMais ? [..._runsFiltrados, ...items] : items;
    } catch (e) {
      _erro = e.toString();
    } finally {
      _carregandoRuns = false;
      notifyListeners();
    }
  }

  void limparFiltroRuns() {
    _statusFiltro = null;
    _buscaFiltro = null;
    _runsFiltrados = [];
    _runsTotal = 0;
    notifyListeners();
  }

  Future<void> carregarRelatorioChat(String userId, {int dias = 30}) async {
    if (_carregandoChat) return;
    _carregandoChat = true;
    _erro = null;
    notifyListeners();
    try {
      _chat = await _repo.relatorioChat(userId, dias: dias);
    } catch (e) {
      _erro = e.toString();
    } finally {
      _carregandoChat = false;
      notifyListeners();
    }
  }

  Future<void> buscarMensagens(String userId, String termo) async {
    final limpo = termo.trim();
    if (limpo.length < 2) {
      _mensagens = [];
      _mensagensTotal = 0;
      notifyListeners();
      return;
    }
    _carregandoBusca = true;
    _erro = null;
    notifyListeners();
    try {
      final resultado = await _repo.buscarMensagens(userId, limpo);
      _mensagens = (resultado['items'] as List? ?? []).cast<Map<String, dynamic>>();
      _mensagensTotal = resultado['total'] as int? ?? _mensagens.length;
    } catch (e) {
      _erro = e.toString();
    } finally {
      _carregandoBusca = false;
      notifyListeners();
    }
  }
}