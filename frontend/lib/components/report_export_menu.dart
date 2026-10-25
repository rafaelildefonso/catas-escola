import 'package:flutter/material.dart';

import '../data/relatorio_repository.dart';
import 'report_export_delivery.dart';

class ReportExportMenu extends StatefulWidget {
  final String userId;
  final String tipo;
  final Map<String, String> filtros;

  const ReportExportMenu({
    super.key,
    required this.userId,
    required this.tipo,
    this.filtros = const {},
  });

  @override
  State<ReportExportMenu> createState() => _ReportExportMenuState();
}

class _ReportExportMenuState extends State<ReportExportMenu> {
  bool _exportando = false;

  Future<void> _exportar(String formato) async {
    setState(() => _exportando = true);
    try {
      final response = await RelatorioRepository().exportar(
        userId: widget.userId,
        tipo: widget.tipo,
        formato: formato,
        filtros: widget.filtros,
      );
      final nome = 'relatorio-${widget.tipo}.$formato';
      final mimeType = switch (formato) {
        'xlsx' =>
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'pdf' => 'application/pdf',
        _ => 'text/csv;charset=utf-8',
      };
      await deliverReportExport(response.bodyBytes, nome, mimeType);
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erro.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      enabled: !_exportando,
      tooltip: 'Exportar relatório',
      onSelected: _exportar,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'csv', child: Text('CSV')),
        PopupMenuItem(value: 'xlsx', child: Text('Excel (.xlsx)')),
        PopupMenuItem(value: 'pdf', child: Text('PDF')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_exportando)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.download_outlined, size: 18),
            const SizedBox(width: 8),
            const Text('Exportar'),
          ],
        ),
      ),
    );
  }
}
