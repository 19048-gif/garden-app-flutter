import 'package:flutter/material.dart';

import '../main.dart';

class CalculatorsScreen extends StatefulWidget {
  const CalculatorsScreen({super.key});

  @override
  State<CalculatorsScreen> createState() => _CalculatorsScreenState();
}

class _CalculatorsScreenState extends State<CalculatorsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Calculadora 1: Relva
  final _lawnAreaCtrl = TextEditingController(text: '100');

  // Calculadora 2: Substrato / Volume
  final _lengthCtrl = TextEditingController(text: '10');
  final _widthCtrl = TextEditingController(text: '2');
  final _depthCtrl = TextEditingController(text: '5'); // cm

  // Calculadora 3: Diluição
  final _tankCapacityCtrl = TextEditingController(text: '15'); // Litros
  final _dosageCtrl = TextEditingController(text: '5'); // mL por Litro de água

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lawnAreaCtrl.dispose();
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _depthCtrl.dispose();
    _tankCapacityCtrl.dispose();
    _dosageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadoras de Campo'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: gardenGreen,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.grass), text: 'Relva / Semente'),
            Tab(icon: Icon(Icons.layers), text: 'Volume / Mulch'),
            Tab(icon: Icon(Icons.science), text: 'Diluição / Adubo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLawnCalculator(),
          _buildVolumeCalculator(),
          _buildDilutionCalculator(),
        ],
      ),
    );
  }

  // --- TAB 1: CALCULADORA DE RELVA ---
  Widget _buildLawnCalculator() {
    final area = double.tryParse(_lawnAreaCtrl.text.replaceAll(',', '.')) ?? 0.0;

    // Semente: ~35g a 40g por m² (média 37.5g)
    final seedGrams = area * 37.5;
    final seedKg = seedGrams / 1000.0;
    final bags1kg = seedKg.ceil();
    final bags5kg = (seedKg / 5.0).ceil();

    // Relva em rolo: Área + 5% margem de recorte. Rolo padrão = 0.8 m²
    final areaWithMargin = area * 1.05;
    final rollCount = (areaWithMargin / 0.8).ceil();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🌱 Cálculo de Relva em Rolo / Semente',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lawnAreaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Área do Terreno (m²)',
                    prefixIcon: Icon(Icons.straighten),
                    suffixText: 'm²',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Resultados
        Row(
          children: [
            Expanded(
              child: _resultCard(
                title: '🌾 Semente de Relva',
                value: '${seedKg.toStringAsFixed(1)} kg',
                subtitle: 'Dose: 35g-40g/m²\n📦 ~$bags1kg saco(s) de 1kg\n📦 ou ~$bags5kg saco(s) de 5kg',
                color: gardenForest,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _resultCard(
                title: '🟩 Relva em Rolo',
                value: '$rollCount rolos',
                subtitle: 'Área + 5% margem: ${areaWithMargin.toStringAsFixed(1)} m²\n📐 Rolo padrão: 0.8 m²',
                color: gardenGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- TAB 2: CALCULADORA DE VOLUME (MULCH / SUBSTRATO / BRITA) ---
  Widget _buildVolumeCalculator() {
    final length = double.tryParse(_lengthCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final width = double.tryParse(_widthCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final depthCm = double.tryParse(_depthCtrl.text.replaceAll(',', '.')) ?? 0.0;

    final area = length * width;
    final depthMeters = depthCm / 100.0;
    final volumeM3 = area * depthMeters; // m³
    final volumeLiters = volumeM3 * 1000.0; // Litros

    // Sacos recomendados
    final substrateBags50L = (volumeLiters / 50.0).ceil();
    final mulchBags70L = (volumeLiters / 70.0).ceil();
    final gravelTons = volumeM3 * 1.5; // Densidade média da brita = 1.5 t/m³
    final gravelBags25kg = (gravelTons * 1000 / 25.0).ceil();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📦 Cálculo de Volume de Terra, Mulch & Brita',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _lengthCtrl,
                        decoration: const InputDecoration(labelText: 'Comprimento (m)', suffixText: 'm'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _widthCtrl,
                        decoration: const InputDecoration(labelText: 'Largura (m)', suffixText: 'm'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _depthCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Profundidade da Camada (cm)',
                    hintText: 'Ex: 5 cm para mulch ou 10 cm para terra',
                    suffixText: 'cm',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Resultado do Volume
        _resultCard(
          title: '📐 Volume Total Necessário',
          value: '${volumeLiters.toStringAsFixed(0)} Litros (${volumeM3.toStringAsFixed(2)} m³)',
          subtitle: 'Área calculada: ${area.toStringAsFixed(1)} m² com ${depthCm.toStringAsFixed(0)} cm de espessura.',
          color: Colors.blue.shade800,
        ),

        const SizedBox(height: 12),

        // Recomendações de Sacos a Comprar
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🛒 Guia de Compra de Sacos / Material:',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Text('🪵', style: TextStyle(fontSize: 24)),
                  title: const Text('Casca de Pinho / Mulch'),
                  subtitle: Text('$mulchBags70L sacos de 70 Litros'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Text('🪴', style: TextStyle(fontSize: 24)),
                  title: const Text('Substrato / Terra Vegetal'),
                  subtitle: Text('$substrateBags50L sacos de 50 Litros'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Text('🪨', style: TextStyle(fontSize: 24)),
                  title: const Text('Brita / Gravilha Decorativa'),
                  subtitle: Text('${gravelTons.toStringAsFixed(2)} toneladas (~$gravelBags25kg sacos de 25kg)'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- TAB 3: CALCULADORA DE DILUIÇÃO E ADUBAÇÃO ---
  Widget _buildDilutionCalculator() {
    final tankLiters = double.tryParse(_tankCapacityCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final dosagePerLiter = double.tryParse(_dosageCtrl.text.replaceAll(',', '.')) ?? 0.0;

    final totalProductNeeded = tankLiters * dosagePerLiter; // mL ou gramas
    final estimatedCoverageM2 = tankLiters * 10; // Média: 1L de calda cobre ~10m²

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🧪 Calculadora de Diluição de Fertilizante / Fitossanitário',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tankCapacityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Capacidade do Pulverizador / Depósito (Litros)',
                    prefixIcon: Icon(Icons.water_drop),
                    suffixText: 'L',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dosageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dose Recomendada na Embalagem (mL ou g por Litro)',
                    hintText: 'Ex: 5 mL/L de Sabão de Potássio ou Óleo de Neem',
                    suffixText: 'mL/L ou g/L',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Resultado da Diluição
        Row(
          children: [
            Expanded(
              child: _resultCard(
                title: '🧪 Dose do Produto',
                value: '${totalProductNeeded.toStringAsFixed(1)} mL (ou g)',
                subtitle: 'Quantidade de produto concentrado a misturar em $tankLiters Litros de água.',
                color: Colors.teal.shade800,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _resultCard(
                title: '📐 Área Coberta',
                value: '~${estimatedCoverageM2.toStringAsFixed(0)} m²',
                subtitle: 'Área aproximada de plantas tratadas com $tankLiters Litros de mistura.',
                color: gardenForest,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _resultCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.3)),
          ],
        ),
      ),
    );
  }
}
