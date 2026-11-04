import 'package:flutter/foundation.dart';

import '../data/termo_aceite_repository.dart';

/// Estado do aceite dos Termos de Uso e do Termo de Consentimento (LGPD)
/// do usuário autenticado. Usado para exigir o aceite no primeiro acesso
/// à web do sistema quando ainda não houver registro no backend.
class TermoAceiteProvider extends ChangeNotifier {
  final TermoAceiteRepository _repository = TermoAceiteRepository();

  bool _carregado = false;
  bool _aceito = false;
  bool _registrando = false;
  Map<String, dynamic>? _status;
  String? _consultadoPara;

  bool get carregado => _carregado;
  bool get aceito => _aceito;
  bool get registrando => _registrando;
  Map<String, dynamic>? get status => _status;
  String? get versaoAtual => _status?['versao_atual'] as String?;

  /// Consulta o aceite no backend para o usuário informado. Deve ser chamado
  /// após o login/preload do usuário autenticado.
  Future<void> carregar(String userKey) async {
    // Evita estado travado entre contas: trocou de usuário, reconsulta.
    if (_carregado && _consultadoPara == userKey) return;
    try {
      final status = await _repository.consultar();
      _status = status;
      _aceito = status['aceito_todos'] == true;
      _consultadoPara = userKey;
    } catch (e) {
      debugPrint('⚠️ [TermoAceiteProvider] Erro ao consultar aceite: $e');
      // Em caso de falha de rede, não bloqueia o usuário (fail-open),
      // evitando impedir o uso por um problema técnico.
      _aceito = true;
    } finally {
      _carregado = true;
      notifyListeners();
    }
  }

  /// Registra o aceite dos termos com a versão vigente.
  Future<bool> aceitar() async {
    if (_registrando) return false;
    _registrando = true;
    notifyListeners();
    try {
      final resultado = await _repository.registrar();
      _status = resultado;
      _aceito = true;
      return true;
    } catch (e) {
      debugPrint('⚠️ [TermoAceiteProvider] Erro ao registrar aceite: $e');
      return false;
    } finally {
      _registrando = false;
      notifyListeners();
    }
  }

  /// Reseta o estado (ex.: após logout).
  Future<void> resetar() async {
    _carregado = false;
    _aceito = false;
    _registrando = false;
    _status = null;
    notifyListeners();
  }
}
