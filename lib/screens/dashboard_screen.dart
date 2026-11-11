import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../db.dart';
import '../main.dart';
import '../models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _totalRevenue = 0;
  double _monthRevenue = 0;
  int _doneCount = 0;
  int _pendingCount = 0;
  Map<String, int> _typeCounts = {};
  Map<String, double> _monthlyRevenue = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppDb.instance.addListener(_onDbUpdated);
    _load();
  }

  void _onDbUpdated() {
    if (mounted) _load();
  }

  @override
  void dispose() {
    AppDb.instance.removeListener(_onDbUpdated);
    super.dispose();
  }

  Future<void> _exportCsvReport() async {
    final allServices = await AppDb.instance.services();
    final buffer = StringBuffer();
    buffer.writeln('ID;Cliente;Data;Tipo;Preco;Estado;Notas');
    for (final s in allServices) {
      buffer.writeln(
        '${s.id};"${s.clientName}";"${fmtDate(s.date)} ${fmtTime(s.date)}";"${s.type}";${s.price.toStringAsFixed(2)};"${s.done ? "Concluido" : "Pendente"}";"${s.notes.replaceAll('"', '""')}"',
      );
    }
    final bytes = Uint8List.fromList(buffer.toString().codeUnits);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'relatorio_servicos_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
  }

  Future<void> _load() async {
    // Garante que existem dados de exemplo se a base de dados estiver vazia
    await AppDb.instance.seedSampleData();

    final total = await AppDb.instance.totalRevenue();
    final month = await AppDb.instance.currentMonthRevenue();
    final done = await AppDb.instance.doneServicesCount();
    final pending = await AppDb.instance.pendingServicesCount();
    final types = await AppDb.instance.servicesCountByType();
    final monthly = await AppDb.instance.monthlyRevenueLast6Months();

    if (!mounted) return;
    setState(() {
      _totalRevenue = total;
      _monthRevenue = month;
      _doneCount = done;
      _pendingCount = pending;
      _typeCounts = types;
      _monthlyRevenue = monthly;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumo Operacional & Financeiro',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Visão geral da atividade e faturação',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Exportar CSV',
                    icon: const Icon(Icons.download, size: 20),
                    onPressed: _exportCsvReport,
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Recarregar Dados',
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _load,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grid de Cards com Métricas Principais
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  title: 'Faturação do Mês',
                  value: fmtCurrency(_monthRevenue),
                  subtitle: 'Mês Atual',
                  icon: Icons.euro,
                  color: gardenGreen,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  title: 'Faturação Total',
                  value: fmtCurrency(_totalRevenue),
                  subtitle: 'Acumulado Total',
                  icon: Icons.account_balance_wallet,
                  color: gardenForest,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  title: 'Serviços Efetuados',
                  value: '$_doneCount',
                  subtitle: 'Concluídos com Sucesso',
                  icon: Icons.check_circle_outline,
                  color: Colors.blue.shade600,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  title: 'Serviços Pendentes',
                  value: '$_pendingCount',
                  subtitle: 'Agendados para Breve',
                  icon: Icons.schedule,
                  color: Colors.orange.shade700,
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Gráfico de Barras - Faturação dos Últimos 6 Meses
          const Text(
            'Evolução da Faturação (€)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Histórico de receitas faturadas nos últimos 6 meses',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 16, left: 12, right: 16),
              child: SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _calculateInterval(),
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (val, meta) {
                            final keys = _monthlyRevenue.keys.toList();
                            if (val.toInt() >= 0 && val.toInt() < keys.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  keys[val.toInt()],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final keys = _monthlyRevenue.keys.toList();
                          final monthName = keys[group.x.toInt()];
                          return BarTooltipItem(
                            '$monthName\n${fmtCurrency(rod.toY)}',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          );
                        },
                      ),
                    ),
                    barGroups: [
                      for (int i = 0; i < _monthlyRevenue.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: _monthlyRevenue.values.elementAt(i),
                              gradient: LinearGradient(
                                colors: [gardenGreen, gardenForest],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              width: 22,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Gráfico Circular - Distribuição dos Tipos de Serviço
          const Text(
            'Distribuição por Tipo de Serviço',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Proporção dos serviços mais requisitados pelos clientes',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _typeCounts.isEmpty
                  ? const SizedBox(
                      height: 120,
                      child: Center(child: Text('Ainda não há serviços registados.')),
                    )
                  : Column(
                      children: [
                        SizedBox(
                          height: 190,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 40,
                              sections: _generatePieSections(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            for (int i = 0; i < _typeCounts.length; i++)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: _colors[i % _colors.length],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_typeCounts.keys.elementAt(i)} (${_typeCounts.values.elementAt(i)})',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  double _calculateInterval() {
    final maxVal = _monthlyRevenue.values.fold<double>(100.0, (prev, curr) => curr > prev ? curr : prev);
    return maxVal / 4;
  }

  static const _colors = [
    Color(0xFF4CAF82),
    Color(0xFF1B3D2F),
    Colors.orange,
    Colors.blue,
    Colors.purple,
    Colors.teal,
    Colors.redAccent,
  ];

  List<PieChartSectionData> _generatePieSections() {
    final total = _typeCounts.values.fold<int>(0, (sum, v) => sum + v);
    final list = <PieChartSectionData>[];
    int i = 0;
    _typeCounts.forEach((type, count) {
      final pct = (count / total * 100).toStringAsFixed(0);
      list.add(
        PieChartSectionData(
          color: _colors[i % _colors.length],
          value: count.toDouble(),
          title: '$pct%',
          radius: 54,
          titleStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      i++;
    });
    return list;
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
