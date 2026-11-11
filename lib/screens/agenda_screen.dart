import 'dart:io';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../db.dart';
import '../main.dart';
import '../models.dart';
import '../services/pdf_service.dart';
import '../services/weather_service.dart';
import 'service_form_screen.dart';

class AgendaScreen extends StatefulWidget {
  final Session session;
  const AgendaScreen({super.key, required this.session});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  Map<String, List<Service>> _byDay = {};
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();
  String _statusFilter = 'Todos';
  bool _loading = true;
  WeatherInfo? _weather;

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
    final all = await AppDb.instance.services(
      clientId: widget.session.isGardener ? null : widget.session.clientId,
    );
    final map = <String, List<Service>>{};
    for (final s in all) {
      map.putIfAbsent(dayKey(s.date), () => []).add(s);
    }

    final weather = await WeatherService.getWeatherForDate(_selected);

    if (!mounted) return;
    setState(() {
      _byDay = map;
      _weather = weather;
      _loading = false;
    });
  }

  List<Service> _eventsFor(DateTime d) => _byDay[dayKey(d)] ?? [];

  Future<void> _edit([Service? s]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceFormScreen(service: s, initialDate: _selected),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _toggle(Service s, bool? v) async {
    await AppDb.instance.setDone(s.id!, v ?? false);
    _load();
  }

  Future<void> _delete(Service s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar serviço'),
        content: Text('Eliminar "${s.type}" de ${s.clientName}?'),
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
      await AppDb.instance.deleteService(s.id!);
      _load();
    }
  }

  Future<void> _exportPdf(Service s) async {
    final clients = await AppDb.instance.clients();
    final client = clients.firstWhere(
      (c) => c.id == s.clientId,
      orElse: () => Client(id: s.clientId, name: s.clientName),
    );
    await PdfService.generateAndShareReceipt(service: s, client: client, context: context);
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.session.isGardener;
    final events = _eventsFor(_selected);

    final pendingCount = events.where((e) => !e.done).length;
    final doneCount = events.where((e) => e.done).length;

    final filteredEvents = events.where((s) {
      if (_statusFilter == 'Pendentes') return !s.done;
      if (_statusFilter == 'Concluídos') return s.done;
      return true;
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isRainyOrSevere = false;
    if (_weather != null) {
      final desc = _weather!.description.toLowerCase();
      isRainyOrSevere = desc.contains('chuva') ||
          desc.contains('aguaceiro') ||
          desc.contains('trovoada') ||
          desc.contains('nevoeiro');
    }

    final String emptyMsg = events.isEmpty
        ? 'Sem serviços a ${fmtDate(_selected)}.'
        : 'Nenhum serviço ${_statusFilter.toLowerCase()} a ${fmtDate(_selected)}.';

    return Scaffold(
      floatingActionButton: g
          ? FloatingActionButton.extended(
              onPressed: () => _edit(),
              icon: const Icon(Icons.add),
              label: const Text('Novo serviço'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar<Service>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  focusedDay: _focused,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {CalendarFormat.month: 'Mês'},
                  selectedDayPredicate: (d) => isSameDay(d, _selected),
                  eventLoader: _eventsFor,
                  onDaySelected: (sel, foc) {
                    setState(() {
                      _selected = sel;
                      _focused = foc;
                    });
                    _load();
                  },
                  onPageChanged: (foc) => _focused = foc,
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextFormatter: (date, _) => ptMonth(date),
                  ),
                  calendarStyle: const CalendarStyle(
                    selectedDecoration:
                        BoxDecoration(color: gardenGreen, shape: BoxShape.circle),
                    todayDecoration:
                        BoxDecoration(color: gardenForest, shape: BoxShape.circle),
                    markerDecoration:
                        BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                  ),
                ),

                // Card Interativo de Meteorologia com Alerta
                if (_weather != null) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isRainyOrSevere
                          ? (isDark ? Colors.amber.shade900.withValues(alpha: 0.35) : Colors.amber.shade100)
                          : (isDark ? Colors.blueGrey.shade900 : Colors.blue.shade50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isRainyOrSevere
                            ? Colors.orange.shade700
                            : (isDark ? Colors.blueGrey.shade700 : Colors.blue.shade300),
                        width: isRainyOrSevere ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_weather!.icon, style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Previsão: ${_weather!.description}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      if (isRainyOrSevere)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade800,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            '⚠️ ALERTA',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    'Temperatura: ${_weather!.tempMin.round()}°C a ${_weather!.tempMax.round()}°C',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isRainyOrSevere) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.white70,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: Colors.deepOrange),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'Aviso: Chuva prevista! Recomendado remarcar cortes de relva e tratamentos de exterior.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 6),

                // Filtros Rápido por Estado (Todos / Pendentes / Concluídos)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _statusFilterChip(
                          label: 'Todos (${events.length})',
                          isSelected: _statusFilter == 'Todos',
                          color: gardenForest,
                          onTap: () => setState(() => _statusFilter = 'Todos'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _statusFilterChip(
                          label: 'Pendentes ($pendingCount)',
                          isSelected: _statusFilter == 'Pendentes',
                          color: Colors.orange.shade800,
                          onTap: () => setState(() => _statusFilter = 'Pendentes'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _statusFilterChip(
                          label: 'Concluídos ($doneCount)',
                          isSelected: _statusFilter == 'Concluídos',
                          color: gardenGreen,
                          onTap: () => setState(() => _statusFilter = 'Concluídos'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),
                const Divider(height: 1),

                Expanded(
                  child: filteredEvents.isEmpty
                      ? Center(
                          child: Text(emptyMsg),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 90, top: 8),
                          itemCount: filteredEvents.length,
                          itemBuilder: (_, i) => _tile(filteredEvents[i], g),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _statusFilterChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _tile(Service s, bool g) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: s.photoPath != null && File(s.photoPath!).existsSync()
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(s.photoPath!), width: 56, height: 56, fit: BoxFit.cover),
                )
              : CircleAvatar(
                  radius: 28,
                  backgroundColor: s.done ? gardenGreen : Colors.orange.shade200,
                  child: Icon(s.done ? Icons.check : Icons.schedule, color: Colors.black87),
                ),
          title: Text('${fmtTime(s.date)} · ${s.type}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${s.clientName} • ${s.done ? "Concluído ✅" : "Pendente ⏳"}'),
              if (s.price > 0)
                Text('Valor: ${fmtCurrency(s.price)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: gardenForest)),
              if (s.notes.isNotEmpty) Text(s.notes, style: const TextStyle(fontSize: 12)),
            ],
          ),
          onTap: g ? () => _edit(s) : null,
          onLongPress: g ? () => _delete(s) : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Comprovativo PDF',
                icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                onPressed: () => _exportPdf(s),
              ),
              if (g)
                Checkbox(
                  value: s.done,
                  onChanged: (v) => _toggle(s, v),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
