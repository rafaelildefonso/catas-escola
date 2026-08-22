import 'dart:async';
import 'package:dio/dio.dart';
import 'chat_repository_interface.dart';
import 'package:uuid/uuid.dart';

/// Tracks the conversation flow state per session for the report demo.
enum _ReportFlowStep {
  none,
  askedReport,
  providedSource,
  approved,
}

/// Tracks onboarding demo state per session.
enum _OnboardingFlowStep {
  none,
  completed,
}

const Map<String, int> _weekdayMap = {
  "segunda": 1, "segunda-feira": 1,
  "terça": 2, "terça-feira": 2, "terca": 2, "terca-feira": 2,
  "quarta": 3, "quarta-feira": 3,
  "quinta": 4, "quinta-feira": 4,
  "sexta": 5, "sexta-feira": 5,
  "sábado": 6, "sabado": 6,
  "domingo": 7,
};

String _resolveDate(String dayRef) {
  final today = DateTime.now();
  final lower = dayRef.trim().toLowerCase();

  if (lower == "hoje") return _formatDate(today);
  if (lower == "amanhã" || lower == "amanha") return _formatDate(today.add(const Duration(days: 1)));
  if (lower == "depois de amanhã" || lower == "depois de amanha") return _formatDate(today.add(const Duration(days: 2)));

  final target = _weekdayMap[lower];
  if (target != null) {
    int current = today.weekday; // DateTime.monday = 1
    int daysAhead = target - current;
    if (daysAhead <= 0) daysAhead += 7;
    return _formatDate(today.add(Duration(days: daysAhead)));
  }

  return _formatDate(today.add(const Duration(days: 1)));
}

String _formatDate(DateTime dt) => "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

class DemoRepository implements IChatRepository {
  final _uuid = const Uuid();

  // Local state for demo purposes
  final List<Map<String, dynamic>> _sessions = [];
  final Map<String, List<Map<String, dynamic>>> _messages = {};

  // Per-session flow tracking for the report demo
  final Map<String, _ReportFlowStep> _reportFlow = {};

  // Per-session flow tracking for the onboarding demo
  final Map<String, _OnboardingFlowStep> _onboardingFlow = {};

  // The automation ID created in the report flow
  String? _demoAutomationId;

  String? get demoAutomationId => _demoAutomationId;

  // Simulate network delay
  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 1000));

  @override
  Future<List<Map<String, dynamic>>> getSessions({int limit = 50, int offset = 0}) async {
    await _delay();
    return List.from(_sessions.reversed.skip(offset).take(limit));
  }

  @override
  Future<Map<String, dynamic>> createSession({String? title}) async {
    await _delay();
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final newSession = {
      "id": id,
      "title": title ?? "Nova Conversa Demo",
      "created_at": now,
      "updated_at": now,
    };

    _sessions.add(newSession);
    _messages[id] = [];

    return newSession;
  }

  @override
  Future<void> renameSession(String sessionId, String title) async {
    await _delay();
    final index = _sessions.indexWhere((s) => s["id"] == sessionId);
    if (index != -1) {
      _sessions[index]["title"] = title;
      _sessions[index]["updated_at"] = DateTime.now().toIso8601String();
    }
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await _delay();
    _sessions.removeWhere((s) => s["id"] == sessionId);
    _messages.remove(sessionId);
  }

  @override
  Future<List<Map<String, dynamic>>> getHistory(
    String sessionId, {
    int limit = 100,
    int offset = 0,
  }) async {
    await _delay();
    final history = _messages[sessionId] ?? [];
    return List.from(history.skip(offset).take(limit));
  }

  @override
  Future<Map<String, dynamic>> sendMessage(
    String? sessionId,
    String text, {
    String? model,
    String? currentPageUrl,
    String? currentPageTitle,
    bool webSearch = false,
    List<String>? activeIntegrations,
    List<String>? attachmentUrls,
    CancelToken? cancelToken,
  }) async {
    await _delay();

    if (cancelToken?.isCancelled == true) {
      throw Exception("cancelled");
    }

    String actualSessionId = sessionId ?? _uuid.v4();
    if (sessionId == null) {
      final now = DateTime.now().toIso8601String();
      _sessions.add({
        "id": actualSessionId,
        "title": text.length > 20 ? text.substring(0, 20) : text,
        "created_at": now,
        "updated_at": now,
      });
      _messages[actualSessionId] = [];
    }

    // Update session timestamp
    final index = _sessions.indexWhere((s) => s["id"] == actualSessionId);
    if (index != -1) {
      _sessions[index]["updated_at"] = DateTime.now().toIso8601String();
    }

    final now = DateTime.now().toIso8601String();

    // Save user message
    _messages[actualSessionId]!.add({
      "id": _uuid.v4(),
      "session_id": actualSessionId,
      "role": "user",
      "content": text,
      "metadata": {},
      "created_at": now,
    });

    // Generate mock assistant response
    String responseText = "Entendi. Como posso ajudar com mais alguma coisa?";
    bool actionTriggered = false;
    Map<String, dynamic>? actionDetails;
    List<dynamic>? components;
    String? automationId;
    String status = 'idle';

    final lowerText = text.toLowerCase();
    final reportFlowStep = _reportFlow[actualSessionId] ?? _ReportFlowStep.none;
    final onboardingFlowStep = _onboardingFlow[actualSessionId] ?? _OnboardingFlowStep.none;

    // === ONBOARDING DEMO FLOW ===
    if (onboardingFlowStep == _OnboardingFlowStep.none) {
      final onboardingData = _detectOnboarding(lowerText);
      if (onboardingData != null) {
        _onboardingFlow[actualSessionId] = _OnboardingFlowStep.completed;

        final clientName = onboardingData["name"] as String;
        final meetingDate = onboardingData["date"] as String;
        final meetingTime = onboardingData["time"] as String;

        final demoAutomationId = _uuid.v4();

        responseText = "**Onboarding de $clientName iniciado!**\n\n"
            "Acompanhe o progresso:";

        actionTriggered = true;
        actionDetails = {
          "intent": "demo_onboarding",
          "action": "Onboarding de $clientName",
          "description": "Organizar onboarding para $clientName em $meetingDate às $meetingTime",
          "payload": {
            "client_name": clientName,
            "meeting_date": meetingDate,
            "meeting_time": meetingTime,
          },
        };
        automationId = demoAutomationId;

        components = [
          {
            "type": "automation_progress",
            "data": {
              "automation_id": demoAutomationId,
              "title": "Onboarding $clientName",
              "steps": [
                {"module_id": "google_calendar.create_event", "status": "pending"},
                {"module_id": "google_drive.create_folder", "status": "pending"},
                {"module_id": "google_sheets.append_row", "status": "pending"},
              ],
            },
          },
        ];
      }
    }

    // === REPORT DEMO FLOW ===
    if (_isReportRequest(lowerText) && reportFlowStep == _ReportFlowStep.none) {
      // Turn 1: User asks for report → IA asks for data source
      _reportFlow[actualSessionId] = _ReportFlowStep.askedReport;
      responseText = "Para gerar esse relatório, preciso saber onde estão seus dados. Em qual planilha do Google Sheets estão as vendas?";
      components = [
        {
          "type": "text_input",
          "data": {
            "prompt": "Informe a planilha de origem",
            "placeholder": "Ex: Vendas 2026",
            "field_id": "sheet_name",
          },
        },
      ];
      status = 'requires_action';
    } else if (reportFlowStep == _ReportFlowStep.askedReport &&
        (lowerText.contains("sheets") || lowerText.contains("planilha") || lowerText.contains("vendas"))) {
      // Turn 2: User provides source → IA shows automation plan with approval
      _reportFlow[actualSessionId] = _ReportFlowStep.providedSource;
      responseText = "Perfeito! Vou criar uma automação que toda **segunda-feira às 08:00** vai:\n\n"
          "1. Acessar a planilha **Vendas 2026** no Google Sheets\n"
          "2. Filtrar os dados da última semana\n"
          "3. Calcular totais por produto e categoria\n"
          "4. Gerar o relatório formatado em PDF\n"
          "5. Te notificar quando estiver pronto\n\n"
          "Confira o roteiro abaixo e aprove para criar a automação.";
      actionTriggered = true;
      actionDetails = {
        "intent": "report_weekly_sales",
        "action": "Relatório de Vendas Semanal",
        "description": "Gera relatório de vendas toda segunda às 08:00",
        "payload": {
          "modules": ["google_sheets", "report_generator", "notifications"],
          "schedule": "segunda 08:00",
          "sheet_name": "Vendas 2026",
        },
      };
      components = [
        {
          "type": "action_approval",
          "data": {
            "title": "Criar Automação: Relatório de Vendas Semanal",
            "description": "Toda segunda-feira às 08:00, o CATAS vai acessar a planilha Vendas 2026, processar os dados e te notificar com o relatório pronto.",
            "danger_level": "low",
            "action": "create_automation",
          },
        },
      ];
      status = 'requires_action';
    } else if (reportFlowStep == _ReportFlowStep.providedSource &&
        (lowerText.contains("aprovar") || lowerText.contains("aprovo") || lowerText == "approved")) {
      // Turn 3: User approves → IA confirms automation creation
      _reportFlow[actualSessionId] = _ReportFlowStep.approved;
      _demoAutomationId = _uuid.v4();
      automationId = _demoAutomationId;
      responseText = "Automação criada com sucesso! Toda segunda às 08:00, o CATAS vai gerar seu relatório de vendas e te notificar.\n\n"
          "Você pode acompanhar o status na aba de **Automações**.";
      actionTriggered = true;
      actionDetails = {
        "intent": "report_weekly_sales",
        "action": "Automação Criada",
        "description": "Relatório de Vendas Semanal — segunda 08:00",
        "payload": {
          "modules": ["google_sheets", "report_generator", "notifications"],
          "automation_id": _demoAutomationId,
        },
      };
      components = [
        {
          "type": "automation_result",
          "data": {
            "action": "Relatório de Vendas Semanal",
            "status": "success",
            "description": "Automação agendada para toda segunda às 08:00",
          },
        },
      ];
    }
    // === EXISTING DEMO FLOWS ===
    else if (lowerText.contains("reunião") || lowerText.contains("agendar")) {
      responseText = "Reunião agendada com sucesso no seu calendário.";
      actionTriggered = true;
      actionDetails = {
        "intent": "calendar_create_event",
        "action": "Agendamento",
        "description": "Evento criado no Google Calendar.",
        "payload": {
          "title": "Reunião de Alinhamento",
          "date": DateTime.now()
              .add(const Duration(days: 1))
              .toIso8601String()
              .split("T")[0],
          "time": "14:00",
        },
      };
    } else if (lowerText.contains("tarefa") || lowerText.contains("lembrar")) {
      responseText = "Tarefa adicionada à sua lista.";
      actionTriggered = true;
      actionDetails = {
        "intent": "task_create",
        "action": "Nova Tarefa",
        "description": "Tarefa criada no Notion.",
        "payload": {
          "task_name": "Lembrar de revisar o projeto",
          "priority": "Alta",
        },
      };
    } else if (lowerText.contains("email")) {
      responseText = "Rascunho de e-mail gerado. Acesse seu Gmail para enviar.";
      actionTriggered = true;
      actionDetails = {
        "intent": "email_draft",
        "action": "Rascunho criado",
        "description": "Email preparado no Gmail.",
        "payload": {
          "subject": "Aviso Importante",
          "recipient": "equipe@escola.com",
        },
      };
    }

    // Save assistant message
    _messages[actualSessionId]!.add({
      "id": _uuid.v4(),
      "session_id": actualSessionId,
      "role": "assistant",
      "content": responseText,
      "metadata": {
        "action_triggered": actionTriggered,
        "action_details": actionDetails,
        "components": components,
      },
      "created_at": DateTime.now().toIso8601String(),
    });

    return {
      "id": _uuid.v4(),
      "session_id": actualSessionId,
      "text": responseText,
      "actionTriggered": actionTriggered,
      "actionDetails": actionDetails,
      "components": components,
      "status": status,
      "automation_id": automationId,
    };
  }

  bool _isReportRequest(String lowerText) {
    return (lowerText.contains("relatório") || lowerText.contains("relatorio")) &&
        (lowerText.contains("vendas") || lowerText.contains("semanal") || lowerText.contains("report"));
  }

  Map<String, dynamic>? _detectOnboarding(String lowerText) {
    final patterns = [
      RegExp(r'(?:fechamos\s+contrato|contrato\s+fechado|novo\s+cliente|onboarding)\s*(?:com|do|da|para|de)?\s*[:\-]?\s*([a-zà-ÿ\s]+?)(?:\s*[.,;!?]|\s+e\s+|\s+para\s+|\s+organize\s+|\s+agende\s+|\s*$)'),
      RegExp(r'(?:contrato|cliente)\s+(?:com|do|da|para|de)\s+([a-zà-ÿ\s]+?)(?:\s*[.,;!?]|\s+para\s+|\s+organize\s+|\s+agende\s+|\s*$)'),
    ];

    String? name;
    for (final pattern in patterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null) {
        final candidate = match.group(1)!.trim();
        if (candidate.length > 1) {
          name = candidate[0].toUpperCase() + candidate.substring(1);
          break;
        }
      }
    }
    if (name == null) return null;

    String time = "14:00";
    final timeMatch = RegExp(r'(\d{1,2})\s*[h:]\s*(\d{2})?\s*(?:h|hrs|horas)?').firstMatch(lowerText);
    if (timeMatch != null) {
      time = "${timeMatch.group(1)!.padLeft(2, '0')}:${(timeMatch.group(2) ?? '00').padLeft(2, '0')}";
    }

    String? date;
    final dateMatch = RegExp(
      r'(sexta|segunda|terça|quarta|quinta|sábado|domingo|hoje|amanhã|depois de amanhã|depois de amanha|sabado|terca)',
      caseSensitive: false,
    ).firstMatch(lowerText);
    if (dateMatch != null) {
      date = _resolveDate(dateMatch.group(1)!);
    }
    date ??= _formatDate(DateTime.now().add(const Duration(days: 1)));

    return {"name": name, "date": date, "time": time};
  }

  @override
  Future<void> sendFeedback({
    required String messageId,
    required String sessionId,
    required bool? isLiked,
    String? reason,
  }) async {
    await _delay();
    // No-op for demo
  }

  @override
  Future<Map<String, dynamic>> continueMessage({
    required String sessionId,
    required String continuationId,
    required String componentType,
    required Map<String, dynamic> responseData,
    String? model,
    CancelToken? cancelToken,
  }) async {
    await _delay();

    // Map component response to a natural language message to reuse sendMessage logic
    String simulatedText = "";
    if (componentType == 'text_input') {
      simulatedText = responseData['text'] ?? responseData['value'] ?? responseData['sheet_name'] ?? "";
    } else if (componentType == 'action_approval') {
      simulatedText = responseData['approved'] == true ? "approved" : "cancelled";
    }

    return sendMessage(
      sessionId,
      simulatedText,
      model: model,
      cancelToken: cancelToken,
    );
  }
}
