import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../data/chat_repository.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../data/chat_repository_interface.dart';
import '../data/demo_repository.dart';
import '../services/token_holder.dart';
import '../core/app_config.dart';
import '../core/api_exception.dart';
import '../models/picked_attachment.dart';
import 'package:catas/data/storage_repository.dart';
import 'package:catas/main.dart' show navigatorKey;
import 'package:catas/providers/auth_provider.dart';
import 'package:catas/providers/demo_automations_provider.dart';
import 'package:provider/provider.dart';

class MessageChunk {
  final String text;
  List<dynamic>? components;
  final String status; // "idle", "requires_action", "completed"
  final DateTime timestamp;

  MessageChunk({
    required this.text,
    this.components,
    this.status = 'idle',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class Message {
  String text;
  final bool isUser;
  final bool isHidden;
  bool actionTriggered;
  Map<String, dynamic>? actionDetails;
  List<dynamic>? components;
  final List<String>? attachmentUrls;
  String status; // "idle", "requires_action", "completed"
  final DateTime timestamp;
  final String? role;
  bool? isLiked;
  String? feedbackReason;
  final String? messageId;
  String? continuationId;
  final List<MessageChunk> chunks;

  Message({
    required this.text,
    required this.isUser,
    this.isHidden = false,
    this.actionTriggered = false,
    this.actionDetails,
    this.components,
    this.attachmentUrls,
    this.status = 'idle',
    DateTime? timestamp,
    this.role,
    this.isLiked,
    this.feedbackReason,
    this.messageId,
    this.continuationId,
    List<MessageChunk>? chunks,
  }) : timestamp = timestamp ?? DateTime.now(),
       chunks = chunks ?? [];

  /// Whether this message is a final response (shows feedback buttons)
  bool get isFinalResponse => !isUser && status != 'requires_action';

  /// True quando a mensagem tem um ID persistido e pode receber feedback.
  bool get canReceiveFeedback => isFinalResponse && messageId != null;

  void setFeedback(bool liked) {
    if (isLiked == liked) {
      isLiked = null; // Toggle off
      feedbackReason = null;
    } else {
      isLiked = liked;
    }
  }

  void setFeedbackReason(String? reason) {
    feedbackReason = reason;
  }

  void addChunk(MessageChunk chunk) {
    chunks.add(chunk);
    text = '$text\n\n---\n\n${chunk.text}';
    components = chunk.components;
    status = chunk.status;
    // Note: messageId remains the same as we are updating in-place
  }
}

/// Estados do pipeline de pensamento da IA
enum ThinkingStage {
  idle,
  processing, // Para perguntas simples (só processando)
  reasoning, // Para ações (analisando)
  planning, // Para ações (planejando)
  executing, // Para ações (executando)
}

class ChatProvider extends ChangeNotifier {
  IChatRepository _repository = ChatRepository();
  bool _isDemoMode = AppConfig.isDemoMode;
  final List<Message> _messages = [];
  bool _isLoading = false;
  bool _isLoadingSessions = false;
  bool _hasAttemptedLoadSessions = false;
  String? _currentSessionId;
  List<ChatSession> _sessions = [];
  Set<String> _pinnedSessionIds = {};
  String _searchQuery = '';
  String? _lastError;
  String _selectedModel = "CATAS Basic";

  bool _isStopped = false;
  ThinkingStage _thinkingStage = ThinkingStage.idle;
  bool _isWebSearchEnabled = false;
  String _messageDraft = "";
  Timer? _draftDebounceTimer;
  final Set<String> _activeIntegrations = {};

  // Pagination State
  bool _isLoadingMoreSessions = false;
  bool _hasMoreSessions = true;
  bool _isLoadingMoreMessages = false;
  bool _hasMoreMessages = true;
  static const int _sessionsLimit = 50;
  static const int _messagesLimit = 100;

  // Cancellation & State
  CancelToken? _activeCancelToken;
  String? _currentAutomationId;

  // Execution Feedback (Realtime - Step 13)
  Timer? _automationPollingTimer;
  DateTime? _automationPollingStartedAt;
  static const Duration _automationPollingTimeout = Duration(minutes: 2);
  List<Map<String, dynamic>> _automationSteps = [];
  List<Map<String, dynamic>> get automationSteps => _automationSteps;

  String _automationPhase = 'none';
  String get automationPhase => _automationPhase;
  String? _automationError;
  String? get automationError => _automationError;

  static const String _kDraftKey = 'chat_message_draft';
  static const String _kWebSearchKey = 'chat_web_search_enabled';
  static const String _kAttachmentsKey = 'chat_attachments';
  static const String _kActiveIntegrationsKey = 'chat_active_integrations';

  final List<PickedAttachment> _attachments = [];

  final List<String> _availableModels = [
    "CATAS Basic",
    "CATAS Pro",
    "CATAS MAX",
  ];

  final Map<String, String> _modelsInfo = {
    "CATAS Basic": "Disponível no plano Basic",
    "CATAS Pro": "Disponível no plano Pro",
    "CATAS MAX": "Disponível no plano MAX",
  };

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isLoadingSessions => _isLoadingSessions;
  bool get hasAttemptedLoadSessions => _hasAttemptedLoadSessions;
  String? get currentSessionId => _currentSessionId;
  List<ChatSession> get sessions => _sessions;
  String get searchQuery => _searchQuery;
  String? get lastError => _lastError;
  String get selectedModel => _selectedModel;
  List<String> get availableModels => _availableModels;
  Map<String, String> get modelsInfo => _modelsInfo;
  bool get isDemoMode => _isDemoMode;
  bool get isStopped => _isStopped;
  ThinkingStage get thinkingStage => _thinkingStage;
  bool get isWebSearchEnabled => _isWebSearchEnabled;
  String get messageDraft => _messageDraft;
  Set<String> get activeIntegrations => _activeIntegrations;

  bool get isLoadingMoreSessions => _isLoadingMoreSessions;
  bool get hasMoreSessions => _hasMoreSessions;
  bool get isLoadingMoreMessages => _isLoadingMoreMessages;
  bool get hasMoreMessages => _hasMoreMessages;

  List<PickedAttachment> get attachments => _attachments;

  ChatSession? get currentSession {
    if (_currentSessionId == null) return null;
    try {
      return _sessions.firstWhere((s) => s.id == _currentSessionId);
    } catch (_) {
      return null;
    }
  }

  bool isIntegrationActive(String providerName) =>
      _activeIntegrations.contains(providerName);

  void toggleDemoMode() {
    _isDemoMode = !_isDemoMode;
    if (_isDemoMode) {
      _repository = DemoRepository();
    } else {
      _repository = ChatRepository();
    }
    clearChat();
    _sessions.clear();
    loadSessions();
  }

  bool isPinnedSession(String sessionId) =>
      _pinnedSessionIds.contains(sessionId);

  List<ChatSession> get filteredSessions {
    final query = _searchQuery.trim().toLowerCase();
    final list = query.isEmpty
        ? _sessions
        : _sessions
              .where((s) => s.title.toLowerCase().contains(query))
              .toList();

    list.sort((a, b) {
      final aPinned = _pinnedSessionIds.contains(a.id);
      final bPinned = _pinnedSessionIds.contains(b.id);
      if (aPinned != bPinned) {
        return aPinned ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return list;
  }

  void setSelectedModel(String model) {
    if (_availableModels.contains(model)) {
      _selectedModel = model;
      notifyListeners();
    }
  }

  ChatProvider() {
    if (_isDemoMode) {
      _repository = DemoRepository();
    }
    _init();
  }

  Future<void> _init() async {
    await _loadPinnedFromStorage();
    await _loadDraftFromStorage();
  }

  Future<void> _loadDraftFromStorage() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _messageDraft = prefs.getString(_kDraftKey) ?? "";
      _isWebSearchEnabled = prefs.getBool(_kWebSearchKey) ?? false;

      final attachmentsJson = prefs.getStringList(_kAttachmentsKey);
      if (attachmentsJson != null) {
        _attachments.clear();
        for (final item in attachmentsJson) {
          final map = jsonDecode(item) as Map<String, dynamic>;
          _attachments.add(
            PickedAttachment(
              id: map['id'],
              path: map['path'],
              name: map['name'],
              isImage: map['isImage'],
              url: map['url'],
            ),
          );
        }
      }

      final activeIntegrations = prefs.getStringList(_kActiveIntegrationsKey);
      if (activeIntegrations != null) {
        _activeIntegrations.clear();
        _activeIntegrations.addAll(activeIntegrations);
      }

      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveDraftToStorage() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDraftKey, _messageDraft);
      await prefs.setBool(_kWebSearchKey, _isWebSearchEnabled);

      final attachmentsJson = _attachments
          .map(
            (a) => jsonEncode({
              'id': a.id,
              'path': a.path,
              'name': a.name,
              'isImage': a.isImage,
              'url': a.url,
            }),
          )
          .toList();

      if (attachmentsJson.isNotEmpty) {
        await prefs.setStringList(_kAttachmentsKey, attachmentsJson);
      } else {
        await prefs.remove(_kAttachmentsKey);
      }

      if (_activeIntegrations.isNotEmpty) {
        await prefs.setStringList(
          _kActiveIntegrationsKey,
          _activeIntegrations.toList(),
        );
      } else {
        await prefs.remove(_kActiveIntegrationsKey);
      }
    } catch (_) {}
  }

  void setMessageDraft(String value) {
    if (_messageDraft != value) {
      _messageDraft = value;
      _draftDebounceTimer?.cancel();
      _draftDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        _saveDraftToStorage();
      });
    }
  }

  void addAttachments(List<PickedAttachment> newAttachments) {
    // Optional: Add logic to limit max attachments if needed
    _attachments.addAll(newAttachments);
    _saveDraftToStorage();
    notifyListeners();
  }

  void removeAttachment(String id) {
    _attachments.removeWhere((a) => a.id == id);
    _saveDraftToStorage();
    notifyListeners();
  }

  void clearAttachments() {
    _attachments.clear();
    _saveDraftToStorage();
    notifyListeners();
  }

  Future<void> _loadPinnedFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pinnedSessionIds =
          prefs.getStringList('pinned_session_ids')?.toSet() ?? {};
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

  Future<void> _savePinnedToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'pinned_session_ids',
        _pinnedSessionIds.toList(),
      );
    } catch (_) {
      // ignore
    }
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void _subscribeToAutomation(
    String automationId, {
    List<Map<String, dynamic>>? demoSteps,
    Message? targetMessage,
  }) {
    _unsubscribeFromAutomation();
    _automationSteps = [];
    _automationPhase = 'running';
    _automationError = null;
    _setAutomationMessageComponents(targetMessage, [
      {
        'type': 'automation_progress',
        'data': {
          'automation_id': automationId,
          'title': 'Execução em andamento',
        },
      },
    ]);

    // Em modo demo, simular steps localmente
    if (_isDemoMode && demoSteps != null && demoSteps.isNotEmpty) {
      _simulateAutomationSteps(automationId, demoSteps);
      return;
    }

    debugPrint("📡 Polling automation steps: $automationId");
    _automationPollingStartedAt = DateTime.now();

    _automationPollingTimer = Timer.periodic(const Duration(seconds: 2), (
      _,
    ) async {
      if (_automationPollingStartedAt != null &&
          DateTime.now().difference(_automationPollingStartedAt!) >
              _automationPollingTimeout) {
        debugPrint(
          "⏱️ Polling timeout — cancelling after ${_automationPollingTimeout.inMinutes}min",
        );
        _automationPollingTimer?.cancel();
        _automationPollingTimer = null;
        _automationPollingStartedAt = null;
        return;
      }
      try {
        final runResponse = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/automation-runs/$automationId'),
          headers: {"Authorization": "Bearer ${TokenHolder().token ?? ""}"},
        );
        if (runResponse.statusCode == 200) {
          final run = Map<String, dynamic>.from(
            jsonDecode(runResponse.body) as Map,
          );
          final status = run['status'] as String? ?? 'running';
          _automationPhase = status;
          if (status == 'completed' ||
              status == 'failed' ||
              status == 'canceled') {
            _automationError = (run['error_details'] as Map?)?['message']
                ?.toString();
            _setAutomationMessageComponents(
              targetMessage,
              _terminalAutomationComponents(automationId, run),
            );
            _automationPollingTimer?.cancel();
            _automationPollingTimer = null;
            _automationPollingStartedAt = null;
          }
        }

        final response = await http.get(
          Uri.parse(
            '${AppConfig.apiBaseUrl}/automation-step-logs?run_id=$automationId',
          ),
          headers: {"Authorization": "Bearer ${TokenHolder().token ?? ""}"},
        );

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final data = body is List ? body : (body['data'] as List? ?? []);

          for (final step in data) {
            final stepMap = step as Map<String, dynamic>;
            final index = _automationSteps.indexWhere(
              (s) => s['step_index'] == stepMap['step_index'],
            );
            if (index != -1) {
              _automationSteps[index] = stepMap;
            } else {
              _automationSteps.add(stepMap);
              _automationSteps.sort(
                (a, b) =>
                    (a['step_index'] as int).compareTo(b['step_index'] as int),
              );
            }

            if (stepMap['status'] == 'success' &&
                stepMap['module_id'] == 'completion_notification') {
              _automationPollingTimer?.cancel();
              _automationPollingTimer = null;
              _automationPollingStartedAt = null;
              Future.delayed(const Duration(seconds: 2), () async {
                try {
                  final quotaResp = await http.get(
                    Uri.parse('${AppConfig.apiBaseUrl}/auth/me'),
                    headers: {
                      "Authorization": "Bearer ${TokenHolder().token ?? ""}",
                    },
                  );
                  if (quotaResp.statusCode == 200) {
                    final quotaData =
                        jsonDecode(quotaResp.body) as Map<String, dynamic>;
                    final profile =
                        quotaData['profile'] as Map<String, dynamic>?;
                    if (profile != null) {
                      debugPrint(
                        "📊 Créditos atualizados: ${profile['quota_used']}/${profile['monthly_quota_limit']}",
                      );
                      _updateAuthQuota(profile);
                    }
                  }
                } catch (e) {
                  debugPrint("⚠️ Erro ao atualizar créditos: $e");
                }
              });
            }
          }

          notifyListeners();

          if (_automationSteps.isNotEmpty) {
            final hasActiveSteps = _automationSteps.any(
              (s) => s['status'] == 'running' || s['status'] == 'pending',
            );
            if (!hasActiveSteps) {
              debugPrint("✅ All automation steps completed — stopping polling");
              _automationPollingTimer?.cancel();
              _automationPollingTimer = null;
              _automationPollingStartedAt = null;
              Future.delayed(const Duration(seconds: 2), () async {
                try {
                  final quotaResp = await http.get(
                    Uri.parse('${AppConfig.apiBaseUrl}/auth/me'),
                    headers: {
                      "Authorization": "Bearer ${TokenHolder().token ?? ""}",
                    },
                  );
                  if (quotaResp.statusCode == 200) {
                    final quotaData =
                        jsonDecode(quotaResp.body) as Map<String, dynamic>;
                    final profile =
                        quotaData['profile'] as Map<String, dynamic>?;
                    if (profile != null) {
                      debugPrint(
                        "📊 Créditos atualizados: ${profile['quota_used']}/${profile['monthly_quota_limit']}",
                      );
                      _updateAuthQuota(profile);
                    }
                  }
                } catch (e) {
                  debugPrint("⚠️ Erro ao atualizar créditos: $e");
                }
              });
            }
          }
        }
      } catch (e) {
        debugPrint("⚠️ Erro no polling de automação: $e");
      }
    });
  }

  void _setAutomationMessageComponents(
    Message? message,
    List<dynamic> components,
  ) {
    if (message == null) return;
    message.components = components;
    if (message.chunks.isNotEmpty) {
      message.chunks.last.components = components;
    }
    message.status = _automationPhase;
    notifyListeners();
  }

  List<dynamic> _terminalAutomationComponents(
    String automationId,
    Map<String, dynamic> run,
  ) {
    final status = run['status']?.toString() ?? 'failed';
    final isSuccess = status == 'completed';
    final context = ((run['result_metadata'] as Map?)?['run_context']);
    final spreadsheetUrl = _findSpreadsheetUrl(context);
    final error = _automationError ?? 'Não foi possível concluir esta ação.';

    final components = <dynamic>[
      {
        'type': 'automation_progress',
        'data': {
          'automation_id': automationId,
          'title': 'Resultado da execução',
        },
      },
      {
        'type': 'automation_result',
        'data': {
          'success': isSuccess,
          'title': isSuccess ? 'Ação concluída' : 'Ação não concluída',
          'summary': isSuccess ? 'A execução terminou com sucesso.' : error,
        },
      },
    ];
    if (isSuccess && spreadsheetUrl != null) {
      components.add({
        'type': 'link_preview',
        'data': {
          'url': spreadsheetUrl,
          'title': 'Abrir planilha',
          'description': 'A planilha foi criada no Google Planilhas.',
          'icon': 'sheets',
        },
      });
    }
    if (!isSuccess) {
      components.add({
        'type': 'alert_banner',
        'data': {
          'level': 'error',
          'title': 'Não foi possível concluir',
          'message': error,
        },
      });
    }
    return components;
  }

  String? _findSpreadsheetUrl(dynamic value) {
    if (value is Map) {
      final url = value['spreadsheet_url'];
      if (url is String && Uri.tryParse(url)?.hasScheme == true) return url;
      for (final child in value.values) {
        final found = _findSpreadsheetUrl(child);
        if (found != null) return found;
      }
    } else if (value is List) {
      for (final child in value) {
        final found = _findSpreadsheetUrl(child);
        if (found != null) return found;
      }
    }
    return null;
  }

  static const Map<String, String> _moduleLabels = {
    'google_calendar.create_event': 'Google Calendar',
    'google_drive.create_folder': 'Google Drive',
    'google_sheets.append_row': 'Google Sheets',
  };

  static const Map<String, String> _moduleDescriptions = {
    'google_calendar.create_event':
        'Criar evento no calendário para a reunião de onboarding',
    'google_drive.create_folder':
        'Criar pasta dedicada no Drive para organizar documentos',
    'google_sheets.append_row': 'Registrar cliente na planilha de onboarding',
  };

  void _simulateAutomationSteps(
    String automationId,
    List<Map<String, dynamic>> steps,
  ) {
    _automationSteps = [];
    _automationPhase = 'appearing';
    notifyListeners();

    // Phase 1: Steps appear one by one (slower for readability)
    for (int i = 0; i < steps.length; i++) {
      final moduleId = steps[i]["module_id"] ?? "unknown";
      Future.delayed(Duration(milliseconds: 500 + i * 1500), () {
        _automationSteps.add({
          "automation_id": automationId,
          "step_index": i,
          "module_id": moduleId,
          "status": "pending",
          "label": _moduleLabels[moduleId] ?? moduleId,
        });
        _automationSteps.sort(
          (a, b) => (a['step_index'] as int).compareTo(b['step_index'] as int),
        );
        notifyListeners();
      });
    }

    // Phase 2: Descriptions appear
    Future.delayed(Duration(milliseconds: 500 + steps.length * 1500 + 800), () {
      _automationPhase = 'descriptions';
      for (int i = 0; i < _automationSteps.length; i++) {
        final moduleId = _automationSteps[i]["module_id"] as String? ?? '';
        _automationSteps[i] = Map<String, dynamic>.from(_automationSteps[i])
          ..['description'] = _moduleDescriptions[moduleId] ?? '';
      }
      notifyListeners();
    });

    // Phase 3: Verify each integration one by one
    for (int i = 0; i < steps.length; i++) {
      final baseDelay = 500 + steps.length * 1500 + 800 + 800;
      Future.delayed(Duration(milliseconds: baseDelay + i * 1000), () {
        _automationPhase = 'verifying';
        final idx = _automationSteps.indexWhere((s) => s['step_index'] == i);
        if (idx != -1) {
          _automationSteps[idx] = Map<String, dynamic>.from(
            _automationSteps[idx],
          )..['status'] = 'verifying';
          notifyListeners();
        }
      });
      Future.delayed(Duration(milliseconds: baseDelay + i * 1000 + 1000), () {
        final idx = _automationSteps.indexWhere((s) => s['step_index'] == i);
        if (idx != -1) {
          _automationSteps[idx] = Map<String, dynamic>.from(
            _automationSteps[idx],
          )..['status'] = 'verified';
          notifyListeners();
        }
      });
    }

    // Phase 4: Test trigger
    final verifyEnd =
        500 + steps.length * 1500 + 800 + 800 + steps.length * 1000;
    Future.delayed(Duration(milliseconds: verifyEnd + 500), () {
      _automationPhase = 'testingTrigger';
      notifyListeners();
    });

    // Phase 5: Completed (after 3s of trigger animation)
    Future.delayed(Duration(milliseconds: verifyEnd + 3500), () {
      _automationPhase = 'completed';
      notifyListeners();
    });
  }

  void _unsubscribeFromAutomation() {
    if (_isDemoMode || _automationPollingTimer == null) {
      _automationPollingTimer?.cancel();
      _automationPollingTimer = null;
      _automationPollingStartedAt = null;
      return;
    }
    _automationPollingTimer?.cancel();
    _automationPollingTimer = null;
    _automationPollingStartedAt = null;
  }

  /// Sincroniza a cota do usuário no AuthProvider (Quota Sync - Step 01)
  void _updateAuthQuota(Map<String, dynamic> response) {
    final used = response['quota_used'] as int?;
    final limit = response['monthly_quota_limit'] as int?;

    if (used != null) {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        context.read<AuthProvider>().updateQuota(used, limit);
      }
    }
  }

  void clearChat() {
    _messages.clear();
    _currentSessionId = null;
    _activeIntegrations.clear();
    _isWebSearchEnabled = false;
    _automationSteps = [];
    _unsubscribeFromAutomation();
    notifyListeners();
  }

  /// Para a geração da IA
  void stopGeneration() {
    _isStopped = true;
    _isLoading = false;
    _thinkingStage = ThinkingStage.idle;

    // 1. Abort network request
    _activeCancelToken?.cancel("User stopped generation");
    _activeCancelToken = null;

    // 2. Clear automation state
    _currentAutomationId = null;

    _unsubscribeFromAutomation();
    notifyListeners();
  }

  /// Atualiza o estágio de pensamento (para UI)
  void setThinkingStage(ThinkingStage stage) {
    _thinkingStage = stage;
    notifyListeners();
  }

  void toggleWebSearch(bool value) {
    _isWebSearchEnabled = value;
    notifyListeners();
    _saveDraftToStorage();
  }

  void toggleChatIntegration(String providerName) {
    if (_activeIntegrations.contains(providerName)) {
      _activeIntegrations.remove(providerName);
    } else {
      _activeIntegrations.add(providerName);
    }
    _saveDraftToStorage();
    notifyListeners();
  }

  void clearActiveIntegrations() {
    _activeIntegrations.clear();
    notifyListeners();
  }

  void activateIntegration(String provider) {
    if (!_activeIntegrations.contains(provider)) {
      _activeIntegrations.add(provider);
      _saveDraftToStorage();
      notifyListeners();
    }
  }

  Future<void> togglePin(String sessionId) async {
    if (_pinnedSessionIds.contains(sessionId)) {
      _pinnedSessionIds.remove(sessionId);
    } else {
      _pinnedSessionIds.add(sessionId);
    }
    notifyListeners();
    await _savePinnedToStorage();
  }

  // ChatProvider() {
  //   _addSystemMessage("Olá! Eu sou o CATAS. Como posso ajudar você hoje?");
  // }

  Future<void> loadSessions() async {
    if (_isLoadingSessions) return;

    _lastError = null;
    _isLoadingSessions = true;
    _hasMoreSessions = true; // Reset
    notifyListeners();

    try {
      final raw = await _repository.getSessions(
        limit: _sessionsLimit,
        offset: 0,
      );
      _sessions = raw.map((s) => ChatSession.fromJson(s)).toList();
      _hasAttemptedLoadSessions = true;
      if (raw.length < _sessionsLimit) {
        _hasMoreSessions = false;
      }
    } catch (e, stackTrace) {
      _lastError = e.toString();
      debugPrint('❌ loadSessions error: $e\n$stackTrace');
      if (_lastError!.contains("401") || _lastError!.contains("403")) {
        // Ignora erro silenciando para o AuthProvider lidar
        // NÃO marca como tentado para permitir retry quando auth estiver pronto
      } else {
        _hasAttemptedLoadSessions = true;
      }
    } finally {
      final error = _lastError;
      if (error == null || (!error.contains("401") && !error.contains("403"))) {
        _hasAttemptedLoadSessions = true;
      }
      _isLoadingSessions = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreSessions() async {
    if (_isLoadingSessions || _isLoadingMoreSessions || !_hasMoreSessions) {
      return;
    }

    _isLoadingMoreSessions = true;
    notifyListeners();

    try {
      final raw = await _repository.getSessions(
        limit: _sessionsLimit,
        offset: _sessions.length,
      );
      final newSessions = raw.map((s) => ChatSession.fromJson(s)).toList();

      if (newSessions.isEmpty || newSessions.length < _sessionsLimit) {
        _hasMoreSessions = false;
      }

      final existingIds = _sessions.map((e) => e.id).toSet();
      _sessions.addAll(newSessions.where((s) => !existingIds.contains(s.id)));
    } catch (e, stackTrace) {
      _lastError = e.toString();
      debugPrint('❌ loadMoreSessions error: $e\n$stackTrace');
    } finally {
      _isLoadingMoreSessions = false;
      notifyListeners();
    }
  }

  Future<bool> renameSession(String sessionId, String title) async {
    _lastError = null;
    notifyListeners();

    try {
      await _repository.renameSession(sessionId, title);
      await loadSessions();
      return true;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSession(String sessionId) async {
    _lastError = null;
    notifyListeners();

    try {
      await _repository.deleteSession(sessionId);
      _pinnedSessionIds.remove(sessionId);
      await _savePinnedToStorage();

      if (_currentSessionId == sessionId) {
        clearChat();
      }

      await loadSessions();
      return true;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<ChatSession?> createSession({String? title}) async {
    _lastError = null;
    notifyListeners();

    try {
      final raw = await _repository.createSession(title: title);
      final session = ChatSession.fromJson(raw);
      _sessions = [session, ..._sessions.where((s) => s.id != session.id)];
      await switchSession(session.id, clearMessages: true);
      return session;
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> switchSession(
    String sessionId, {
    bool clearMessages = true,
  }) async {
    _currentSessionId = sessionId;
    if (clearMessages) {
      _messages.clear();
    }
    notifyListeners();
    await loadHistory(sessionId);
  }

  Future<void> loadHistory(String sessionId) async {
    _lastError = null;
    _isLoading = true;
    _hasMoreMessages = true; // Reset
    notifyListeners();

    try {
      final raw = await _repository.getHistory(
        sessionId,
        limit: _messagesLimit,
        offset: 0,
      );
      final history = raw.map((m) => ChatMessage.fromJson(m)).toList();
      if (raw.length < _messagesLimit) {
        _hasMoreMessages = false;
      }

      _messages
        ..clear()
        ..addAll(
          history.map((m) {
            final isUser = m.role == 'user';
            final actionTriggered =
                (m.metadata['action_triggered'] as bool?) ??
                (m.metadata['actionTriggered'] as bool?) ??
                false;
            final actionDetails =
                (m.metadata['action_details'] as Map<String, dynamic>?) ??
                (m.metadata['actionDetails'] as Map<String, dynamic>?);

            return Message(
              text: m.content,
              isUser: isUser,
              role: m.role,
              isHidden: (m.metadata['is_hidden'] as bool?) ?? false,
              actionTriggered: actionTriggered,
              actionDetails: actionDetails,
              components: m.metadata['components'] as List<dynamic>?,
              attachmentUrls: (m.metadata['attachment_urls'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList(),
              status: (m.metadata['status'] as String?) ?? 'idle',
              timestamp: m.createdAt,
              messageId: m.id,
              continuationId: (m.metadata['status'] == 'requires_action')
                  ? m.id
                  : null,
            );
          }),
        );
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreMessages() async {
    if (_currentSessionId == null) return;
    if (_isLoading || _isLoadingMoreMessages || !_hasMoreMessages) return;

    _isLoadingMoreMessages = true;
    notifyListeners();

    try {
      final raw = await _repository.getHistory(
        _currentSessionId!,
        limit: _messagesLimit,
        offset: _messages.length,
      );
      final history = raw.map((m) => ChatMessage.fromJson(m)).toList();

      if (history.isEmpty || history.length < _messagesLimit) {
        _hasMoreMessages = false;
      }

      final newMessages = history.map((m) {
        final isUser = m.role == 'user';
        final actionTriggered =
            (m.metadata['action_triggered'] as bool?) ??
            (m.metadata['actionTriggered'] as bool?) ??
            false;
        final actionDetails =
            (m.metadata['action_details'] as Map<String, dynamic>?) ??
            (m.metadata['actionDetails'] as Map<String, dynamic>?);

        return Message(
          text: m.content,
          isUser: isUser,
          role: m.role,
          isHidden: (m.metadata['is_hidden'] as bool?) ?? false,
          actionTriggered: actionTriggered,
          actionDetails: actionDetails,
          components: m.metadata['components'] as List<dynamic>?,
          attachmentUrls: (m.metadata['attachment_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
          status: (m.metadata['status'] as String?) ?? 'idle',
          timestamp: m.createdAt,
          messageId: m.id,
          continuationId: (m.metadata['status'] == 'requires_action')
              ? m.id
              : null,
        );
      });

      _messages.addAll(newMessages);
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isLoadingMoreMessages = false;
      notifyListeners();
    }
  }

  /// Envia feedback (like/dislike) de uma mensagem para o backend.
  /// Atualiza a UI imediatamente (optimistic update) e persiste em background.
  /// [reason] é opcional e representa o motivo do feedback (Positive/Negative feedback reasons).
  Future<void> sendFeedback(
    Message message,
    bool voted, {
    String? reason,
  }) async {
    if (message.messageId == null || _currentSessionId == null) return;

    // Toggle local: se já estava marcado com o mesmo valor, desmarca (null)
    // Se há novo feedback, aplica; se é toggle off, remove o reason também
    if (message.isLiked == voted) {
      message.isLiked = null;
      message.feedbackReason = null;
    } else {
      message.isLiked = voted;
      message.feedbackReason = reason;
    }
    notifyListeners();

    try {
      await _repository.sendFeedback(
        messageId: message.messageId!,
        sessionId: _currentSessionId!,
        isLiked: message.isLiked,
        reason: reason,
      );
    } catch (e) {
      // Falha silenciosa — feedback é best-effort
      debugPrint('Feedback não enviado para ${message.messageId}: $e');
    }
  }

  Future<Map<String, dynamic>> sendMessage(
    String text, {
    String? currentPageUrl,
    String? currentPageTitle,
  }) async {
    if (text.trim().isEmpty && _attachments.isEmpty) return {};

    final userMessage = Message(
      text: text.trim().isEmpty ? "[Arquivo(s) enviado(s)]" : text,
      isUser: true,
      role: 'user',
      attachmentUrls: _attachments
          .map((a) => a.path)
          .toList(), // Using path for local preview
    );
    _messages.add(userMessage);
    _isLoading = true;
    _isStopped = false;
    _lastError = null;
    _thinkingStage =
        ThinkingStage.processing; // Começa com "processando" por padrão
    notifyListeners();

    try {
      final List<PickedAttachment> attachmentsToSend = List.from(_attachments);
      // Limpa anexos e rascunho da UI imediatamente
      clearAttachments();
      _messageDraft = "";
      _saveDraftToStorage();

      List<String> uploadedUrls = [];
      if (attachmentsToSend.isNotEmpty) {
        _thinkingStage = ThinkingStage.executing; // Upload status
        notifyListeners();
        final storageRepo = StorageRepository();
        for (final attachment in attachmentsToSend) {
          if (_isDemoMode) {
            uploadedUrls.add("https://demo.catas.ai/mock_${attachment.name}");
          } else {
            final url = await storageRepo.uploadAttachment(attachment);
            uploadedUrls.add(url);
          }
        }
      }

      _activeCancelToken = CancelToken();

      final response = await _repository.sendMessage(
        _currentSessionId,
        text.trim().isEmpty ? "[Arquivo(s) enviado(s)]" : text,
        model: _selectedModel,
        currentPageUrl: currentPageUrl,
        currentPageTitle: currentPageTitle,
        webSearch: _isWebSearchEnabled,
        activeIntegrations: _activeIntegrations.toList(),
        attachmentUrls: uploadedUrls,
        cancelToken: _activeCancelToken,
      );

      // Guard if user stopped during request
      if (_isStopped) return {};

      final newSessionId = response['session_id'] as String?;
      if (newSessionId != null && newSessionId.isNotEmpty) {
        _currentSessionId = newSessionId;
      }

      // Atualizar cota do usuário (Quota Sync - Step 03)
      _updateAuthQuota(response);

      // Store automation ID for possible cancellation
      _currentAutomationId = response['automation_id'] as String?;

      final assistantMessage = Message(
        text: response['text'] ?? "Desculpe, não entendi.",
        isUser: false,
        role: 'assistant',
        actionTriggered: response['actionTriggered'] ?? false,
        actionDetails: response['actionDetails'],
        components: response['components'] as List<dynamic>?,
        status: (response['status'] as String?) ?? 'idle',
        messageId: response['id'] as String?,
        continuationId: response['continuation_id'] as String?,
        chunks: [
          MessageChunk(
            text: response['text'] ?? "Desculpe, não entendi.",
            components: response['components'] as List<dynamic>?,
            status: (response['status'] as String?) ?? 'idle',
          ),
        ],
      );

      _messages.add(assistantMessage);

      // Se actionTriggered=true, muda para "reasoning" para mostrar feedback de automação
      if (response['actionTriggered'] == true) {
        _thinkingStage = ThinkingStage.reasoning;
      } else {
        _thinkingStage = ThinkingStage.idle;
      }
      notifyListeners();

      // Realtime Feedback / Demo Simulation
      final automationId = response['automation_id'] as String?;
      if (response['actionTriggered'] == true && automationId != null) {
        List<Map<String, dynamic>>? demoSteps;
        if (_isDemoMode) {
          final comps = response['components'] as List<dynamic>?;
          if (comps != null) {
            for (final comp in comps) {
              if (comp is Map<String, dynamic> &&
                  comp['type'] == 'automation_progress') {
                final data = comp['data'] as Map<String, dynamic>?;
                if (data != null && data['steps'] is List) {
                  demoSteps = (data['steps'] as List)
                      .cast<Map<String, dynamic>>();
                }
                break;
              }
            }
          }

          // Create onboarding automation run if this is an onboarding demo response
          final actionDetails =
              response['actionDetails'] as Map<String, dynamic>?;
          if (actionDetails != null &&
              actionDetails['intent'] == 'demo_onboarding') {
            final payload =
                actionDetails['payload'] as Map<String, dynamic>? ?? {};
            final clientName =
                payload['client_name'] as String? ?? 'João Silva';
            final meetingDate = payload['meeting_date'] as String? ?? '';
            final meetingTime = payload['meeting_time'] as String? ?? '';
            try {
              final ctx = navigatorKey.currentContext;
              if (ctx != null && ctx.mounted) {
                ctx.read<DemoAutomationsProvider>().addOnboardingAutomation(
                  clientName,
                  meetingDate,
                  meetingTime,
                );
              }
            } catch (_) {}
          }
        }
        _subscribeToAutomation(
          automationId,
          demoSteps: demoSteps,
          targetMessage: assistantMessage,
        );
      }

      if (_currentSessionId != null) {
        await loadSessions();
      }
      return response;
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        debugPrint("ChatProvider: Message cancelled by user.");
        return {};
      }

      _thinkingStage = ThinkingStage.idle;
      _lastError = e.toString();

      String friendlyError = e is ApiException
          ? e.message
          : 'Não foi possível enviar a mensagem.';
      if (e is ApiException && e.isUnauthorized) {
        friendlyError =
            'Sua sessão expirou ou sua conta não foi encontrada. Por favor, faça login novamente.';
      }
      if (e is DioException) {
        final data = e.response?.data;
        final detail = data is Map
            ? data['detail']?.toString()
            : data?.toString();
        final statusCode = e.response?.statusCode ?? 0;

        if (detail != null && detail.isNotEmpty) {
          friendlyError = detail;
        } else if (statusCode == 401) {
          friendlyError =
              "Sua sessão expirou ou sua conta não foi encontrada. Por favor, faça login novamente.";
        }
      }

      if (!_isStopped) {
        _messages.add(
          Message(text: friendlyError, isUser: false, role: 'assistant'),
        );
      }
    } finally {
      _isLoading = false;
      _thinkingStage = ThinkingStage.idle;
      _activeCancelToken = null;
      notifyListeners();
    }
    return {};
  }

  /// Envia uma resposta de componente interativo (ex: seleção de contato, aprovação)
  /// como uma nova mensagem no chat, ou continua a mensagem atual se suportado.
  Future<Map<String, dynamic>> sendComponentResponse(
    String componentType,
    Map<String, dynamic> responseData,
  ) async {
    // The server checks this state against its own list of OAuth connections.
    // It is only used to decide whether a connected integration is enabled for
    // the current chat; it can never make a disconnected account executable.
    responseData = {
      ...responseData,
      'active_integrations': _activeIntegrations.toList(),
    };
    final lastMessage = _messages.isNotEmpty ? _messages.last : null;
    final canContinue =
        lastMessage != null && lastMessage.continuationId != null;

    if (canContinue) {
      return await _continueMessageFlow(
        lastMessage,
        componentType,
        responseData,
      );
    }

    // --- Comportamento Legado (para mensagens antigas sem fluxo de continuação) ---

    // Monta texto descritivo para a IA entender
    String responseText;
    switch (componentType) {
      case 'action_approval':
        final approved = responseData['approved'] as bool? ?? false;
        responseText = approved
            ? '[APROVADO] O usuário aprovou a ação.'
            : '[RECUSADO] O usuário recusou a ação.';
        break;
      case 'contact_select':
        final contacts = responseData['selected_contacts'] as List? ?? [];
        responseText = '[CONTATOS SELECIONADOS] ${contacts.join(", ")}';
        break;
      case 'multiple_choice':
        final chosen = responseData['selected_option'] as String? ?? '';
        responseText = '[OPÇÃO SELECIONADA] $chosen';
        break;
      case 'drive_file_select':
        final files = responseData['selected_files'] as List? ?? [];
        responseText = '[ARQUIVOS SELECIONADOS] ${files.join(", ")}';
        break;
      case 'text_input':
        final text = responseData['text'] as String? ?? '';
        responseText = '[RESPOSTA DE TEXTO] $text';
        break;
      case 'date_time_picker':
        final formatted = responseData['formatted'] as String? ?? '';
        responseText = '[DATA/HORA SELECIONADA] $formatted';
        break;
      case 'editable_preview':
        final fields = responseData['fields'] as Map<String, dynamic>? ?? {};
        responseText = '[CONTEÚDO EDITADO/CONFIRMADO] $fields';
        break;
      case 'checklist':
        final items = responseData['items'] as List? ?? [];
        responseText = '[CHECKLIST ATUALIZADO] $items';
        break;
      default:
        responseText = '[RESPOSTA DO COMPONENTE] ${responseData.toString()}';
    }

    // Adiciona como mensagem oculta do usuário
    final hiddenMessage = Message(
      text: responseText,
      isUser: true,
      role: 'user',
      isHidden: true,
    );
    _messages.add(hiddenMessage);
    _isLoading = true;
    _isStopped = false;
    _lastError = null;
    _thinkingStage = ThinkingStage.executing;
    notifyListeners();

    try {
      _activeCancelToken = CancelToken();

      final response = await _repository.sendMessage(
        _currentSessionId,
        responseText,
        model: _selectedModel,
        cancelToken: _activeCancelToken,
      );

      if (_isStopped) return {};

      final assistantMessage = Message(
        text: response['text'] ?? "Entendido.",
        isUser: false,
        role: 'assistant',
        actionTriggered: response['actionTriggered'] ?? false,
        actionDetails: response['actionDetails'],
        components: response['components'] as List<dynamic>?,
        status: (response['status'] as String?) ?? 'idle',
        messageId: response['id'] as String?,
        continuationId: response['continuation_id'] as String?,
      );

      _messages.add(assistantMessage);
      _thinkingStage = ThinkingStage.idle;

      // Atualizar cota do usuário (Quota Sync - Step 03 - Component Response)
      _updateAuthQuota(response);

      notifyListeners();
      return response;
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return {};
      _lastError = e.toString();
      _messages.add(
        Message(
          text: "Erro ao processar resposta: $e",
          isUser: false,
          role: 'assistant',
        ),
      );
    } finally {
      _isLoading = false;
      _thinkingStage = ThinkingStage.idle;
      notifyListeners();
    }
    return {};
  }

  /// Fluxo de Resposta Contínua (Opção A)
  Future<Map<String, dynamic>> _continueMessageFlow(
    Message originalMessage,
    String componentType,
    Map<String, dynamic> responseData,
  ) async {
    _isLoading = true;
    _isStopped = false;
    _lastError = null;
    _thinkingStage = ThinkingStage.executing;
    notifyListeners();

    try {
      _activeCancelToken = CancelToken();

      final response = await _repository.continueMessage(
        sessionId: _currentSessionId!,
        continuationId: originalMessage.continuationId!,
        componentType: componentType,
        responseData: responseData,
        model: _selectedModel,
        cancelToken: _activeCancelToken,
      );

      if (_isStopped) return {};

      final chunk = MessageChunk(
        text: response['text'] ?? "",
        components: response['components'] as List<dynamic>?,
        status: (response['status'] as String?) ?? 'idle',
      );

      originalMessage.addChunk(chunk);
      originalMessage.actionTriggered = response['actionTriggered'] ?? false;
      originalMessage.actionDetails = response['actionDetails'];
      originalMessage.status = chunk.status;
      // Atualiza o continuationId (caso o backend tenha gerado um novo ou mantido o mesmo)
      originalMessage.continuationId = response['continuation_id'] as String?;

      // Atualizar cota do usuário (Quota Sync - Step 03 - Continue Flow)
      _updateAuthQuota(response);

      // Store automation ID for possible cancellation
      _currentAutomationId = response['automation_id'] as String?;

      if (originalMessage.actionTriggered == true &&
          _currentAutomationId != null) {
        _subscribeToAutomation(
          _currentAutomationId!,
          targetMessage: originalMessage,
        );
        _thinkingStage = ThinkingStage.reasoning;
      } else {
        _thinkingStage = ThinkingStage.idle;
      }

      notifyListeners();
      return response;
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return {};
      _lastError = e.toString();
      // Em caso de erro na continuação, podemos adicionar uma nota ou alertar o usuário
      debugPrint("❌ Erro no _continueMessageFlow: $e");
    } finally {
      _isLoading = false;
      _thinkingStage = ThinkingStage.idle;
      _activeCancelToken = null;
      notifyListeners();
    }
    return {};
  }
}
