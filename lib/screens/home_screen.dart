import 'package:flutter/material.dart';

import '../models.dart';
import 'agenda_screen.dart';
import 'calculators_screen.dart';
import 'clients_screen.dart';
import 'dashboard_screen.dart';
import 'equipment_screen.dart';
import 'history_screen.dart';
import 'plant_guide_screen.dart';
import 'price_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final Session session;
  final VoidCallback onLogout;
  final bool isDarkMode;
  final VoidCallback onToggleDarkMode;

  const HomeScreen({
    super.key,
    required this.session,
    required this.onLogout,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final g = widget.session.isGardener;

    final pages = <Widget>[
      if (g) const DashboardScreen(),
      if (g) const ClientsScreen(),
      PriceListScreen(session: widget.session),
      AgendaScreen(session: widget.session),
      HistoryScreen(session: widget.session),
      PlantGuideScreen(session: widget.session),
      if (g) const EquipmentScreen(),
      if (g) const CalculatorsScreen(),
    ];

    final titles = [
      if (g) 'Estatísticas',
      if (g) 'Clientes & Jardins',
      'Tabela de Preços',
      'Agenda',
      'Histórico & Avaliações',
      'Guia de Plantas',
      if (g) 'Máquinas & Carrinha',
      if (g) 'Calculadoras de Campo',
    ];

    final destinations = [
      if (g)
        const NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
      if (g)
        const NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Clientes',
        ),
      const NavigationDestination(
        icon: Icon(Icons.sell_outlined),
        selectedIcon: Icon(Icons.sell),
        label: 'Preços',
      ),
      const NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month),
        label: 'Agenda',
      ),
      const NavigationDestination(
        icon: Icon(Icons.history_outlined),
        selectedIcon: Icon(Icons.history),
        label: 'Histórico',
      ),
      const NavigationDestination(
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book),
        label: 'Guia Plantas',
      ),
      if (g)
        const NavigationDestination(
          icon: Icon(Icons.build_outlined),
          selectedIcon: Icon(Icons.build),
          label: 'Máquinas',
        ),
      if (g)
        const NavigationDestination(
          icon: Icon(Icons.calculate_outlined),
          selectedIcon: Icon(Icons.calculate),
          label: 'Calculadoras',
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(child: Text(titles[_index])),
            if (widget.session.clientName != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.session.clientName!,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: widget.isDarkMode ? 'Modo Claro' : 'Modo Escuro',
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleDarkMode,
          ),
          IconButton(
            tooltip: 'Terminar sessão',
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations,
      ),
    );
  }
}
