import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SheetsTablePreviewComponent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isEnabled;

  const SheetsTablePreviewComponent({
    super.key,
    required this.data,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Resumo da Planilha';
    final headers = (data['headers'] as List<dynamic>? ?? []).cast<String>();
    final rowsData = data['rows'] as List<dynamic>? ?? [];

    const Color sheetsGreen = Color(0xFF0F9D58);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: sheetsGreen.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: sheetsGreen.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.table_chart_outlined,
                  color: sheetsGreen,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sheetsGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Theme(
                data: Theme.of(context).copyWith(
                  dataTableTheme: DataTableThemeData(
                    headingRowColor: WidgetStatePropertyAll(
                      Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                child: DataTable(
                  columns: headers
                      .map(
                        (h) => DataColumn(
                          label: Text(
                            h,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  rows: rowsData.map((row) {
                    final cells = (row as List<dynamic>).cast<String>();
                    return DataRow(
                      cells: cells
                          .map(
                            (c) => DataCell(
                              Text(c, style: GoogleFonts.inter(fontSize: 13)),
                            ),
                          )
                          .toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
