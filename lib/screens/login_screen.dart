import 'package:flutter/material.dart';

import '../db.dart';
import '../main.dart';
import '../models.dart';

class LoginScreen extends StatelessWidget {
  final Future<void> Function(Session) onLogin;
  const LoginScreen({super.key, required this.onLogin});

  void _openClientLoginSheet(BuildContext context) async {
    final clients = await AppDb.instance.clients();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ClientLoginSheet(
        existingClients: clients,
        onSelectClient: (c) {
          Navigator.pop(ctx);
          onLogin(Session(Role.client, clientId: c.id, clientName: c.name));
        },
        onGuestLogin: () {
          Navigator.pop(ctx);
          onLogin(const Session(Role.client, clientId: null, clientName: 'Cliente Visitante'));
        },
        onRegisterClient: (name, phone, address) async {
          final id = await AppDb.instance.saveClient(Client(
            name: name,
            phone: phone,
            address: address,
          ));
          if (ctx.mounted) Navigator.pop(ctx);
          onLogin(Session(Role.client, clientId: id, clientName: name));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: gardenDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(Icons.eco, size: 72, color: gardenGreen),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'GardenApp',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gestão & Serviços de Jardinagem',
                textAlign: TextAlign.center,
                style: TextStyle(color: gardenGreen, fontSize: 16),
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: gardenGreen),
                onPressed: () => onLogin(const Session(Role.gardener, clientName: 'Jardineiro')),
                icon: const Icon(Icons.yard),
                label: const Text('Entrar como Jardineiro'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: gardenGreen, width: 1.5),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                onPressed: () => _openClientLoginSheet(context),
                icon: const Icon(Icons.person),
                label: const Text('Entrar como Cliente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientLoginSheet extends StatefulWidget {
  final List<Client> existingClients;
  final Function(Client) onSelectClient;
  final VoidCallback onGuestLogin;
  final Function(String name, String phone, String address) onRegisterClient;

  const _ClientLoginSheet({
    required this.existingClients,
    required this.onSelectClient,
    required this.onGuestLogin,
    required this.onRegisterClient,
  });

  @override
  State<_ClientLoginSheet> createState() => _ClientLoginSheetState();
}

class _ClientLoginSheetState extends State<_ClientLoginSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.existingClients.isEmpty ? 1 : 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasClients = widget.existingClients.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Acesso de Cliente',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          TabBar(
            controller: _tabController,
            labelColor: gardenForest,
            indicatorColor: gardenGreen,
            tabs: [
              if (hasClients) const Tab(text: 'Clientes Registados'),
              const Tab(text: 'Registar Novo'),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 250,
            child: TabBarView(
              controller: _tabController,
              children: [
                if (hasClients)
                  ListView.builder(
                    itemCount: widget.existingClients.length,
                    itemBuilder: (_, i) {
                      final c = widget.existingClients[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: gardenGreen,
                            foregroundColor: Colors.white,
                            child: Text(c.name.isEmpty ? '?' : c.name[0].toUpperCase()),
                          ),
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(c.phone.isNotEmpty ? c.phone : c.address),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => widget.onSelectClient(c),
                        ),
                      );
                    },
                  ),

                Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'O seu nome',
                            prefixIcon: Icon(Icons.person),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Indique o nome' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Telemóvel',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _addressCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Morada / Local',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: gardenGreen,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              widget.onRegisterClient(
                                _nameCtrl.text.trim(),
                                _phoneCtrl.text.trim(),
                                _addressCtrl.text.trim(),
                              );
                            }
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Registar & Entrar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: widget.onGuestLogin,
            icon: const Icon(Icons.visibility),
            label: const Text('Entrar sem Registo (Visitante)'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
