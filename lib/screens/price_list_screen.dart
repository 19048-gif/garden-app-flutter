import 'package:flutter/material.dart';

import '../main.dart';
import '../models.dart';
import '../services/pdf_service.dart';
import 'service_form_screen.dart';

class PriceListScreen extends StatefulWidget {
  final Session session;
  const PriceListScreen({super.key, required this.session});

  @override
  State<PriceListScreen> createState() => _PriceListScreenState();
}

class _PriceListScreenState extends State<PriceListScreen> {
  String _selectedCategory = 'Todos';
  String _searchQuery = '';

  final _categories = [
    'Todos',
    'Manutenção',
    'Poda',
    'Sistemas de Rega',
    'Limpeza',
    'Plantação',
    'Saúde Vegetal',
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = priceTableCatalog.where((item) {
      final matchesCat = _selectedCategory == 'Todos' || item.category == _selectedCategory;
      final matchesQuery = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.solution.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesQuery;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Campo de Pesquisa
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Pesquisar serviço, solução ou preço...',
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Imprimir / Fotocópia da Tabela (PDF)',
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                  onPressed: () => PdfService.generateAndPrintPriceList(context),
                ),
              ],
            ),
          ),

          // Filtro de Categorias em Scroll Horizontal
          SizedBox(
            height: 40,
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

          // Lista de Serviços, Preços & Soluções Encontradas
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Nenhum serviço encontrado nesta categoria.'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24, left: 12, right: 12),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _buildPriceCard(filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(PriceItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto Real Unsplash
          Stack(
            children: [
              SizedBox(
                height: 170,
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
                    child: const Icon(Icons.yard, size: 64, color: Colors.white54),
                  ),
                ),
              ),

              // Badge Categoria
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: gardenForest,
                    borderRadius: BorderRadius.circular(16),
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

              // Destaque de Preço
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: gardenGreen,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    '${item.price} (${item.unit})',
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

          // Detalhes do Serviço & Solução
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 14, height: 1.3),
                ),
                const SizedBox(height: 12),

                // Caixa com Solução Encontrada
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.green.shade900.withValues(alpha: 0.4)
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
                          item.solution,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : gardenForest,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Botão de Agendamento
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: gardenForest,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: () {
                      final parsedPrice = double.tryParse(
                            item.price.replaceAll('€', '').replaceAll(',', '.').trim(),
                          ) ??
                          0.0;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ServiceFormScreen(
                            initialDate: DateTime.now(),
                            service: Service(
                              clientId: widget.session.clientId ?? 0,
                              date: DateTime.now().add(const Duration(days: 1)),
                              type: item.title.contains('Corte')
                                  ? 'Corte de relva'
                                  : item.title.contains('Poda')
                                      ? 'Poda'
                                      : item.title.contains('Rega')
                                          ? 'Rega / Sistema de rega'
                                          : item.title.contains('Limpeza')
                                              ? 'Limpeza de jardim'
                                              : 'Outro',
                              price: parsedPrice,
                              notes: 'Pedido via Tabela de Preços: ${item.title} (${item.price} ${item.unit})',
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: const Text('Pedir Agendamento / Orçamento'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
