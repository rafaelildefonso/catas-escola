import 'dart:async';
import 'automations_provider.dart';

/// Demo version of AutomationsProvider that works without Supabase.
/// Provides mock automation runs and step logs for demos.
/// Extends AutomationsProvider for type compatibility.
class DemoAutomationsProvider extends AutomationsProvider {
  final List<AutomationRun> _demoRuns = [];
  bool _demoIsLoading = false;
  bool _demoIsLoadingMore = false;
  bool _demoHasMore = false;
  String? _demoError;

  List<AutomationStepLog> _demoStepLogs = [];
  bool _demoIsLoadingSteps = false;

  String? _lastOnboardingRunId;
  String? get lastOnboardingRunId => _lastOnboardingRunId;

  String _onboardingPhase = 'none';
  String get onboardingPhase => _onboardingPhase;

  Timer? _stepSimulationTimer;

  @override
  List<AutomationRun> get runs => _demoRuns;
  @override
  bool get isLoading => _demoIsLoading;
  @override
  bool get isLoadingMore => _demoIsLoadingMore;
  @override
  bool get hasMore => _demoHasMore;
  @override
  String? get error => _demoError;

  @override
  List<AutomationStepLog> get stepLogs => _demoStepLogs;
  @override
  bool get isLoadingSteps => _demoIsLoadingSteps;

  /// Adds the demo report automation to the list.
  void addReportAutomation() {
    final now = DateTime.now();
    final runId = 'demo-run-${now.millisecondsSinceEpoch}';
    final automationId = 'demo-automation-${now.millisecondsSinceEpoch}';

    final run = AutomationRun(
      id: runId,
      automationId: automationId,
      status: 'completed',
      automationStatus: 'active',
      automationName: 'Relatório de Vendas Semanal',
      runType: 'temporal',
      inputSummary: 'Relatório de Vendas Semanal',
      inputPayload: {
        'modules': ['google_sheets', 'report_generator', 'notifications'],
        'schedule': 'segunda 08:00',
        'sheet_name': 'Vendas 2026',
      },
      createdAt: now,
    );

    _demoRuns.insert(0, run);
    notifyListeners();
  }

  /// Adds the onboarding demo automation run.
  void addOnboardingAutomation(String clientName, String meetingDate, String meetingTime) {
    final now = DateTime.now();
    final runId = 'demo-onb-${now.millisecondsSinceEpoch}';
    final automationId = 'demo-automation-onb-${now.millisecondsSinceEpoch}';
    _lastOnboardingRunId = runId;

    final run = AutomationRun(
      id: runId,
      automationId: automationId,
      status: 'running',
      automationStatus: 'active',
      automationName: 'Onboarding $clientName',
      runType: 'onboarding',
      inputSummary: 'Onboarding de $clientName',
      inputPayload: {
        'client_name': clientName,
        'meeting_date': meetingDate,
        'meeting_time': meetingTime,
        'modules': ['google_calendar', 'google_drive', 'google_sheets'],
      },
      createdAt: now,
    );

    _demoRuns.insert(0, run);
    notifyListeners();
  }

  /// Fetch runs (mock).
  @override
  Future<void> fetchRuns(String userId, {bool refresh = false}) async {
    _demoIsLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    _demoIsLoading = false;
    _demoHasMore = false;
    notifyListeners();
  }

  /// Fetch step logs — simulates real-time for onboarding runs.
  @override
  Future<void> fetchStepLogs(String runId) async {
    _demoIsLoadingSteps = true;
    _demoStepLogs = [];
    _stepSimulationTimer?.cancel();
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final run = _demoRuns.cast<AutomationRun?>().firstWhere(
      (r) => r?.id == runId,
      orElse: () => null,
    );

    if (run != null && run.runType == 'onboarding') {
      _demoIsLoadingSteps = false;
      notifyListeners();
      _simulateOnboardingSteps(run);
    } else {
      _demoStepLogs = _buildReportStepLogs();
      _demoIsLoadingSteps = false;
      notifyListeners();
    }
  }

  Future<void> _simulateOnboardingSteps(AutomationRun run) async {
    final clientName = run.inputPayload['client_name'] ?? 'João Silva';
    final meetingDate = run.inputPayload['meeting_date'] ?? '2026-06-19';
    final meetingTime = run.inputPayload['meeting_time'] ?? '14:00';

    final stepDefs = [
      {
        'name': 'Criar evento no Google Calendar',
        'type': 'google_calendar.create_event',
        'subtitle': 'Agendando reunião de onboarding',
        'description':
            'O CATAS acessa seu Google Calendar e cria um evento para a reunião de onboarding com $clientName em $meetingDate às $meetingTime.',
        'metadata': {
          'event': 'Onboarding $clientName',
          'date': meetingDate,
          'time': meetingTime,
          'calendar': 'Google Calendar',
        },
      },
      {
        'name': 'Criar pasta no Google Drive',
        'type': 'google_drive.create_folder',
        'subtitle': 'Organizando documentos do cliente',
        'description':
            'O CATAS cria uma pasta dedicada para $clientName no Google Drive, dentro de "Clientes", com as permissões corretas de acesso.',
        'metadata': {
          'folder': 'Clientes/$clientName',
          'permissions': 'Restrito à equipe',
          'drive': 'Google Drive',
        },
      },
      {
        'name': 'Registrar no Google Sheets',
        'type': 'google_sheets.append_row',
        'subtitle': 'Atualizando planilha de onboarding',
        'description':
            'O CATAS adiciona uma nova linha na planilha de onboarding com os dados de $clientName, mantendo o CRM sempre atualizado.',
        'metadata': {
          'sheet': 'Onboarding',
          'row': 'Última linha',
          'data': '$clientName | $meetingDate $meetingTime',
          'sheets': 'Google Sheets',
        },
      },
    ];

    _onboardingPhase = 'appearing';

    // Phase 1: Steps appear one by one as pending
    for (int i = 0; i < stepDefs.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      _demoStepLogs.add(AutomationStepLog(
        id: 'onb-step-$i',
        stepIndex: i,
        stepName: stepDefs[i]['name'] as String,
        stepType: stepDefs[i]['type'] as String,
        status: 'pending',
        durationMs: null,
        metadata: stepDefs[i] as Map<String, dynamic>,
        updatedAt: DateTime.now(),
      ));
      notifyListeners();
    }

    // Phase 2: Execute each step in sequence
    _onboardingPhase = 'executing';
    notifyListeners();

    for (int i = 0; i < stepDefs.length; i++) {
      await Future.delayed(const Duration(milliseconds: 800));

      if (i < _demoStepLogs.length && _demoStepLogs[i].status != 'success') {
        _demoStepLogs[i] = AutomationStepLog(
          id: 'onb-step-$i',
          stepIndex: i,
          stepName: stepDefs[i]['name'] as String,
          stepType: stepDefs[i]['type'] as String,
          status: 'running',
          durationMs: null,
          metadata: stepDefs[i] as Map<String, dynamic>,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      await Future.delayed(const Duration(milliseconds: 1000));

      if (i < _demoStepLogs.length) {
        _demoStepLogs[i] = AutomationStepLog(
          id: 'onb-step-$i',
          stepIndex: i,
          stepName: stepDefs[i]['name'] as String,
          stepType: stepDefs[i]['type'] as String,
          status: 'success',
          durationMs: 1000,
          metadata: stepDefs[i] as Map<String, dynamic>,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    }

    // Phase 3: Completed
    _onboardingPhase = 'completed';
    notifyListeners();

    final runIdx = _demoRuns.indexWhere((r) => r.id == run.id);
    if (runIdx != -1) {
      _demoRuns[runIdx] = _demoRuns[runIdx].copyWith(
        status: 'completed',
        finishedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// Toggle automation status (mock).
  @override
  Future<void> toggleAutomationStatus(String automationId, bool active) async {
    final newStatus = active ? 'active' : 'paused';
    for (int i = 0; i < _demoRuns.length; i++) {
      if (_demoRuns[i].automationId == automationId) {
        _demoRuns[i] = _demoRuns[i].copyWith(automationStatus: newStatus);
      }
    }
    notifyListeners();
  }

  /// Delete automation (mock).
  @override
  Future<void> deleteAutomation(String automationId) async {
    _demoRuns.removeWhere((r) => r.automationId == automationId);
    notifyListeners();
  }

  /// Delete run (mock).
  @override
  Future<void> deleteRun(String runId) async {
    _demoRuns.removeWhere((r) => r.id == runId);
    notifyListeners();
  }

  List<AutomationStepLog> _buildReportStepLogs() {
    final now = DateTime.now();
    return [
      AutomationStepLog(
        id: 'step-1',
        stepIndex: 0,
        stepName: 'Acessar Google Sheets',
        stepType: 'google_sheets.read',
        status: 'success',
        durationMs: 1200,
        metadata: {
          'sheet_name': 'Vendas 2026',
          'rows_read': 312,
          'columns': ['Data', 'Produto', 'Categoria', 'Quantidade', 'Valor'],
        },
        updatedAt: now,
      ),
      AutomationStepLog(
        id: 'step-2',
        stepIndex: 1,
        stepName: 'Filtrar Dados da Última Semana',
        stepType: 'google_sheets.filter',
        status: 'success',
        durationMs: 800,
        metadata: {
          'date_range': '20/04/2026 - 26/04/2026',
          'rows_filtered': 87,
        },
        updatedAt: now,
      ),
      AutomationStepLog(
        id: 'step-3',
        stepIndex: 2,
        stepName: 'Calcular Totais por Produto',
        stepType: 'report_generator.aggregate',
        status: 'success',
        durationMs: 650,
        metadata: {
          'total_revenue': 'R\$ 47.832,00',
          'total_orders': 312,
          'avg_ticket': 'R\$ 153,00',
          'growth': '+12,3%',
        },
        updatedAt: now,
      ),
      AutomationStepLog(
        id: 'step-4',
        stepIndex: 3,
        stepName: 'Gerar Relatório em PDF',
        stepType: 'report_generator.pdf',
        status: 'success',
        durationMs: 2100,
        metadata: {
          'file_name': 'relatorio_vendas_semanal_2026-04-26.pdf',
          'pages': 3,
          'size_kb': 245,
        },
        updatedAt: now,
      ),
      AutomationStepLog(
        id: 'step-5',
        stepIndex: 4,
        stepName: 'Enviar Notificação',
        stepType: 'notifications.push',
        status: 'success',
        durationMs: 300,
        metadata: {
          'channel': 'FCM',
          'title': 'Relatório de Vendas Semanal',
          'body': 'Seu relatório está pronto! Clique para visualizar.',
        },
        updatedAt: now,
      ),
    ];
  }

  @override
  void dispose() {
    _stepSimulationTimer?.cancel();
    super.dispose();
  }
}
