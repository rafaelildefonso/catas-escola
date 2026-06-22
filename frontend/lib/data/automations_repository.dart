import 'package:supabase_flutter/supabase_flutter.dart';

class AutomationsRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Busca o histórico de execuções do usuário
  Future<List<Map<String, dynamic>>> fetchAutomationRuns({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('automation_runs')
          .select('*, automations(status, name)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Error fetching automation runs: $e");
      rethrow;
    }
  }

  /// Busca os logs de passos de uma execução específica
  Future<List<Map<String, dynamic>>> fetchStepLogs(String runId) async {
    final response = await _client
        .from('automation_step_logs')
        .select('*')
        .eq('run_id', runId)
        .order('step_index', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Atualiza o status de uma automação (para pausar/ativar via tabela automations)
  Future<void> updateAutomationStatus(String automationId, String status) async {
    await _client
        .from('automations')
        .update({'status': status})
        .eq('id', automationId);
  }

  /// Exclui uma automação
  Future<void> deleteAutomation(String automationId) async {
    await _client.from('automations').delete().eq('id', automationId);
  }

  /// Exclui uma execução específica do histórico
  Future<void> deleteRun(String runId) async {
    await _client.from('automation_runs').delete().eq('id', runId);
  }
}
