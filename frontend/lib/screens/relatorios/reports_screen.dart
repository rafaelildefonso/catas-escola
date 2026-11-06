import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/relatorios/report_export_delivery.dart';
import '../../core/router.dart';
import '../../data/generated_reports_repository.dart';
import '../../providers/generated_reports_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<GeneratedReportsProvider>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GeneratedReportsProvider>();
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: state.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
        children: [
          Text(
            'Relatórios',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Relatórios criados pelas suas automações ficam guardados aqui.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _HowItWorksCard(onCreate: () => context.go(AppRoutes.chat)),
          const SizedBox(height: 24),
          if (state.isLoading && state.reports.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.error != null && state.reports.isEmpty)
            _ErrorState(message: state.error!, onRetry: state.load)
          else if (state.reports.isEmpty)
            const _EmptyReportsState()
          else ...[
            Text(
              '${state.reports.length} relatório(s)',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 10),
            ...state.reports.map((report) => _ReportCard(report: report)),
          ],
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  final VoidCallback onCreate;
  const _HowItWorksCard({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_graph_rounded,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Relatórios automáticos com IA',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Peça no chat: “Quero um relatório de vendas das minhas planilhas toda segunda-feira”. '
            'O CATAS lê os dados, organiza os números, cria gráficos e salva o PDF aqui.',
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_chart_outlined),
            label: const Text('Criar automação de relatório'),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatefulWidget {
  final Map<String, dynamic> report;
  const _ReportCard({required this.report});

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final response = await GeneratedReportsRepository().baixar(
        widget.report['id'] as String,
      );
      final title = (widget.report['title'] as String? ?? 'relatorio')
          .replaceAll('/', '-');
      await deliverReportExport(
        response.bodyBytes,
        '$title.pdf',
        'application/pdf',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = Map<String, dynamic>.from(
      widget.report['metrics'] as Map? ?? const {},
    );
    final source = widget.report['source_name'] as String?;
    final summary = widget.report['summary'] as String?;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.report['title'] as String? ?? 'Relatório',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (source?.isNotEmpty ?? false)
                        Text(
                          source!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _downloading ? null : _download,
                  tooltip: 'Baixar PDF',
                  icon: _downloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                ),
              ],
            ),
            if (summary?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Text(summary!, maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  label: '${metrics['rows_analyzed'] ?? 0} linhas analisadas',
                ),
                if (metrics.containsKey('total'))
                  _MetricChip(label: 'Total ${metrics['total']}'),
                _MetricChip(
                  label: _date(widget.report['created_at'] as String?),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _date(String? value) {
    if (value == null || value.length < 10) return 'Gerado agora';
    final parts = value.substring(0, 10).split('-');
    return parts.length == 3
        ? 'Gerado em ${parts[2]}/${parts[1]}/${parts[0]}'
        : 'Gerado';
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  const _MetricChip({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelSmall),
  );
}

class _EmptyReportsState extends StatelessWidget {
  const _EmptyReportsState();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
    child: Column(
      children: [
        Icon(Icons.folder_open_outlined, size: 48),
        SizedBox(height: 12),
        Text('Nenhum relatório pronto ainda.', textAlign: TextAlign.center),
        SizedBox(height: 6),
        Text(
          'Quando uma automação de relatório terminar, o PDF aparecerá aqui.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
      ],
    ),
  );
}
