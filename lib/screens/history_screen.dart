import 'dart:io';

import 'package:flutter/material.dart';

import '../db.dart';
import '../main.dart';
import '../models.dart';
import '../services/pdf_service.dart';

/// Histórico de todos os serviços concluídos, por data e por cliente.
class HistoryScreen extends StatefulWidget {
  final Session session;
  const HistoryScreen({super.key, required this.session});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Service> _items = [];
  List<Client> _clients = [];
  int? _filter;
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
    final g = widget.session.isGardener;
    final items = await AppDb.instance.services(
      clientId: g ? _filter : widget.session.clientId,
      done: true,
    );
    final clients = g ? await AppDb.instance.clients() : <Client>[];
    if (!mounted) return;
    setState(() {
      _items = items.reversed.toList(); // mais recentes primeiro
      _clients = clients;
      _loading = false;
    });
  }

  Future<void> _exportPdf(Service s) async {
    final clients = await AppDb.instance.clients();
    final client = clients.firstWhere(
      (c) => c.id == s.clientId,
      orElse: () => Client(id: s.clientId, name: s.clientName),
    );
    await PdfService.generateAndShareReceipt(service: s, client: client, context: context);
  }

  Future<void> _addLike(Service s) async {
    if (s.id != null) {
      await AppDb.instance.addLike(s.id!);
      _load();
    }
  }

  void _openReviewsSheet(Service s) async {
    if (s.id == null) return;
    final reviews = await AppDb.instance.reviewsForService(s.id!);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ReviewsModalSheet(
        service: s,
        initialReviews: reviews,
        session: widget.session,
        onAddReview: (review) async {
          await AppDb.instance.saveReview(review);
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final filteredItems = _items.where((s) {
      if (_query.trim().isEmpty) return true;
      final q = _query.toLowerCase();
      return s.type.toLowerCase().contains(q) ||
          s.clientName.toLowerCase().contains(q) ||
          s.notes.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Pesquisar por serviço, cliente ou notas...',
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        if (widget.session.isGardener)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: DropdownButtonFormField<int?>(
              initialValue: _filter,
              decoration: const InputDecoration(labelText: 'Filtrar por cliente', isDense: true),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Todos os clientes')),
                for (final c in _clients)
                  DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) {
                _filter = v;
                _load();
              },
            ),
          ),
        Expanded(
          child: filteredItems.isEmpty
              ? const Center(child: Text('Ainda não há serviços concluídos.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (_, i) {
                      final s = filteredItems[i];
                      final hasBefore =
                          s.photoBeforePath != null && File(s.photoBeforePath!).existsSync();
                      final hasAfter =
                          s.photoAfterPath != null && File(s.photoAfterPath!).existsSync();
                      final hasPhoto = hasBefore || hasAfter || (s.photoPath != null && File(s.photoPath!).existsSync());

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasPhoto)
                              SizedBox(
                                height: 160,
                                child: Row(
                                  children: [
                                    if (hasBefore)
                                      Expanded(
                                        child: Image.file(
                                          File(s.photoBeforePath!),
                                          fit: BoxFit.cover,
                                          height: 160,
                                        ),
                                      ),
                                    if (hasAfter)
                                      Expanded(
                                        child: Image.file(
                                          File(s.photoAfterPath!),
                                          fit: BoxFit.cover,
                                          height: 160,
                                        ),
                                      ),
                                    if (!hasBefore && !hasAfter && s.photoPath != null)
                                      Expanded(
                                        child: Image.file(
                                          File(s.photoPath!),
                                          fit: BoxFit.cover,
                                          height: 160,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ListTile(
                              leading: const Icon(Icons.check_circle, color: gardenGreen, size: 28),
                              title: Text(s.type,
                                  style: const TextStyle(
                                      fontSize: 17, fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${s.clientName}\n${fmtDate(s.date)} · ${fmtTime(s.date)}'
                                '${s.price > 0 ? "\nValor: ${fmtCurrency(s.price)}" : ""}'
                                '${s.notes.isNotEmpty ? "\nNotas: ${s.notes}" : ""}',
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                tooltip: 'Comprovativo PDF',
                                icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                                onPressed: () => _exportPdf(s),
                              ),
                            ),
                            const Divider(height: 1),
                            // Bar com Likes e Comentários
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _addLike(s),
                                    icon: const Icon(Icons.thumb_up_alt_outlined, size: 18, color: Colors.blue),
                                    label: Text('${s.likes} Gosto(s)', style: const TextStyle(color: Colors.blue)),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () => _openReviewsSheet(s),
                                    icon: const Icon(Icons.comment_outlined, size: 18, color: gardenForest),
                                    label: const Text('Comentários & Avaliação', style: TextStyle(color: gardenForest)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _ReviewsModalSheet extends StatefulWidget {
  final Service service;
  final List<ServiceReview> initialReviews;
  final Session session;
  final Function(ServiceReview) onAddReview;

  const _ReviewsModalSheet({
    required this.service,
    required this.initialReviews,
    required this.session,
    required this.onAddReview,
  });

  @override
  State<_ReviewsModalSheet> createState() => _ReviewsModalSheetState();
}

class _ReviewsModalSheetState extends State<_ReviewsModalSheet> {
  late List<ServiceReview> _reviews;
  final _commentCtrl = TextEditingController();
  int _selectedRating = 5;

  @override
  void initState() {
    super.initState();
    _reviews = List.from(widget.initialReviews);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _submitReview() {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final author = widget.session.clientName ?? (widget.session.isGardener ? 'Jardineiro' : 'Cliente');

    final newReview = ServiceReview(
      serviceId: widget.service.id!,
      clientName: author,
      comment: text,
      rating: _selectedRating,
      createdAt: DateTime.now(),
    );

    widget.onAddReview(newReview);

    setState(() {
      _reviews.insert(0, newReview);
      _commentCtrl.clear();
    });
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Comentários · ${widget.service.type}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),

          // Formulário para novo comentário
          Row(
            children: [
              const Text('Avaliação: ', style: TextStyle(fontWeight: FontWeight.bold)),
              for (int star = 1; star <= 5; star++)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    star <= _selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 22,
                  ),
                  onPressed: () => setState(() => _selectedRating = star),
                ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Escreva um comentário ou feedback...',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: gardenGreen),
                icon: const Icon(Icons.send),
                onPressed: _submitReview,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Lista de Comentários
          SizedBox(
            height: 220,
            child: _reviews.isEmpty
                ? const Center(child: Text('Ainda não há comentários. Seja o primeiro a comentar!'))
                : ListView.builder(
                    itemCount: _reviews.length,
                    itemBuilder: (_, i) {
                      final r = _reviews[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: Theme.of(context).cardColor,
                        child: ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(r.clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Row(
                                children: [
                                  for (int s = 0; s < r.rating; s++)
                                    const Icon(Icons.star, color: Colors.amber, size: 14),
                                ],
                              ),
                            ],
                          ),
                          subtitle: Text('${r.comment}\n${fmtDate(r.createdAt)} ${fmtTime(r.createdAt)}',
                              style: const TextStyle(fontSize: 12)),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
