import '../main.dart';
import 'package:flutter/material.dart';

import '../db.dart';
import '../models.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Equipment> _items = [];
  bool _loading = true;

  // Lista da Checklist Pré-Saída
  final List<Map<String, dynamic>> _checklist = [
    {'title': '⛽ Combustível de Mistura 2T / Gasóleo', 'category': 'Consumíveis', 'checked': true},
    {'title': '🧶 Fio de Corte para Roçadora (2.4mm / 3.0mm)', 'category': 'Consumíveis', 'checked': true},
    {'title': '🗑️ Sacos de Entulho Verde (200 Litros)', 'category': 'Consumíveis', 'checked': false},
    {'title': '🌱 Sementes de Relva & Adubo Granulado', 'category': 'Consumíveis', 'checked': true},
    {'title': '🧴 Sabão de Potássio / Tratamento Fitossanitário', 'category': 'Produtos', 'checked': false},
    {'title': '🧤 EPI (Óculos, Luvas, Protetores Auriculares)', 'category': 'Segurança', 'checked': true},
    {'title': '🔧 Caixa de Ferramentas & Chaves de Bujão', 'category': 'Ferramentas', 'checked': true},
    {'title': '⚡ Baterias Carregadas & Carregador Portátil', 'category': 'Máquinas', 'checked': true},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    AppDb.instance.addListener(_onDbUpdated);
    _load();
  }

  void _onDbUpdated() {
    if (mounted) _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    AppDb.instance.removeListener(_onDbUpdated);
    super.dispose();
  }

  Future<void> _load() async {
    await AppDb.instance.seedSampleData();
    final list = await AppDb.instance.equipments();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _openEquipmentForm([Equipment? e]) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EquipmentFormSheet(
        equipment: e,
        onSave: (eq) async {
          await AppDb.instance.saveEquipment(eq);
          if (ctx.mounted) Navigator.pop(ctx);
          _load();
        },
      ),
    );
  }

  Future<void> _deleteEquipment(Equipment e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Equipamento'),
        content: Text('Deseja eliminar "${e.name}" da lista?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true && e.id != null) {
      await AppDb.instance.deleteEquipment(e.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final operationalCount = _items.where((e) => e.status == 'Operacional').length;
    final needsReviewCount = _items.where((e) => e.status == 'Necessita Revisão').length;
    final brokenCount = _items.where((e) => e.status == 'Avariado').length;

    final checkedCount = _checklist.where((c) => c['checked'] == true).length;
    final checklistProgress = checkedCount / _checklist.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipamento & Carrinha'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: gardenGreen,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              icon: const Icon(Icons.build),
              text: 'Máquinas (${_items.length})',
            ),
            Tab(
              icon: const Icon(Icons.fact_check),
              text: 'Checklist Carrinha ($checkedCount/${_checklist.length})',
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _openEquipmentForm(),
              icon: const Icon(Icons.add),
              label: const Text('Nova Máquina'),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // Separador 1: Gestão de Máquinas & Ferramentas
          RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Resumo de Estado
                Row(
                  children: [
                    Expanded(
                      child: _statusSummaryCard(
                        title: 'Operacional',
                        count: operationalCount,
                        color: Colors.green,
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statusSummaryCard(
                        title: 'Revisão',
                        count: needsReviewCount,
                        color: Colors.orange,
                        icon: Icons.warning_amber_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statusSummaryCard(
                        title: 'Avariado',
                        count: brokenCount,
                        color: Colors.red,
                        icon: Icons.build_circle_outlined,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (needsReviewCount > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade700),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.deepOrange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Aviso: $needsReviewCount máquina(s) necessita(m) de revisão/afiação antes do próximo serviço!',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_items.isEmpty)
                  const Center(child: Text('Sem equipamentos registados.'))
                else
                  for (final eq in _items) _equipmentCard(eq),
              ],
            ),
          ),

          // Separador 2: Checklist Pré-Saída da Carrinha
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Checklist de Carga da Carrinha',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            tooltip: 'Reiniciar Lista Diária',
                            icon: const Icon(Icons.restart_alt, color: gardenForest),
                            onPressed: () {
                              setState(() {
                                for (final item in _checklist) {
                                  item['checked'] = false;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: checklistProgress,
                        backgroundColor: Colors.grey.shade300,
                        color: checklistProgress == 1.0 ? Colors.green : gardenGreen,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        checklistProgress == 1.0
                            ? '✅ Tudo pronto! Pode sair para o dia de trabalho.'
                            : '$checkedCount de ${_checklist.length} itens verificados (${(checklistProgress * 100).round()}%).',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: checklistProgress == 1.0 ? Colors.green : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < _checklist.length; i++)
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: CheckboxListTile(
                    activeColor: gardenGreen,
                    title: Text(
                      _checklist[i]['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: _checklist[i]['checked'] ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(_checklist[i]['category'], style: const TextStyle(fontSize: 12)),
                    value: _checklist[i]['checked'],
                    onChanged: (v) {
                      setState(() {
                        _checklist[i]['checked'] = v ?? false;
                      });
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusSummaryCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _equipmentCard(Equipment e) {
    Color statusColor = Colors.green;
    if (e.status == 'Necessita Revisão') statusColor = Colors.orange;
    if (e.status == 'Avariado') statusColor = Colors.red;

    IconData powerIcon = Icons.local_gas_station;
    if (e.powerType == 'Bateria / Elétrico') powerIcon = Icons.battery_charging_full;
    if (e.powerType == 'Manual') powerIcon = Icons.build;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.2),
          child: Icon(powerIcon, color: statusColor, size: 22),
        ),
        title: Text(e.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${e.category} • ${e.powerType}'),
            if (e.nextMaintenance != null)
              Text(
                'Próxima Revisão: ${fmtDate(e.nextMaintenance!)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: e.nextMaintenance!.isBefore(DateTime.now()) ? Colors.red : Colors.grey.shade700,
                ),
              ),
            if (e.notes.isNotEmpty) Text('Notas: ${e.notes}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                e.status,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_note, size: 22),
              onPressed: () => _openEquipmentForm(e),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
              onPressed: () => _deleteEquipment(e),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentFormSheet extends StatefulWidget {
  final Equipment? equipment;
  final Function(Equipment) onSave;

  const _EquipmentFormSheet({this.equipment, required this.onSave});

  @override
  State<_EquipmentFormSheet> createState() => _EquipmentFormSheetState();
}

class _EquipmentFormSheetState extends State<_EquipmentFormSheet> {
  late final TextEditingController _name;
  late String _category;
  late String _powerType;
  late String _status;
  late final TextEditingController _notes;
  DateTime? _nextMaintenance;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.equipment?.name);
    _category = widget.equipment?.category ?? 'Corta-relvas';
    _powerType = widget.equipment?.powerType ?? 'Combustível';
    _status = widget.equipment?.status ?? 'Operacional';
    _notes = TextEditingController(text: widget.equipment?.notes);
    _nextMaintenance = widget.equipment?.nextMaintenance ?? DateTime.now().add(const Duration(days: 60));
  }

  final _categories = ['Corta-relvas', 'Moto-roçadora', 'Soprador', 'Corta-sebes', 'Motosserra', 'Outro'];
  final _powerTypes = ['Combustível', 'Bateria / Elétrico', 'Manual'];
  final _statuses = ['Operacional', 'Necessita Revisão', 'Avariado'];

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.equipment == null ? 'Nova Máquina / Ferramenta' : 'Editar Equipamento',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nome do Equipamento / Modelo'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Categoria'),
            items: [for (final c in _categories) DropdownMenuItem(value: c, child: Text(c))],
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _powerType,
            decoration: const InputDecoration(labelText: 'Tipo de Alimentação'),
            items: [for (final p in _powerTypes) DropdownMenuItem(value: p, child: Text(p))],
            onChanged: (v) => setState(() => _powerType = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Estado Operacional'),
            items: [for (final s in _statuses) DropdownMenuItem(value: s, child: Text(s))],
            onChanged: (v) => setState(() => _status = v!),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Próxima Revisão / Manutenção'),
            subtitle: Text(_nextMaintenance != null ? fmtDate(_nextMaintenance!) : 'Não definida'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _nextMaintenance ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (d != null) setState(() => _nextMaintenance = d);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Notas (Ex: Troca de óleo, lâmina afiada)'),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: gardenGreen, minimumSize: const Size.fromHeight(48)),
            onPressed: () {
              if (_name.text.trim().isEmpty) return;
              widget.onSave(Equipment(
                id: widget.equipment?.id,
                name: _name.text.trim(),
                category: _category,
                powerType: _powerType,
                status: _status,
                lastMaintenance: widget.equipment?.lastMaintenance ?? DateTime.now(),
                nextMaintenance: _nextMaintenance,
                notes: _notes.text.trim(),
              ));
            },
            icon: const Icon(Icons.save),
            label: const Text('Guardar Equipamento'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
