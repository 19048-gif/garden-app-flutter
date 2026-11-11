import '../main.dart';
import 'package:flutter/material.dart';

import '../db.dart';
import '../models.dart';
import '../services/launcher_service.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  List<Client> _all = [];
  String _query = '';
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

  Future<void> _load() async {
    final c = await AppDb.instance.clients();
    if (!mounted) return;
    setState(() {
      _all = c;
      _loading = false;
    });
  }

  Future<void> _open([Client? c]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ClientFormScreen(client: c)),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Client c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: Text('Eliminar ${c.name} e todos os seus serviços?'),
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
    if (ok == true) {
      await AppDb.instance.deleteClient(c.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final list = _all
        .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(),
        icon: const Icon(Icons.person_add),
        label: const Text('Novo cliente'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Pesquisar cliente por nome',
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: list.isEmpty
                      ? const Center(child: Text('Sem clientes registados.'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 90),
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final c = list[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: gardenGreen,
                                        foregroundColor: Colors.white,
                                        child: Text(c.name.isEmpty ? '?' : c.name[0].toUpperCase()),
                                      ),
                                      title: Text(c.name,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      subtitle: Text(
                                        [
                                          if (c.phone.isNotEmpty) '📞 ${c.phone}',
                                          if (c.address.isNotEmpty) '📍 ${c.address}'
                                        ].join('\n'),
                                      ),
                                      onTap: () => _open(c),
                                      trailing: IconButton(
                                        tooltip: 'Eliminar',
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                        onPressed: () => _delete(c),
                                      ),
                                    ),

                                    // Ficha Técnica do Jardim em Badges
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.grey.shade900 : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isDark ? Colors.grey.shade800 : Colors.green.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '🏡 Ficha Técnica do Jardim:',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: gardenForest),
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              _badge('🪴 Solo: ${c.soilType}'),
                                              _badge('☀️ Sol: ${c.sunExposure}'),
                                              _badge('💧 Rega: ${c.irrigationType}'),
                                              if (c.petsInfo.isNotEmpty) _badge('🐕 Animais: ${c.petsInfo}'),
                                              if (c.gardenArea > 0) _badge('📐 Área: ${c.gardenArea.toStringAsFixed(0)} m²'),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    const Divider(height: 12),

                                    // Notificações Automáticas e Ações
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        if (c.phone.isNotEmpty) ...[
                                          TextButton.icon(
                                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                                            onPressed: () => LauncherService.openWhatsApp(
                                              c.phone,
                                              'Olá ${c.name}, o jardineiro da GardenApp está a caminho do seu jardim! Chegada prevista em 15 minutos. 🚗💨',
                                            ),
                                            icon: const Icon(Icons.directions_car, size: 16, color: Colors.orange),
                                            label: const Text('A Caminho', style: TextStyle(color: Colors.orange, fontSize: 12)),
                                          ),
                                          TextButton.icon(
                                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                                            onPressed: () => LauncherService.openWhatsApp(
                                              c.phone,
                                              'Olá ${c.name}, o serviço de jardinagem no seu imóvel foi concluído com sucesso! ✅ Obrigado pela preferência.',
                                            ),
                                            icon: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                            label: const Text('Concluído', style: TextStyle(color: Colors.green, fontSize: 12)),
                                          ),
                                        ],
                                        if (c.address.isNotEmpty)
                                          IconButton(
                                            tooltip: 'Google Maps',
                                            icon: const Icon(Icons.map, size: 20, color: Colors.blue),
                                            onPressed: () => LauncherService.openAddressInMaps(c.address),
                                          ),
                                        IconButton(
                                          tooltip: 'Editar Ficha Técnica',
                                          icon: const Icon(Icons.edit_note, size: 22),
                                          onPressed: () => _open(c),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400, width: 0.8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}

class ClientFormScreen extends StatefulWidget {
  final Client? client;
  const ClientFormScreen({super.key, this.client});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.client?.name);
  late final _phone = TextEditingController(text: widget.client?.phone);
  late final _address = TextEditingController(text: widget.client?.address);
  late String _soilType = widget.client?.soilType ?? 'Argiloso';
  late String _sunExposure = widget.client?.sunExposure ?? 'Sol Direto (6h+)';
  late String _irrigationType = widget.client?.irrigationType ?? 'Gota-a-gota automático';
  late final _petsInfo = TextEditingController(text: widget.client?.petsInfo);
  late final _gardenArea = TextEditingController(
      text: widget.client?.gardenArea != null && widget.client!.gardenArea > 0
          ? widget.client!.gardenArea.toStringAsFixed(0)
          : '');

  final _soilTypes = ['Argiloso', 'Arenoso', 'Franco-limoso', 'Misto / Rochoso', 'Não especificado'];
  final _sunExposures = ['Sol Direto (6h+)', 'Meia-sombra', 'Sombra total', 'Não especificado'];
  final _irrigationTypes = ['Gota-a-gota automático', 'Aspersão pop-up', 'Manual / Mangueira', 'Sem rega'];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _petsInfo.dispose();
    _gardenArea.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final areaVal = double.tryParse(_gardenArea.text.replaceAll(',', '.')) ?? 0.0;

    await AppDb.instance.saveClient(Client(
      id: widget.client?.id,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      soilType: _soilType,
      sunExposure: _sunExposure,
      irrigationType: _irrigationType,
      petsInfo: _petsInfo.text.trim(),
      gardenArea: areaVal,
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.client == null ? 'Novo cliente' : 'Editar cliente')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Dados do Cliente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome completo'),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Indique o nome' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(
                labelText: 'Contacto Telefónico',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'Morada / Local do Jardim',
                prefixIcon: Icon(Icons.location_on),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text('🏡 Ficha Técnica do Jardim', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _soilType,
              decoration: const InputDecoration(labelText: 'Tipo de Solo'),
              items: [for (final s in _soilTypes) DropdownMenuItem(value: s, child: Text(s))],
              onChanged: (v) => setState(() => _soilType = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _sunExposure,
              decoration: const InputDecoration(labelText: 'Exposição Solar'),
              items: [for (final s in _sunExposures) DropdownMenuItem(value: s, child: Text(s))],
              onChanged: (v) => setState(() => _sunExposure = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _irrigationType,
              decoration: const InputDecoration(labelText: 'Sistema de Rega'),
              items: [for (final i in _irrigationTypes) DropdownMenuItem(value: i, child: Text(i))],
              onChanged: (v) => setState(() => _irrigationType = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _petsInfo,
              decoration: const InputDecoration(
                labelText: 'Animais de Estimação (Ex: Cão de guarda, Gato)',
                prefixIcon: Icon(Icons.pets),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gardenArea,
              decoration: const InputDecoration(
                labelText: 'Área do Jardim (m²)',
                prefixIcon: Icon(Icons.square_foot),
                suffixText: 'm²',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: gardenGreen),
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Guardar Cliente & Ficha Técnica'),
            ),
          ],
        ),
      ),
    );
  }
}
