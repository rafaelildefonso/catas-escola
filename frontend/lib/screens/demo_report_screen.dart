import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

/// Demo report screen showing a beautiful sales report.
class DemoReportScreen extends StatelessWidget {
  const DemoReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Relatório de Vendas',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PDF salvo com sucesso!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Baixar PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildSummaryCards(context),
                const SizedBox(height: 32),
                _buildSalesChart(context),
                const SizedBox(height: 32),
                _buildTopProductsTable(context),
                const SizedBox(height: 32),
                _buildCategoryBreakdown(context),
                const SizedBox(height: 48),
              ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.1),
            colorScheme.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.assessment_rounded, color: colorScheme.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Relatório de Vendas Semanal',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Período: 20/04/2026 — 26/04/2026',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text(
                      '+12,3%',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Fonte: Google Sheets — "Vendas 2026"',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final cards = [
      _SummaryCardData(
        title: 'Total de Vendas',
        value: 'R\$ 47.832',
        icon: Icons.attach_money_rounded,
        color: Colors.green,
        subtitle: '+12,3% vs semana anterior',
      ),
      _SummaryCardData(
        title: 'Pedidos',
        value: '312',
        icon: Icons.shopping_cart_rounded,
        color: Colors.blue,
        subtitle: '+8,7% vs semana anterior',
      ),
      _SummaryCardData(
        title: 'Ticket Médio',
        value: 'R\$ 153',
        icon: Icons.receipt_long_rounded,
        color: Colors.orange,
        subtitle: '+3,3% vs semana anterior',
      ),
      _SummaryCardData(
        title: 'Produtos Vendidos',
        value: '487',
        icon: Icons.inventory_2_rounded,
        color: Colors.purple,
        subtitle: '+15,1% vs semana anterior',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: crossCount == 4 ? 1.2 : 1.4,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => _buildSummaryCard(context, cards[index]),
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, _SummaryCardData data) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.color, size: 20),
              ),
              const Spacer(),
              Icon(Icons.trending_up, size: 14, color: Colors.green[400]),
            ],
          ),
          const Spacer(),
          Text(
            data.value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.green[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vendas por Dia',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10000,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
                        if (value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              days[value.toInt()],
                              style: GoogleFonts.inter(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          'R\$ ${(value / 1000).toStringAsFixed(0)}k',
                          style: GoogleFonts.inter(fontSize: 11, color: colorScheme.onSurfaceVariant),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2500,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.onSurface.withValues(alpha: 0.06),
                    strokeWidth: 1,
                  ),
                ),
                barGroups: [
                  _makeBarGroup(0, 5420, colorScheme),
                  _makeBarGroup(1, 6890, colorScheme),
                  _makeBarGroup(2, 7230, colorScheme),
                  _makeBarGroup(3, 8150, colorScheme),
                  _makeBarGroup(4, 9340, colorScheme),
                  _makeBarGroup(5, 6120, colorScheme),
                  _makeBarGroup(6, 4682, colorScheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double value, ColorScheme colorScheme) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          color: colorScheme.primary,
          width: 28,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _buildTopProductsTable(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final products = [
      _ProductData('Notebook Pro 15"', 42, 'R\$ 18.900', '39,5%'),
      _ProductData('Monitor UltraWide 34"', 38, 'R\$ 11.020', '23,0%'),
      _ProductData('Teclado Mecânico RGB', 87, 'R\$ 6.960', '14,6%'),
      _ProductData('Mouse Ergonômico Pro', 65, 'R\$ 5.200', '10,9%'),
      _ProductData('Webcam 4K HDR', 53, 'R\$ 3.710', '7,8%'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 5 Produtos',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 500) {
                return Column(
                  children: [
                    _buildTableHeader(context),
                    ...products.map((p) => _buildProductRow(context, p)),
                  ],
                );
              }
              return Column(
                children: products.map((p) => _buildProductVertical(context, p)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Produto', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant))),
          Expanded(flex: 1, child: Text('Qtd', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant), textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text('Receita', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant), textAlign: TextAlign.right)),
          Expanded(flex: 1, child: Text('% Total', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildProductRow(BuildContext context, _ProductData product) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(product.name, style: GoogleFonts.inter(fontSize: 14, color: colorScheme.onSurface, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          Expanded(flex: 1, child: Text('${product.qty}', style: GoogleFonts.inter(fontSize: 14, color: colorScheme.onSurface), textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text(product.revenue, style: GoogleFonts.inter(fontSize: 14, color: colorScheme.onSurface), textAlign: TextAlign.right)),
          Expanded(flex: 1, child: Text(product.percent, style: GoogleFonts.inter(fontSize: 14, color: colorScheme.primary, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildProductVertical(BuildContext context, _ProductData product) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.05))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.name, style: GoogleFonts.inter(fontSize: 14, color: colorScheme.onSurface, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text('Qtd: ${product.qty}', style: GoogleFonts.inter(fontSize: 12, color: colorScheme.onSurfaceVariant)),
              ),
              Text(product.revenue, style: GoogleFonts.inter(fontSize: 12, color: colorScheme.onSurface, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text(product.percent, style: GoogleFonts.inter(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categories = [
      _CategoryData('Informática', 'R\$ 29.920', '62,6%', Colors.blue),
      _CategoryData('Periféricos', 'R\$ 12.160', '25,4%', Colors.orange),
      _CategoryData('Acessórios', 'R\$ 5.752', '12,0%', Colors.purple),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vendas por Categoria',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...categories.map((c) => _buildCategoryBar(context, c)),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(BuildContext context, _CategoryData cat) {
    final colorScheme = Theme.of(context).colorScheme;
    final percentValue = double.parse(cat.percent.replaceAll('%', '').replaceAll(',', '.'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: cat.color, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(cat.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
              ),
              Text(cat.revenue, style: GoogleFonts.inter(fontSize: 14, color: colorScheme.onSurface)),
              const SizedBox(width: 8),
              Text(cat.percent, style: GoogleFonts.inter(fontSize: 13, color: cat.color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percentValue / 100,
              backgroundColor: colorScheme.onSurface.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(cat.color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  _SummaryCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });
}

class _ProductData {
  final String name;
  final int qty;
  final String revenue;
  final String percent;

  _ProductData(this.name, this.qty, this.revenue, this.percent);
}

class _CategoryData {
  final String name;
  final String revenue;
  final String percent;
  final Color color;

  _CategoryData(this.name, this.revenue, this.percent, this.color);
}
