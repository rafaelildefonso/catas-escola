import 'package:flutter/material.dart';
import '../data/automations_repository.dart';

class AutomationRun {
  final String id;
  final String? automationId;
  final String status;
  final String? automationStatus;
  final String? automationName;
  final String runType;
  final String inputSummary;
  final Map<String, dynamic> inputPayload;
  final Map<String, dynamic>? errorDetails;
  final Map<String, dynamic>? resultMetadata;
  final DateTime createdAt;
  final DateTime? finishedAt;

  AutomationRun({
    required this.id,
    this.automationId,
    required this.status,
    this.automationStatus,
    this.automationName,
    required this.runType,
    required this.inputSummary,
    required this.inputPayload,
    this.errorDetails,
    this.resultMetadata,
    required this.createdAt,
    this.finishedAt,
  });

  factory AutomationRun.fromMap(Map<String, dynamic> map) {
    final automationData = map['automations'] as Map<String, dynamic>?;
    
    // Safely parse JSONB fields that might come as strings or maps
    dynamic rawInput = map['input_payload'];
    Map<String, dynamic> inputPayload = (rawInput is Map) ? Map<String, dynamic>.from(rawInput) : {};
    
    dynamic rawError = map['error_details'];
    Map<String, dynamic>? errorDetails = (rawError is Map) ? Map<String, dynamic>.from(rawError) : null;
    if (rawError is String) errorDetails = {"message": rawError};
    
    dynamic rawResult = map['result_metadata'];
    Map<String, dynamic>? resultMetadata = (rawResult is Map) ? Map<String, dynamic>.from(rawResult) : null;
    
    return AutomationRun(
      id: map['id'],
      automationId: map['automation_id'],
      status: map['status'] ?? 'pending',
      automationStatus: automationData?['status'],
      automationName: automationData?['name'],
      runType: map['run_type'] ?? 'temporal',
      inputSummary: map['input_summary'] ?? '',
      inputPayload: inputPayload,
      errorDetails: errorDetails,
      resultMetadata: resultMetadata,
      createdAt: DateTime.parse(map['created_at']),
      finishedAt: map['finished_at'] != null ? DateTime.parse(map['finished_at']) : null,
    );
  }

  AutomationRun copyWith({
    String? status,
    String? automationStatus,
    DateTime? finishedAt,
  }) {
    return AutomationRun(
      id: id,
      automationId: automationId,
      status: status ?? this.status,
      automationStatus: automationStatus ?? this.automationStatus,
      automationName: automationName,
      runType: runType,
      inputSummary: inputSummary,
      inputPayload: inputPayload,
      errorDetails: errorDetails,
      resultMetadata: resultMetadata,
      createdAt: createdAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }
}

class AutomationStepLog {
  final String id;
  final int stepIndex;
  final String stepName;
  final String stepType;
  final String status;
  final String? errorMessage;
  final int? durationMs;
  final Map<String, dynamic> metadata;
  final DateTime updatedAt;

  AutomationStepLog({
    required this.id,
    required this.stepIndex,
    required this.stepName,
    required this.stepType,
    required this.status,
    this.errorMessage,
    this.durationMs,
    required this.metadata,
    required this.updatedAt,
  });

  factory AutomationStepLog.fromMap(Map<String, dynamic> map) {
    // Tenta extrair informações amigáveis do resultado ou metadados
    final rawResult = map['result'];
    final Map<String, dynamic> result = (rawResult is Map) ? Map<String, dynamic>.from(rawResult) : {};
    final String? resultError = (rawResult is String) ? rawResult : null;
    
    final intent = map['intent']?.toString() ?? 'Ação';
    
    return AutomationStepLog(
      id: map['id'],
      stepIndex: map['step_index'] ?? 0,
      stepName: intent,
      stepType: map['module_id'] ?? 'unknown',
      status: map['status'] ?? 'pending',
      errorMessage: map['error_message'] ?? result['error'] ?? resultError,
      durationMs: map['duration_ms'] ?? result['duration'],
      metadata: result,
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

class AutomationsProvider with ChangeNotifier {
  late final AutomationsRepository _repository = AutomationsRepository();
  
  List<AutomationRun> _runs = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  // Estados para Detalhes (Steps)
  List<AutomationStepLog> _stepLogs = [];
  bool _isLoadingSteps = false;

  List<AutomationRun> get runs => _runs;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  List<AutomationStepLog> get stepLogs => _stepLogs;
  bool get isLoadingSteps => _isLoadingSteps;

  /// Busca inicial de runs
  Future<void> fetchRuns(String userId, {bool refresh = false}) async {
    if (refresh) {
      _runs = [];
      _hasMore = true;
    }

    if (_runs.isNotEmpty && !_hasMore) return;

    _error = null;
    if (refresh || _runs.isEmpty) {
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }
    notifyListeners();

    try {
      final data = await _repository.fetchAutomationRuns(
        userId: userId,
        offset: _runs.length,
        limit: 20,
      );

      final newRuns = data.map((m) => AutomationRun.fromMap(m)).toList();
      
      if (newRuns.length < 20) {
        _hasMore = false;
      }

      if (refresh) {
        _runs = newRuns;
      } else {
        _runs.addAll(newRuns);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Busca os passos de uma execução específica
  Future<void> fetchStepLogs(String runId) async {
    _isLoadingSteps = true;
    _stepLogs = [];
    notifyListeners();

    try {
      final data = await _repository.fetchStepLogs(runId);
      _stepLogs = data.map((m) => AutomationStepLog.fromMap(m)).toList();
      // Ordena por index
      _stepLogs.sort((a, b) => a.stepIndex.compareTo(b.stepIndex));
    } catch (e) {
      debugPrint("Erro ao buscar step logs: $e");
    } finally {
      _isLoadingSteps = false;
      notifyListeners();
    }
  }

  /// Toggle status (pausar/ativar)
  Future<void> toggleAutomationStatus(String automationId, bool active) async {
    final newStatus = active ? 'active' : 'paused';
    try {
      await _repository.updateAutomationStatus(automationId, newStatus);
      
      // Atualiza o estado local para refletir na UI sem refresh
      for (int i = 0; i < _runs.length; i++) {
        if (_runs[i].automationId == automationId) {
          _runs[i] = _runs[i].copyWith(automationStatus: newStatus);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Erro ao atualizar status da automação: $e");
      rethrow;
    }
  }

  /// Excluir automação
  Future<void> deleteAutomation(String automationId) async {
    try {
      await _repository.deleteAutomation(automationId);
      _runs.removeWhere((r) => r.automationId == automationId);
      notifyListeners();
    } catch (e) {
      debugPrint("Erro ao excluir automação: $e");
      rethrow;
    }
  }
  /// Excluir apenas uma execução específica
  Future<void> deleteRun(String runId) async {
    try {
      await _repository.deleteRun(runId);
      _runs.removeWhere((r) => r.id == runId);
      notifyListeners();
    } catch (e) {
      debugPrint("Erro ao excluir execução: $e");
      rethrow;
    }
  }
}
