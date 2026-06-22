import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum ServerStatus {
  checking,
  online,
  starting,
  offline,
  unavailable,
}

class ServerStatusProvider extends ChangeNotifier {
  ServerStatus _status = ServerStatus.checking;
  String? _errorMessage;
  DateTime? _lastCheckTime;

  ServerStatus get status => _status;
  String? get errorMessage => _errorMessage;
  DateTime? get lastCheckTime => _lastCheckTime;

  bool get isOnline => _status == ServerStatus.online;
  bool get isChecking => _status == ServerStatus.checking;

  Future<void> checkServerHealth(String apiBaseUrl) async {
    _status = ServerStatus.checking;
    _errorMessage = null;
    notifyListeners();

    try {
      final healthBase = apiBaseUrl.replaceFirst('/api/v1', '');
      final uri = Uri.parse('$healthBase/health');

      debugPrint('Checking server health at: $uri');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout after 10 seconds');
        },
      );

      if (response.statusCode == 200) {
        _status = ServerStatus.online;
        debugPrint('Server is online');
      } else if (response.statusCode >= 500) {
        _status = ServerStatus.starting;
        _errorMessage = 'Server is starting up (${response.statusCode})';
        debugPrint('Server is starting up');
      } else {
        _status = ServerStatus.offline;
        _errorMessage = 'Server returned status ${response.statusCode}';
        debugPrint('Server returned error status: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Timeout') || e.toString().contains('timeout')) {
        _status = ServerStatus.starting;
        _errorMessage = 'Server is taking too long to respond';
        debugPrint('Server timeout - likely starting up');
      } else {
        _status = ServerStatus.unavailable;
        _errorMessage = e.toString();
        debugPrint('Server unavailable: $e');
      }
    }

    _lastCheckTime = DateTime.now();
    notifyListeners();
  }

  String getStatusMessage() {
    switch (_status) {
      case ServerStatus.checking:
        return 'Verificando servidor...';
      case ServerStatus.online:
        return 'Servidor online';
      case ServerStatus.starting:
        return 'Servidor iniciando...';
      case ServerStatus.offline:
        return 'Servidor offline';
      case ServerStatus.unavailable:
        return 'Servidor indisponível';
    }
  }

  String getStatusDescription() {
    switch (_status) {
      case ServerStatus.checking:
        return 'Aguardando resposta do servidor';
      case ServerStatus.online:
        return 'Conexão estabelecida com sucesso';
      case ServerStatus.starting:
        return 'O servidor está iniciando, por favor aguarde';
      case ServerStatus.offline:
        return 'O servidor está temporariamente indisponível';
      case ServerStatus.unavailable:
        return 'Não foi possível conectar ao servidor';
    }
  }
}
