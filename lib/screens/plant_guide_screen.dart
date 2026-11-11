import 'package:flutter/material.dart';

import '../db.dart';
import '../main.dart';
import '../models.dart';
import '../services/launcher_service.dart';
import 'service_form_screen.dart';

class PlantGuideScreen extends StatefulWidget {
  final Session? session;
  const PlantGuideScreen({super.key, this.session});

  @override
  State<PlantGuideScreen> createState() => _PlantGuideScreenState();
}

class _PlantGuideScreenState extends State<PlantGuideScreen> {
  String _query = '';
  String _selectedCategory = 'Todos';

  final _categories = ['Todos', 'Flores', 'Árvores', 'Plantas', 'Serviços'];

  Future<void> _sharePlantWhatsApp(BuildContext context, PlantTip item) async {
    final clients = await AppDb.instance.clients();
    if (!context.mounted) return;

    final message = '''
🌱 *Ficha Técnica de Jardinagem - GardenApp*

- *${item.name}* (${item.category})
💰 *Valor Estimado:* ${item.priceRange}
☀️ *Exposição Solar:* ${item.sunExposure}
🪴 *Solo Ideal:* ${item.idealSoil}
💧 *Rega / Cuidados:* ${item.watering}
✂️ *Época de Poda:* ${item.pruningSeason}
🧪 *Adubo Recomendado:* ${item.recommendedFertilizer}

💡 *Dica / Solução:*
${item.solutions}
''';

    if (clients.isEmpty) {
      await LauncherService.openWhatsApp('', message);
    } else {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Partilhar Ficha no WhatsApp',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.chat, color: Colors.green),
                title: const Text('Partilhar Geral (Escolher contacto no WhatsApp)'),
                onTap: () {
                  Navigator.pop(ctx);
                  LauncherService.openWhatsApp('', message);
                },
              ),
              for (final c in clients.where((c) => c.phone.isNotEmpty))
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: gardenGreen,
                    child: Text(c.name.isEmpty ? '?' : c.name[0].toUpperCase()),
                  ),
                  title: Text(c.name),
                  subtitle: Text(c.phone),
                  onTap: () {
                    Navigator.pop(ctx);
                    LauncherService.openWhatsApp(c.phone, message);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = plantGuideCatalog.where((item) {
      final matchesCat = _selectedCategory == 'Todos' || item.category == _selectedCategory;
      final matchesQuery = item.name.toLowerCase().contains(_query.toLowerCase()) ||
          item.description.toLowerCase().contains(_query.toLowerCase()) ||
          item.solutions.toLowerCase().contains(_query.toLowerCase());
      return matchesCat && matchesQuery;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Campo de pesquisa
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Pesquisar plantas, soluções, serviços ou pragas...',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          // Chips de Filtro por Categoria
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: gardenGreen,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (sel) {
                    if (sel) setState(() => _selectedCategory = cat);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Lista de Plantas e Serviços
          Expanded(
            child: filtered.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nenhum resultado encontrado para a sua pesquisa.'),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 24, left: 12, right: 12, top: 4),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _buildItemCard(filtered[i], isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(PlantTip item, bool isDark) {
    final isService = item.category == 'Serviços';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlantDetailScreen(
                item: item,
                session: widget.session,
                onShareWhatsApp: (context, item) => _sharePlantWhatsApp(context, item),
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: gardenForest,
                      height: 180,
                      child: const Center(
                        child: Icon(Icons.yard, size: 64, color: Colors.white54),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isService ? Colors.orange.shade800 : gardenForest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.all(8),
                        ),
                        tooltip: 'Partilhar no WhatsApp',
                        icon: const Icon(Icons.share, color: Colors.white, size: 18),
                        onPressed: () => _sharePlantWhatsApp(context, item),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.priceRange,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: const TextStyle(fontSize: 14, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  _detailRow(Icons.water_drop, 'Rega / Cuidados', item.watering),
                  const SizedBox(height: 6),
                  _detailRow(Icons.event, 'Época / Frequência', item.pruningSeason),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.green.shade900.withOpacity(0.4)
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.green.shade700 : Colors.green.shade300,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb,
                          color: isDark ? Colors.amberAccent : gardenForest,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.solutions,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : gardenForest,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isService) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: gardenForest,
                          side: const BorderSide(color: gardenForest, width: 1.5),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ServiceFormScreen(
                                initialDate: DateTime.now(),
                                service: Service(
                                  clientId: widget.session?.clientId ?? 0,
                                  date: DateTime.now().add(const Duration(days: 1)),
                                  type: item.name.contains('Corte')
                                      ? 'Corte de relva'
                                      : item.name.contains('Poda')
                                      ? 'Poda'
                                      : item.name.contains('Rega')
                                      ? 'Rega / Sistema de rega'
                                      : item.name.contains('Plantação')
                                      ? 'Plantação'
                                      : 'Outro',
                                  notes: 'Solicitado via Catálogo: ${item.name} (${item.priceRange})',
                                ),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_task),
                        label: const Text('Agendar este Serviço'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String text) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: textColor, fontSize: 13),
              children: [
                TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PlantDetailScreen extends StatelessWidget {
  final PlantTip item;
  final Session? session;
  final Function(BuildContext, PlantTip) onShareWhatsApp;

  const PlantDetailScreen({
    super.key,
    required this.item,
    this.session,
    required this.onShareWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isService = item.category == 'Serviços';

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            tooltip: 'Partilhar no WhatsApp',
            icon: const Icon(Icons.share, color: Colors.greenAccent),
            onPressed: () => onShareWhatsApp(context, item),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: gardenForest,
                      height: 220,
                      child: const Center(
                        child: Icon(Icons.yard, size: 72, color: Colors.white54),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isService ? Colors.orange.shade800 : gardenForest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.priceRange,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            item.description,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Ficha Técnica & Necessidades',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 20),
                  _specRow(context, Icons.wb_sunny, 'Exposição Solar', item.sunExposure),
                  const SizedBox(height: 10),
                  _specRow(context, Icons.grass, 'Solo Ideal', item.idealSoil),
                  const SizedBox(height: 10),
                  _specRow(context, Icons.water_drop, 'Rega & Cuidados', item.watering),
                  const SizedBox(height: 10),
                  _specRow(context, Icons.event, 'Época de Poda', item.pruningSeason),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (item.pruningSteps.isNotEmpty) ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.content_cut, color: gardenForest),
                        SizedBox(width: 8),
                        Text(
                          '✂️ Dicas de Poda Passo a Passo',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    for (final step in item.pruningSteps) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          step,
                          style: const TextStyle(fontSize: 14, height: 1.3, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            elevation: 2,
            color: isDark ? Colors.teal.shade900.withOpacity(0.3) : Colors.teal.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.teal.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.science, color: Colors.teal),
                      SizedBox(width: 8),
                      Text(
                        '🧪 Adubo & Nutrição Recomendada',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.recommendedFertilizer,
                    style: const TextStyle(fontSize: 14, height: 1.3, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.green.shade900.withOpacity(0.4) : Colors.green.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.green.shade700 : Colors.green.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: isDark ? Colors.amberAccent : gardenForest),
                    const SizedBox(width: 8),
                    Text(
                      '💡 Solução & Prevenção de Pragas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.green.shade100 : gardenForest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.solutions,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade800,
                    side: BorderSide(color: Colors.green.shade800, width: 1.5),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => onShareWhatsApp(context, item),
                  icon: const Icon(Icons.chat),
                  label: const Text('Partilhar no WhatsApp'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: gardenForest,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceFormScreen(
                          initialDate: DateTime.now(),
                          service: Service(
                            clientId: session?.clientId ?? 0,
                            date: DateTime.now().add(const Duration(days: 1)),
                            type: item.name.contains('Corte')
                                ? 'Corte de relva'
                                : item.name.contains('Poda')
                                ? 'Poda'
                                : item.name.contains('Rega')
                                ? 'Rega / Sistema de rega'
                                : item.name.contains('Plantação')
                                ? 'Plantação'
                                : 'Outro',
                            notes: 'Solicitado via Ficha Técnica: ${item.name} (${item.priceRange})',
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Agendar Trabalho'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _specRow(BuildContext context, IconData icon, String label, String value) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: gardenGreen),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: textColor),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}