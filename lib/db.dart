import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// Base de dados SQL local (SQLite) – persistente, funciona sem internet.
class AppDb extends ValueNotifier<int> {
  AppDb._() : super(0);
  static final AppDb instance = AppDb._();

  void notifyDataChanged() => value++;

  Database? _db;
  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'gardenapp.db');
    return openDatabase(
      path,
      version: 4,
      onConfigure: (d) async => d.execute('PRAGMA foreign_keys = ON'),
      onCreate: (d, v) async {
        await d.execute('''
          CREATE TABLE clients(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT,
            address TEXT,
            soil_type TEXT,
            sun_exposure TEXT,
            irrigation_type TEXT,
            pets_info TEXT,
            garden_area REAL NOT NULL DEFAULT 0.0
          )''');
        await d.execute('''
          CREATE TABLE services(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client_id INTEGER NOT NULL,
            date TEXT NOT NULL,
            type TEXT NOT NULL,
            notes TEXT,
            done INTEGER NOT NULL DEFAULT 0,
            price REAL NOT NULL DEFAULT 0.0,
            photo_before TEXT,
            photo_after TEXT,
            photo_path TEXT,
            likes INTEGER NOT NULL DEFAULT 0,
            duration_minutes INTEGER NOT NULL DEFAULT 0,
            expenses REAL NOT NULL DEFAULT 0.0,
            diagnostic_photo TEXT,
            diagnostic_notes TEXT,
            FOREIGN KEY(client_id) REFERENCES clients(id) ON DELETE CASCADE
          )''');
        await d.execute('''
          CREATE TABLE service_reviews(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            service_id INTEGER NOT NULL,
            client_name TEXT NOT NULL,
            comment TEXT NOT NULL,
            rating INTEGER NOT NULL DEFAULT 5,
            created_at TEXT NOT NULL,
            FOREIGN KEY(service_id) REFERENCES services(id) ON DELETE CASCADE
          )''');
        await d.execute('''
          CREATE TABLE equipments(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            power_type TEXT NOT NULL,
            status TEXT NOT NULL,
            last_maintenance TEXT,
            next_maintenance TEXT,
            notes TEXT
          )''');
      },
      onUpgrade: (d, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await d.execute('ALTER TABLE services ADD COLUMN price REAL NOT NULL DEFAULT 0.0');
          } catch (_) {}
          try {
            await d.execute('ALTER TABLE services ADD COLUMN photo_before TEXT');
          } catch (_) {}
          try {
            await d.execute('ALTER TABLE services ADD COLUMN photo_after TEXT');
          } catch (_) {}
        }
        if (oldVersion < 3) {
          try {
            await d.execute('ALTER TABLE services ADD COLUMN likes INTEGER NOT NULL DEFAULT 0');
          } catch (_) {}
          try {
            await d.execute('''
              CREATE TABLE IF NOT EXISTS service_reviews(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                service_id INTEGER NOT NULL,
                client_name TEXT NOT NULL,
                comment TEXT NOT NULL,
                rating INTEGER NOT NULL DEFAULT 5,
                created_at TEXT NOT NULL,
                FOREIGN KEY(service_id) REFERENCES services(id) ON DELETE CASCADE
              )''');
          } catch (_) {}
        }
        if (oldVersion < 4) {
          try {
            await d.execute('ALTER TABLE clients ADD COLUMN soil_type TEXT');
          } catch (_) {}
          try {
            await d.execute('ALTER TABLE clients ADD COLUMN sun_exposure TEXT');
          } catch (_) {}
          try {
            await d.execute('ALTER TABLE clients ADD COLUMN irrigation_type TEXT');
          } catch (_) {}
          try {
            await d.execute('ALTER TABLE clients ADD COLUMN pets_info TEXT');
          } catch (_) {}
          try {
            await d.execute('ALTER TABLE clients ADD COLUMN garden_area REAL NOT NULL DEFAULT 0.0');
          } catch (_) {}

          try {
            await d.execute('ALTER TABLE services ADD COLUMN duration_minutes INTEGER NOT NULL DEFAULT 0');
          } catch (_) {}
          try {
            await d.execute('ALTER TABLE services ADD COLUMN expenses REAL NOT NULL DEFAULT 0.0');
          } catch (_) {}
          try {
            await d.execute('ALTER TABLE services ADD COLUMN diagnostic_photo TEXT');
          } catch (_) {}
          try {
            await d.execute('ALTER TABLE services ADD COLUMN diagnostic_notes TEXT');
          } catch (_) {}

          try {
            await d.execute('''
              CREATE TABLE IF NOT EXISTS equipments(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                category TEXT NOT NULL,
                power_type TEXT NOT NULL,
                status TEXT NOT NULL,
                last_maintenance TEXT,
                next_maintenance TEXT,
                notes TEXT
              )''');
          } catch (_) {}
        }
      },
    );
  }

  // ---------- Inserção de Dados Exemplo (PAP) ----------
  Future<void> seedSampleData() async {
    final existingClients = await clients();
    if (existingClients.isNotEmpty) return;

    // Inserir clientes exemplo
    final c1 = await saveClient(const Client(
      name: 'Maria Santos',
      phone: '912 345 678',
      address: 'Rua das Flores, nº 12, Lisboa',
    ));
    final c2 = await saveClient(const Client(
      name: 'João Pereira',
      phone: '961 987 654',
      address: 'Avenida do Mar, Cascais',
    ));
    final c3 = await saveClient(const Client(
      name: 'Quinta do Sol',
      phone: '934 112 233',
      address: 'Estrada Nacional 10, Sintra',
    ));

    final now = DateTime.now();

    // Inserir serviços dos últimos 5 meses até ao mês atual
    final sampleServices = [
      Service(
        clientId: c1,
        date: DateTime(now.year, now.month - 5, 10, 9, 30),
        type: 'Corte de relva',
        price: 45.00,
        done: true,
        likes: 3,
        notes: 'Corte completo e acerto de bordaduras.',
      ),
      Service(
        clientId: c2,
        date: DateTime(now.year, now.month - 4, 15, 11, 0),
        type: 'Poda',
        price: 75.00,
        done: true,
        likes: 5,
        notes: 'Poda de formação de sebes e arbustos.',
      ),
      Service(
        clientId: c3,
        date: DateTime(now.year, now.month - 3, 20, 14, 0),
        type: 'Rega / Sistema de rega',
        price: 250.00,
        done: true,
        likes: 8,
        notes: 'Instalação de circuito gota a gota.',
      ),
      Service(
        clientId: c1,
        date: DateTime(now.year, now.month - 2, 5, 10, 0),
        type: 'Limpeza de jardim',
        price: 60.00,
        done: true,
        likes: 2,
        notes: 'Remoção de ervas daninhas e folhas secas.',
      ),
      Service(
        clientId: c2,
        date: DateTime(now.year, now.month - 1, 12, 9, 0),
        type: 'Corte de relva',
        price: 55.00,
        done: true,
        likes: 4,
        notes: 'Manutenção quinzenal do relvado.',
      ),
      Service(
        clientId: c3,
        date: DateTime(now.year, now.month, 2, 15, 30),
        type: 'Plantação',
        price: 120.00,
        done: true,
        likes: 6,
        notes: 'Plantação de canteiro florido com mulching.',
      ),
      Service(
        clientId: c1,
        date: DateTime(now.year, now.month, now.day, 10, 30),
        type: 'Corte de relva',
        price: 50.00,
        done: false,
        likes: 0,
        notes: 'Corte agendado para hoje.',
      ),
      Service(
        clientId: c2,
        date: DateTime(now.year, now.month, now.day + 2, 14, 0),
        type: 'Poda',
        price: 80.00,
        done: false,
        likes: 0,
        notes: 'Poda de árvores de fruto agendada.',
      ),
    ];

    for (final s in sampleServices) {
      await saveService(s);
    }

    // Inserir avaliações de exemplo
    await saveReview(ServiceReview(
      serviceId: 1,
      clientName: 'Maria Santos',
      comment: 'Trabalho impecável no relvado! Ficou muito bem alinhado.',
      rating: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ));
    await saveReview(ServiceReview(
      serviceId: 3,
      clientName: 'Quinta do Sol',
      comment: 'O sistema de rega automática poupa-nos imenso tempo. Excelente serviço!',
      rating: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ));

    // Inserir equipamentos de exemplo
    final existingEquipments = await equipments();
    if (existingEquipments.isEmpty) {
      await saveEquipment(Equipment(
        name: 'Corta-Relva Honda HRX 537',
        category: 'Corta-relvas',
        powerType: 'Combustível',
        status: 'Operacional',
        lastMaintenance: DateTime.now().subtract(const Duration(days: 20)),
        nextMaintenance: DateTime.now().add(const Duration(days: 40)),
        notes: 'Troca de óleo efetuada. Afiar lâmina em breve.',
      ));
      await saveEquipment(Equipment(
        name: 'Moto-roçadora Stihl FS 240',
        category: 'Moto-roçadora',
        powerType: 'Combustível',
        status: 'Necessita Revisão',
        lastMaintenance: DateTime.now().subtract(const Duration(days: 90)),
        nextMaintenance: DateTime.now().subtract(const Duration(days: 5)),
        notes: 'Verificar vela de ignição e afiar lâmina.',
      ));
      await saveEquipment(Equipment(
        name: 'Soprador de Costas Husqvarna 570BT',
        category: 'Soprador',
        powerType: 'Combustível',
        status: 'Operacional',
        lastMaintenance: DateTime.now().subtract(const Duration(days: 15)),
        nextMaintenance: DateTime.now().add(const Duration(days: 75)),
        notes: 'Filtro de ar limpo.',
      ));
      await saveEquipment(Equipment(
        name: 'Corta-Sebes Stihl HSA 86',
        category: 'Corta-sebes',
        powerType: 'Bateria',
        status: 'Operacional',
        lastMaintenance: DateTime.now().subtract(const Duration(days: 10)),
        nextMaintenance: DateTime.now().add(const Duration(days: 50)),
        notes: 'Lâminas lubrificadas.',
      ));
    }
  }

  // ---------- Clientes ----------
  Future<List<Client>> clients() async {
    final d = await db;
    final rows = await d.query('clients', orderBy: 'name COLLATE NOCASE');
    return rows.map(Client.fromMap).toList();
  }

  Future<int> saveClient(Client c) async {
    final d = await db;
    int id;
    if (c.id == null) {
      id = await d.insert('clients', c.toMap());
    } else {
      await d.update('clients', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
      id = c.id!;
    }
    notifyDataChanged();
    return id;
  }

  Future<void> deleteClient(int id) async {
    final d = await db;
    await d.delete('clients', where: 'id = ?', whereArgs: [id]);
    notifyDataChanged();
  }

  // ---------- Equipamentos & Ferramentas ----------
  Future<List<Equipment>> equipments() async {
    final d = await db;
    final rows = await d.query('equipments', orderBy: 'name COLLATE NOCASE');
    return rows.map(Equipment.fromMap).toList();
  }

  Future<int> saveEquipment(Equipment e) async {
    final d = await db;
    int id;
    if (e.id == null) {
      id = await d.insert('equipments', e.toMap());
    } else {
      await d.update('equipments', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
      id = e.id!;
    }
    notifyDataChanged();
    return id;
  }

  Future<void> deleteEquipment(int id) async {
    final d = await db;
    await d.delete('equipments', where: 'id = ?', whereArgs: [id]);
    notifyDataChanged();
  }

  // ---------- Serviços ----------
  Future<List<Service>> services({int? clientId, bool? done}) async {
    final d = await db;
    final where = <String>[];
    final args = <Object>[];
    if (clientId != null) {
      where.add('s.client_id = ?');
      args.add(clientId);
    }
    if (done != null) {
      where.add('s.done = ?');
      args.add(done ? 1 : 0);
    }
    final rows = await d.rawQuery('''
      SELECT s.*, c.name AS client_name
      FROM services s JOIN clients c ON c.id = s.client_id
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY s.date ASC
    ''', args);
    return rows.map(Service.fromMap).toList();
  }

  Future<void> saveService(Service s) async {
    final d = await db;
    if (s.id == null) {
      await d.insert('services', s.toMap());
    } else {
      await d.update('services', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
    }
    notifyDataChanged();
  }

  Future<void> setDone(int id, bool done) async {
    final d = await db;
    await d.update('services', {'done': done ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
    notifyDataChanged();
  }

  Future<void> deleteService(int id) async {
    final d = await db;
    await d.delete('services', where: 'id = ?', whereArgs: [id]);
    notifyDataChanged();
  }

  Future<void> addLike(int serviceId) async {
    final d = await db;
    await d.rawUpdate('UPDATE services SET likes = likes + 1 WHERE id = ?', [serviceId]);
    notifyDataChanged();
  }

  // ---------- Comentários & Avaliações ----------
  Future<List<ServiceReview>> reviewsForService(int serviceId) async {
    final d = await db;
    final rows = await d.query(
      'service_reviews',
      where: 'service_id = ?',
      whereArgs: [serviceId],
      orderBy: 'created_at DESC',
    );
    return rows.map(ServiceReview.fromMap).toList();
  }

  Future<void> saveReview(ServiceReview r) async {
    final d = await db;
    await d.insert('service_reviews', r.toMap());
    notifyDataChanged();
  }

  // ---------- Estatísticas & Métricas ----------
  Future<double> totalRevenue() async {
    final d = await db;
    final res = await d.rawQuery('SELECT SUM(price) as total FROM services WHERE done = 1');
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> currentMonthRevenue() async {
    final d = await db;
    final now = DateTime.now();
    final monthStr = '${now.year}-${two(now.month)}';
    final res = await d.rawQuery(
      'SELECT SUM(price) as total FROM services WHERE done = 1 AND date LIKE ?',
      ['$monthStr%'],
    );
    return (res.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> doneServicesCount() async {
    final d = await db;
    final res = await d.rawQuery('SELECT COUNT(*) as cnt FROM services WHERE done = 1');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<int> pendingServicesCount() async {
    final d = await db;
    final res = await d.rawQuery('SELECT COUNT(*) as cnt FROM services WHERE done = 0');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<Map<String, int>> servicesCountByType() async {
    final d = await db;
    final rows = await d.rawQuery(
      'SELECT type, COUNT(*) as cnt FROM services GROUP BY type ORDER BY cnt DESC',
    );
    final map = <String, int>{};
    for (final r in rows) {
      map[r['type'] as String] = (r['cnt'] as num).toInt();
    }
    return map;
  }

  Future<Map<String, double>> monthlyRevenueLast6Months() async {
    final d = await db;
    final result = <String, double>{};
    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = '${date.year}-${two(date.month)}';
      final label = '${two(date.month)}/${date.year.toString().substring(2)}';

      final res = await d.rawQuery(
        'SELECT SUM(price) as total FROM services WHERE done = 1 AND date LIKE ?',
        ['$key%'],
      );
      final val = (res.first['total'] as num?)?.toDouble() ?? 0.0;
      result[label] = val;
    }
    return result;
  }
}
