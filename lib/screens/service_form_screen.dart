import '../main.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db.dart';
import '../models.dart';
import '../services/launcher_service.dart';

class ServiceFormScreen extends StatefulWidget {
  final Service? service;
  final DateTime initialDate;
  const ServiceFormScreen({super.key, this.service, required this.initialDate});

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  List<Client> _clients = [];
  int? _clientId;
  late DateTime _date;
  late String _type;
  late final _notes = TextEditingController(text: widget.service?.notes);
  late final _price = TextEditingController(
      text: widget.service?.price != null && widget.service!.price > 0
          ? widget.service!.price.toStringAsFixed(2)
          : '');
  late final _expenses = TextEditingController(
      text: widget.service?.expenses != null && widget.service!.expenses > 0
          ? widget.service!.expenses.toStringAsFixed(2)
          : '');
  late final _duration = TextEditingController(
      text: widget.service?.durationMinutes != null && widget.service!.durationMinutes > 0
          ? widget.service!.durationMinutes.toString()
          : '0');
  late final _diagnosticNotes = TextEditingController(text: widget.service?.diagnosticNotes);

  bool _done = false;
  String? _photoBefore;
  String? _photoAfter;
  String? _photoDiagnostic;

  // Cronómetro de Tempo de Serviço
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _date = s?.date ??
        DateTime(widget.initialDate.year, widget.initialDate.month,
            widget.initialDate.day, 9, 0);
    _type = s?.type ?? serviceTypes.first;
    _clientId = s?.clientId;
    _done = s?.done ?? false;
    _photoBefore = s?.photoBeforePath;
    _photoAfter = s?.photoAfterPath ?? (s?.photoBeforePath == null ? s?.photoPath : null);
    _photoDiagnostic = s?.diagnosticPhotoPath;

    AppDb.instance.clients().then((c) {
      if (mounted) {
        setState(() {
          _clients = c;
          if (_clientId == null || !_clients.any((client) => client.id == _clientId)) {
            _clientId = _clients.isNotEmpty ? _clients.first.id : null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notes.dispose();
    _price.dispose();
    _expenses.dispose();
    _duration.dispose();
    _diagnosticNotes.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    setState(() {
      if (_isTimerRunning) {
        _stopwatch.stop();
        _timer?.cancel();
        _isTimerRunning = false;
        final elapsedMins = (_stopwatch.elapsedMilliseconds / 60000.0).round();
        if (elapsedMins > 0) {
          _duration.text = '$elapsedMins';
        }
      } else {
        _stopwatch.start();
        _isTimerRunning = true;
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) {
            setState(() {
              final elapsedMins = (_stopwatch.elapsedMilliseconds / 60000.0).round();
              _duration.text = '$elapsedMins';
            });
          }
        });
      }
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _date.hour, minute: _date.minute),
    );
    if (t != null) {
      setState(() => _date = DateTime(_date.year, _date.month, _date.day, t.hour, t.minute));
    }
  }

  Future<void> _pickPhoto(int type, ImageSource source) async {
    // type: 0 = antes, 1 = depois, 2 = diagnóstico
    final x = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (x == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final tag = type == 0 ? 'antes' : (type == 1 ? 'depois' : 'diagnostico');
    final dest = p.join(dir.path, 'foto_${tag}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(x.path).copy(dest);
    setState(() {
      if (type == 0) {
        _photoBefore = dest;
      } else if (type == 1) {
        _photoAfter = dest;
      } else {
        _photoDiagnostic = dest;
      }
    });
  }

  void _photoSheet(int type) {
    String tagStr = type == 0 ? 'Antes' : (type == 1 ? 'Depois' : 'Diagnóstico');
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: Text('Tirar foto ($tagStr)'),
            onTap: () {
              Navigator.pop(ctx);
              _pickPhoto(type, ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Escolher da galeria'),
            onTap: () {
              Navigator.pop(ctx);
              _pickPhoto(type, ImageSource.gallery);
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _sendDiagnosticWhatsApp() async {
    final selectedClient = _clients.firstWhere(
      (c) => c.id == _clientId,
      orElse: () => const Client(name: 'Cliente'),
    );

    final diagText = _diagnosticNotes.text.trim();
    final priceVal = double.tryParse(_price.text.replaceAll(',', '.')) ?? 0.0;

    final msg = '''
🌱 *Diagnóstico & Proposta de Tratamento - GardenApp*

*Cliente:* ${selectedClient.name}
*Serviço:* $_type

🔍 *Diagnóstico da Praga / Doença:*
${diagText.isEmpty ? "Identificada necessidade de intervenção/tratamento fitossanitário." : diagText}

💡 *Proposta de Intervenção:*
${_notes.text.trim().isEmpty ? "Aplicação de tratamento ecológico e nutrição vegetal." : _notes.text.trim()}

💰 *Valor Estimado:* ${fmtCurrency(priceVal)}
''';

    await LauncherService.openWhatsApp(selectedClient.phone, msg);
  }

  Future<void> _save() async {
    if (_clientId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Escolha um cliente.')));
      return;
    }
    final priceVal = double.tryParse(_price.text.replaceAll(',', '.')) ?? 0.0;
    final expVal = double.tryParse(_expenses.text.replaceAll(',', '.')) ?? 0.0;
    final durVal = int.tryParse(_duration.text) ?? 0;

    await AppDb.instance.saveService(Service(
      id: widget.service?.id,
      clientId: _clientId!,
      date: _date,
      type: _type,
      notes: _notes.text.trim(),
      done: _done,
      price: priceVal,
      photoBeforePath: _photoBefore,
      photoAfterPath: _photoAfter,
      durationMinutes: durVal,
      expenses: expVal,
      diagnosticPhotoPath: _photoDiagnostic,
      diagnosticNotes: _diagnosticNotes.text.trim(),
    ));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final priceVal = double.tryParse(_price.text.replaceAll(',', '.')) ?? 0.0;
    final expVal = double.tryParse(_expenses.text.replaceAll(',', '.')) ?? 0.0;
    final netProfit = priceVal - expVal;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final formattedStopwatchTime = Duration(milliseconds: _stopwatch.elapsedMilliseconds)
        .toString()
        .split('.')
        .first;

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.service == null ? 'Novo serviço' : 'Editar serviço')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cronómetro de Medição de Tempo
          Card(
            color: _isTimerRunning
                ? (isDark ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade50)
                : (isDark ? Colors.grey.shade900 : Colors.green.shade50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: _isTimerRunning ? Colors.orange : Colors.green.shade300,
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isTimerRunning ? Icons.timer : Icons.timer_outlined,
                            color: _isTimerRunning ? Colors.orange : gardenForest,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isTimerRunning ? 'Intervenção em Curso ($formattedStopwatchTime)' : 'Medição de Tempo (Cronómetro)',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isTimerRunning ? Colors.red : gardenGreen,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _toggleTimer,
                        icon: Icon(_isTimerRunning ? Icons.stop : Icons.play_arrow),
                        label: Text(_isTimerRunning ? 'Concluir' : 'Iniciar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            initialValue: (_clientId != null && _clients.any((c) => c.id == _clientId)) ? _clientId : null,
            decoration: const InputDecoration(labelText: 'Cliente'),
            hint: const Text('Selecione o cliente'),
            items: [
              for (final c in _clients)
                DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) => setState(() => _clientId = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Tipo de serviço'),
            items: [
              for (final t in serviceTypes) DropdownMenuItem(value: t, child: Text(t)),
            ],
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(fmtDate(_date)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time),
                label: Text(fmtTime(_date)),
              ),
            ),
          ]),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _price,
                  decoration: const InputDecoration(
                    labelText: 'Preço (€)',
                    prefixIcon: Icon(Icons.euro),
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _expenses,
                  decoration: const InputDecoration(
                    labelText: 'Despesas (€)',
                    hintText: 'Combustível/Aterro',
                    prefixIcon: Icon(Icons.local_gas_station),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),

          // Painel de Lucro Real Líquido
          if (priceVal > 0 || expVal > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: netProfit >= 0
                    ? (isDark ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.green.shade50)
                    : Colors.red.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: netProfit >= 0 ? Colors.green : Colors.red),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('💰 Lucro Real Líquido:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${netProfit.toStringAsFixed(2)} €',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: netProfit >= 0 ? gardenForest : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          TextField(
            controller: _duration,
            decoration: const InputDecoration(
              labelText: 'Duração da Intervenção (Minutos)',
              prefixIcon: Icon(Icons.access_alarm),
              suffixText: 'min',
            ),
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Notas / Observações do Serviço'),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),

          const SizedBox(height: 16),
          const Divider(),

          // Diagnóstico de Pragas e Doenças
          const Text('🔍 Diagnóstico de Praga / Doença Vegetal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: _photoBox('Foto Diagnóstico', _photoDiagnostic, () => _photoSheet(2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _diagnosticNotes,
                  decoration: const InputDecoration(
                    labelText: 'Descrição da Praga / Sintomas',
                    hintText: 'Ex: Cochonilha nas hortênsias',
                  ),
                  maxLines: 4,
                ),
              ),
            ],
          ),

          if (_diagnosticNotes.text.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green.shade800,
                side: BorderSide(color: Colors.green.shade800),
              ),
              onPressed: _sendDiagnosticWhatsApp,
              icon: const Icon(Icons.chat),
              label: const Text('Enviar Diagnóstico & Proposta no WhatsApp'),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Serviço concluído', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            value: _done,
            onChanged: (v) => setState(() => _done = v),
          ),

          const SizedBox(height: 16),
          const Text('Registo Fotográfico (Antes & Depois)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _photoBox('Foto Antes', _photoBefore, () => _photoSheet(0)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _photoBox('Foto Depois', _photoAfter, () => _photoSheet(1)),
              ),
            ],
          ),

          const SizedBox(height: 28),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: gardenGreen, minimumSize: const Size.fromHeight(52)),
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Guardar Serviço Completo'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _photoBox(String title, String? path, VoidCallback onTap) {
    final hasImage = path != null && File(path).existsSync();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(path), fit: BoxFit.cover),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo, size: 28, color: Colors.grey),
                  const SizedBox(height: 4),
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                ],
              ),
      ),
    );
  }
}
