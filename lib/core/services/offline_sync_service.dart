import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'dart:convert';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  Database? _database;
  final _connectivity = Connectivity();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pharma_connect.db');
    return await openDatabase(
      path,
      version: 12,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE health_records (
        id TEXT PRIMARY KEY,
        patient_id TEXT,
        blood_type TEXT,
        height INTEGER,
        weight INTEGER,
        allergies TEXT,
        medical_conditions TEXT,
        medications TEXT,
        vaccinations TEXT,
        notes TEXT,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE consultations (
        id TEXT PRIMARY KEY,
        patient_id TEXT,
        professional_id TEXT,
        scheduled_at TEXT,
        duration_minutes INTEGER,
        status TEXT,
        reason TEXT,
        notes TEXT,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE interventions (
        id TEXT PRIMARY KEY,
        patient_id TEXT,
        professional_id TEXT,
        scheduled_at TEXT,
        duration_minutes INTEGER,
        status TEXT,
        reason TEXT,
        address TEXT,
        notes TEXT,
        report TEXT,
        created_at TEXT,
        updated_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        table_name TEXT,
        record_id TEXT,
        operation TEXT,
        data TEXT,
        status TEXT,
        retry_count INTEGER,
        error_message TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Module 4 (STK, 29/08/2026) : cache local du stock d'une officine —
    // directive « privilégier le mode hors-ligne ». Générique par
    // pharmacy_id pour rester réutilisable si un autre module a un jour
    // besoin du même patron (liste + réécriture locale ligne par ligne).
    await db.execute('''
      CREATE TABLE cache_stock_items (
        id TEXT PRIMARY KEY,
        pharmacy_id TEXT,
        data TEXT,
        cached_at TEXT
      )
    ''');

    // Module 5 (ORD, 29/08/2026) : même patron que cache_stock_items,
    // appliqué aux ordonnances — directive standing « privilégier le mode
    // hors-ligne ». owner_key = id de l'utilisateur authentifié (et non
    // pharmacy_id, absent de prescriptions) : PrescriptionProvider sert aussi
    // bien la vue patient ("mes ordonnances") que la vue pharmacien (file de
    // validation), et deux comptes différents sur le même appareil ne
    // doivent jamais se partager le même cache local.
    await db.execute('''
      CREATE TABLE cache_prescriptions (
        id TEXT PRIMARY KEY,
        owner_key TEXT,
        data TEXT,
        cached_at TEXT
      )
    ''');

    // Module 6 (RES, 29/08/2026) : même patron que cache_prescriptions.
    // owner_key distingue la vue patient ("mes réservations", clé =
    // patient_id) de la vue pharmacien (file d'attente d'une officine, clé
    // = 'staff_queue_<pharmacy_id>') pour les mêmes raisons.
    await db.execute('''
      CREATE TABLE cache_reservations (
        id TEXT PRIMARY KEY,
        owner_key TEXT,
        data TEXT,
        cached_at TEXT
      )
    ''');

    // Module 7 (LIV, 29/08/2026) : même patron. owner_key distingue la vue
    // patient ("mes livraisons", clé = patient_id) de la vue livreur
    // (courses assignées, clé = 'driver_<driver_id>').
    await db.execute('''
      CREATE TABLE cache_deliveries (
        id TEXT PRIMARY KEY,
        owner_key TEXT,
        data TEXT,
        cached_at TEXT
      )
    ''');

    // Module 8 (PAY, 29/08/2026) : même patron que cache_deliveries pour
    // l'historique de transactions (owner_key = patient_id). cache_wallet
    // est un cache à une seule ligne par utilisateur (id = user_id, pas
    // besoin d'owner_key séparé) — voir le rapport d'audit pour la raison
    // pour laquelle seule la LECTURE (solde, historique) bénéficie d'un
    // repli hors-ligne ici, jamais l'écriture (initiation de paiement,
    // recharge, échéance).
    await db.execute('''
      CREATE TABLE cache_transactions (
        id TEXT PRIMARY KEY,
        owner_key TEXT,
        data TEXT,
        cached_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cache_wallet (
        id TEXT PRIMARY KEY,
        data TEXT,
        cached_at TEXT
      )
    ''');

    // Module 10 (ALR, 29/08/2026) : même patron que cache_transactions —
    // directive standing « privilégier le mode hors-ligne ». owner_key =
    // user_id de l'utilisateur authentifié (une alerte personnelle ou
    // d'officine reste toujours consultée depuis le même compte connecté).
    // Lecture seule, comme les autres caches de ce module : consulter une
    // alerte hors-ligne (marquer lu/traité/ignoré) reste une écriture
    // différée, pas couverte ici — cohérent avec la décision déjà prise pour
    // PAY (Module 8).
    await db.execute('''
      CREATE TABLE cache_alerts (
        id TEXT PRIMARY KEY,
        owner_key TEXT,
        data TEXT,
        cached_at TEXT
      )
    ''');

    // Module 11 (IA, 29/08/2026) : même patron que cache_alerts — directive
    // standing « privilégier le mode hors-ligne ». owner_key = pharmacy_id
    // (les deux écrans de ce module sont scopés officine, pas utilisateur).
    // Lecture seule : générer une prévision ou valider une commande reste
    // une écriture en ligne uniquement, cohérent avec PAY (D13) et ALR.
    await db.execute('''
      CREATE TABLE cache_forecasts (
        id TEXT PRIMARY KEY,
        owner_key TEXT,
        data TEXT,
        cached_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE cache_reorder_alerts (
        id TEXT PRIMARY KEY,
        owner_key TEXT,
        data TEXT,
        cached_at TEXT
      )
    ''');

    // Module 12 (TRC, 29/08/2026) : même patron que cache_stock_items, mais
    // sans owner_key — contrairement aux autres caches, la liste des lots
    // tracés n'est pas scopée par officine/utilisateur (un lot traverse
    // plusieurs officines/grossistes au fil de sa vie, comme documenté pour
    // les policies RLS de la même migration). Lecture seule (repli du
    // dashboard) : les écritures de ce module (receiveBatch) passent par
    // queueOperation() comme STK, jamais par un cache dédié.
    await db.execute('''
      CREATE TABLE cache_traceable_batches (
        id TEXT PRIMARY KEY,
        data TEXT,
        cached_at TEXT
      )
    ''');

    // Module 13 (B2B, 29/08/2026) : même patron que cache_traceable_batches,
    // sans owner_key — directive standing « privilégier le mode hors-ligne ».
    // Ne couvre que la LECTURE du catalogue global (onglet « Offres » de
    // marketplace_home_screen.dart, la vue la plus utile hors-ligne : un
    // pharmacien peut au moins consulter les offres déjà vues). « Mes
    // offres »/« Mes commandes » et toutes les écritures (créer/négocier/
    // commander/changer un statut) restent en ligne uniquement, différé au
    // registre des écarts — même logique que PAY (D13) et ALR pour ne pas
    // risquer un double envoi de négociation/commande après reconnexion.
    await db.execute('''
      CREATE TABLE cache_b2b_offers (
        id TEXT PRIMARY KEY,
        data TEXT,
        cached_at TEXT
      )
    ''');

    // Module 13 (B2B, 29/08/2026, clôture) : extension du mode hors-ligne à
    // « Mes offres »/« Mes commandes » (arbitrage porteur du projet) — même
    // patron owner_key que cache_prescriptions/cache_reservations, distinct
    // de cache_b2b_offers (catalogue global, sans owner_key) puisque ces deux
    // onglets sont scopés à l'officine connectée (owner_key = pharmacy_id).
    // Lecture seule : créer/modifier/supprimer une offre, négocier ou
    // commander restent en ligne uniquement, même logique que PAY (D13) et
    // le catalogue global de ce même module — éviter tout rejeu ambigu d'une
    // négociation/commande après reconnexion.
    await db.execute('''
      CREATE TABLE cache_my_b2b_offers (
        id TEXT PRIMARY KEY,
        owner_key TEXT,
        data TEXT,
        cached_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE cache_b2b_orders (
        id TEXT PRIMARY KEY,
        owner_key TEXT,
        data TEXT,
        cached_at TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE sync_queue ADD COLUMN retry_count INTEGER DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE sync_queue ADD COLUMN error_message TEXT
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cache_stock_items (
          id TEXT PRIMARY KEY,
          pharmacy_id TEXT,
          data TEXT,
          cached_at TEXT
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cache_prescriptions (
          id TEXT PRIMARY KEY,
          owner_key TEXT,
          data TEXT,
          cached_at TEXT
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cache_reservations (
          id TEXT PRIMARY KEY,
          owner_key TEXT,
          data TEXT,
          cached_at TEXT
        )
      ''');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cache_deliveries (
          id TEXT PRIMARY KEY,
          owner_key TEXT,
          data TEXT,
          cached_at TEXT
        )
      ''');
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cache_transactions (
          id TEXT PRIMARY KEY,
          owner_key TEXT,
          data TEXT,
          cached_at TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cache_wallet (
          id TEXT PRIMARY KEY,
          data TEXT,
          cached_at TEXT
        )
      ''');
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cache_alerts (
          id TEXT PRIMARY KEY,
          owner_key TEXT,
          data TEXT,
          cached_at TEXT
        )
      ''');
    }
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cache_forecasts (
          id TEXT PRIMARY KEY,
          owner_key TEXT,
          data TEXT,
          cached_at TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cache_reorder_alerts (
          id TEXT PRIMARY KEY,
          owner_key TEXT,
          data TEXT,
          cached_at TEXT
        )
      ''');
    }
    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cache_traceable_batches (
          id TEXT PRIMARY KEY,
          data TEXT,
          cached_at TEXT
        )
      ''');
    }
    if (oldVersion < 11) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cache_b2b_offers (
          id TEXT PRIMARY KEY,
          data TEXT,
          cached_at TEXT
        )
      ''');
    }
    if (oldVersion < 12) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cache_my_b2b_offers (
          id TEXT PRIMARY KEY,
          owner_key TEXT,
          data TEXT,
          cached_at TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cache_b2b_orders (
          id TEXT PRIMARY KEY,
          owner_key TEXT,
          data TEXT,
          cached_at TEXT
        )
      ''');
    }
  }

  // ---- Record Management ----

  Future<void> saveRecord({
    required String table,
    required Map<String, dynamic> record,
    bool sync = true,
  }) async {
    final db = await database;
    await db.insert(
      table,
      record,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (sync) {
      await _addToSyncQueue(table, record['id'], 'insert', record);
    }
  }

  Future<List<Map<String, dynamic>>> getRecords(String table) async {
    final db = await database;
    return await db.query(table);
  }

  Future<Map<String, dynamic>?> getRecord(String table, String id) async {
    final db = await database;
    final results = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> deleteRecord(String table, String id) async {
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
    await _addToSyncQueue(table, id, 'delete', {});
  }

  // ---- Sync Queue ----

  Future<void> _addToSyncQueue(
    String table,
    String recordId,
    String operation,
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.insert('sync_queue', {
      'id': '${DateTime.now().millisecondsSinceEpoch}_$recordId',
      'table_name': table,
      'record_id': recordId,
      'operation': operation,
      'data': jsonEncode(data),
      'status': 'pending',
      'retry_count': 0,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<List<SyncQueueItem>> getPendingSyncItems() async {
    final db = await database;
    final results = await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
    return results.map((e) => SyncQueueItem.fromJson(e)).toList();
  }

  Future<void> markSynced(String id) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {'status': 'completed', 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markFailed(String id, String error) async {
    // Bug corrigé (audit Module 4, 29/08/2026) : `sqlExpr(...)` n'est une
    // fonction ni de sqflite ni de ce fichier — cet appel levait une
    // NoSuchMethodError à chaque échec de synchronisation, empêchant
    // `retry_count` d'être incrémenté (et plantant potentiellement la
    // boucle syncAll avant qu'elle ait pu traiter les items suivants). Le
    // même bug existe dans core/services/offline_sales_service.dart (module
    // hors-cahier pos/sales, non corrigé ici — voir registre des écarts,
    // item B5) : `db.update()` n'accepte que des valeurs littérales, pas
    // des expressions SQL ; l'incrément doit passer par `rawUpdate`.
    final db = await database;
    await db.rawUpdate(
      'UPDATE sync_queue SET status = ?, error_message = ?, retry_count = retry_count + 1, updated_at = ? WHERE id = ?',
      ['failed', error, DateTime.now().toIso8601String(), id],
    );
  }

  // ---- Cache stock (Module 4 — STK) ----
  //
  // Directive standing « privilégier le mode hors-ligne » : StockProvider
  // met en cache la dernière lecture réussie du stock d'une officine ici, et
  // s'y replie si le réseau échoue. `queueOperation` expose la primitive
  // déjà existante de file d'attente pour que StockProvider puisse y
  // enregistrer un ajustement de stock effectué hors-ligne, rejoué plus
  // tard par syncAll() exactement comme n'importe quelle autre écriture en
  // attente — sans dupliquer la logique de file d'attente.

  Future<void> queueOperation({
    required String table,
    required String recordId,
    required String operation,
    required Map<String, dynamic> data,
  }) => _addToSyncQueue(table, recordId, operation, data);

  Future<void> cacheStockItems(
    String pharmacyId,
    List<Map<String, dynamic>> rawItems,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    batch.delete(
      'cache_stock_items',
      where: 'pharmacy_id = ?',
      whereArgs: [pharmacyId],
    );
    for (final item in rawItems) {
      batch.insert('cache_stock_items', {
        'id': item['id'] as String,
        'pharmacy_id': pharmacyId,
        'data': jsonEncode(item),
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedStockItems(
    String pharmacyId,
  ) async {
    final db = await database;
    final rows = await db.query(
      'cache_stock_items',
      where: 'pharmacy_id = ?',
      whereArgs: [pharmacyId],
    );
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  /// Applique localement un correctif (ex. nouvelle total_quantity/status)
  /// à une ligne déjà en cache, pour que l'écran liste reflète tout de suite
  /// un ajustement mis en file d'attente hors-ligne, sans attendre la
  /// prochaine synchronisation réussie.
  Future<void> patchCachedStockItem(
    String pharmacyId,
    String stockItemId,
    Map<String, dynamic> patch,
  ) async {
    final db = await database;
    final rows = await db.query(
      'cache_stock_items',
      where: 'id = ? AND pharmacy_id = ?',
      whereArgs: [stockItemId, pharmacyId],
    );
    if (rows.isEmpty) return;
    final data = jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
    data.addAll(patch);
    await db.update(
      'cache_stock_items',
      {'data': jsonEncode(data)},
      where: 'id = ?',
      whereArgs: [stockItemId],
    );
  }

  // ---- Cache prescriptions (Module 5 — ORD) ----
  //
  // owner_key distingue la vue patient ("mes ordonnances", clé = patient_id)
  // de la vue pharmacien (file de validation, clé constante 'staff_queue')
  // afin qu'un même appareil utilisé par les deux rôles (démo, changement de
  // compte) ne mélange jamais les deux caches.

  Future<void> cachePrescriptions(
    String ownerKey,
    List<Map<String, dynamic>> rawItems,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    batch.delete(
      'cache_prescriptions',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
    );
    for (final item in rawItems) {
      batch.insert('cache_prescriptions', {
        'id': item['id'] as String,
        'owner_key': ownerKey,
        'data': jsonEncode(item),
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedPrescriptions(
    String ownerKey,
  ) async {
    final db = await database;
    final rows = await db.query(
      'cache_prescriptions',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
    );
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  /// Insère localement une ordonnance créée hors-ligne (dépôt patient sans
  /// réseau) pour qu'elle apparaisse tout de suite dans "mes ordonnances",
  /// avant même que syncAll() ait pu la rejouer côté serveur.
  Future<void> upsertCachedPrescription(
    String ownerKey,
    Map<String, dynamic> item,
  ) async {
    final db = await database;
    await db.insert('cache_prescriptions', {
      'id': item['id'] as String,
      'owner_key': ownerKey,
      'data': jsonEncode(item),
      'cached_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ---- Cache reservations (Module 6 — RES) ----

  Future<void> cacheReservations(
    String ownerKey,
    List<Map<String, dynamic>> rawItems,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    batch.delete(
      'cache_reservations',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
    );
    for (final item in rawItems) {
      batch.insert('cache_reservations', {
        'id': item['id'] as String,
        'owner_key': ownerKey,
        'data': jsonEncode(item),
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedReservations(
    String ownerKey,
  ) async {
    final db = await database;
    final rows = await db.query(
      'cache_reservations',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
    );
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  /// Insère localement une réservation créée hors-ligne, même logique que
  /// upsertCachedPrescription (Module 5).
  Future<void> upsertCachedReservation(
    String ownerKey,
    Map<String, dynamic> item,
  ) async {
    final db = await database;
    await db.insert('cache_reservations', {
      'id': item['id'] as String,
      'owner_key': ownerKey,
      'data': jsonEncode(item),
      'cached_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ---- Cache deliveries (Module 7 — LIV) ----

  Future<void> cacheDeliveries(
    String ownerKey,
    List<Map<String, dynamic>> rawItems,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    batch.delete(
      'cache_deliveries',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
    );
    for (final item in rawItems) {
      batch.insert('cache_deliveries', {
        'id': item['id'] as String,
        'owner_key': ownerKey,
        'data': jsonEncode(item),
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedDeliveries(
    String ownerKey,
  ) async {
    final db = await database;
    final rows = await db.query(
      'cache_deliveries',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
    );
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  // ---- Cache payments (Module 8 — PAY) ----
  //
  // Audit Module 8 (29/08/2026) : directive standing « privilégier le mode
  // hors-ligne », appliquée ici seulement à la LECTURE (solde du
  // portefeuille, historique de transactions). Contrairement à STK/ORD/RES/
  // LIV, aucune écriture de ce module (initiation de paiement, recharge de
  // portefeuille, paiement d'échéance) n'est mise en file d'attente
  // hors-ligne : rejouer une initiation de paiement après coup risquerait un
  // double débit ou une confirmation en double une fois reconnecté, ce
  // qu'un simple ajustement de stock ou une réservation ne risquent pas de
  // la même façon. Décision documentée au registre des écarts plutôt que
  // traitée en silence.

  Future<void> cacheTransactions(
    String ownerKey,
    List<Map<String, dynamic>> rawItems,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    batch.delete(
      'cache_transactions',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
    );
    for (final item in rawItems) {
      batch.insert('cache_transactions', {
        'id': item['id'] as String,
        'owner_key': ownerKey,
        'data': jsonEncode(item),
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedTransactions(
    String ownerKey,
  ) async {
    final db = await database;
    final rows = await db.query(
      'cache_transactions',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
    );
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  Future<void> cacheWallet(
    String userId,
    Map<String, dynamic> walletJson,
  ) async {
    final db = await database;
    await db.insert('cache_wallet', {
      'id': userId,
      'data': jsonEncode(walletJson),
      'cached_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getCachedWallet(String userId) async {
    final row = await getRecord('cache_wallet', userId);
    if (row == null) return null;
    return jsonDecode(row['data'] as String) as Map<String, dynamic>;
  }

  // ---- Cache alerts (Module 10 — ALR) ----

  Future<void> cacheAlerts(
    String ownerKey,
    List<Map<String, dynamic>> rawItems,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    batch.delete(
      'cache_alerts',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
    );
    for (final item in rawItems) {
      batch.insert('cache_alerts', {
        'id': item['id'] as String,
        'owner_key': ownerKey,
        'data': jsonEncode(item),
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedAlerts(String ownerKey) async {
    final db = await database;
    final rows = await db.query(
      'cache_alerts',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
    );
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  // ---- Cache forecasts & reorder alerts (Module 11 — IA) ----

  Future<void> cacheForecasts(
    String ownerKey,
    List<Map<String, dynamic>> rawItems,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    batch.delete(
      'cache_forecasts',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
    );
    for (final item in rawItems) {
      batch.insert('cache_forecasts', {
        'id': item['id'] as String,
        'owner_key': ownerKey,
        'data': jsonEncode(item),
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedForecasts(
    String ownerKey,
  ) async {
    final db = await database;
    final rows = await db.query(
      'cache_forecasts',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
    );
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  Future<void> cacheReorderAlerts(
    String ownerKey,
    List<Map<String, dynamic>> rawItems,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    batch.delete(
      'cache_reorder_alerts',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
    );
    for (final item in rawItems) {
      batch.insert('cache_reorder_alerts', {
        'id': item['id'] as String,
        'owner_key': ownerKey,
        'data': jsonEncode(item),
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedReorderAlerts(
    String ownerKey,
  ) async {
    final db = await database;
    final rows = await db.query(
      'cache_reorder_alerts',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
    );
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  // ---- Cache lots tracés (Module 12 — TRC) ----

  Future<void> cacheTraceableBatches(
    List<Map<String, dynamic>> rawItems,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    batch.delete('cache_traceable_batches');
    for (final item in rawItems) {
      batch.insert('cache_traceable_batches', {
        'id': item['id'] as String,
        'data': jsonEncode(item),
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedTraceableBatches() async {
    final db = await database;
    final rows = await db.query('cache_traceable_batches');
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  // ---- Cache offres B2B (Module 13 — B2B) ----

  Future<void> cacheB2BOffers(List<Map<String, dynamic>> rawItems) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    batch.delete('cache_b2b_offers');
    for (final item in rawItems) {
      batch.insert('cache_b2b_offers', {
        'id': item['id'] as String,
        'data': jsonEncode(item),
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedB2BOffers() async {
    final db = await database;
    final rows = await db.query('cache_b2b_offers');
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  // ---- Cache « Mes offres » / « Mes commandes » (Module 13 — B2B, clôture) ----
  //
  // owner_key = pharmacy_id de l'officine connectée, même patron que
  // cache_prescriptions/cache_reservations — distinct de cache_b2b_offers
  // (catalogue global, sans owner_key).

  Future<void> cacheMyB2BOffers(
    String ownerKey,
    List<Map<String, dynamic>> rawItems,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    batch.delete(
      'cache_my_b2b_offers',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
    );
    for (final item in rawItems) {
      batch.insert('cache_my_b2b_offers', {
        'id': item['id'] as String,
        'owner_key': ownerKey,
        'data': jsonEncode(item),
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedMyB2BOffers(
    String ownerKey,
  ) async {
    final db = await database;
    final rows = await db.query(
      'cache_my_b2b_offers',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
    );
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  Future<void> cacheB2BOrders(
    String ownerKey,
    List<Map<String, dynamic>> rawItems,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    batch.delete(
      'cache_b2b_orders',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
    );
    for (final item in rawItems) {
      batch.insert('cache_b2b_orders', {
        'id': item['id'] as String,
        'owner_key': ownerKey,
        'data': jsonEncode(item),
        'cached_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedB2BOrders(
    String ownerKey,
  ) async {
    final db = await database;
    final rows = await db.query(
      'cache_b2b_orders',
      where: 'owner_key = ?',
      whereArgs: [ownerKey],
    );
    return rows
        .map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>)
        .toList();
  }

  // ---- Sync Process ----

  Future<void> syncAll() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return;
    }

    final items = await getPendingSyncItems();
    for (final item in items) {
      try {
        await _syncItem(item);
        await markSynced(item.id);
      } catch (e) {
        await markFailed(item.id, e.toString());
      }
    }
  }

  Future<void> _syncItem(SyncQueueItem item) async {
    final client = SupabaseService().client;
    final data = jsonDecode(item.data) as Map<String, dynamic>;

    switch (item.operation) {
      case 'insert':
        await client.from(item.tableName).insert(data);
        break;
      case 'update':
        await client.from(item.tableName).update(data).eq('id', item.recordId);
        break;
      case 'delete':
        await client.from(item.tableName).delete().eq('id', item.recordId);
        break;
    }
  }

  // ---- Clear local data ----

  Future<void> clearAll() async {
    final db = await database;
    final tables = [
      'health_records',
      'consultations',
      'interventions',
      'sync_queue',
      'cache_stock_items',
      'cache_prescriptions',
      'cache_reservations',
      'cache_deliveries',
      'cache_transactions',
      'cache_wallet',
      'cache_alerts',
      'cache_forecasts',
      'cache_reorder_alerts',
      'cache_traceable_batches',
      'cache_b2b_offers',
      'cache_my_b2b_offers',
      'cache_b2b_orders',
    ];
    for (final table in tables) {
      await db.delete(table);
    }
  }

  // ---- Connectivity ----

  Future<bool> hasInternet() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
}

class SyncQueueItem {
  final String id;
  final String tableName;
  final String recordId;
  final String operation;
  final String data;
  final String status;
  final int retryCount;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  SyncQueueItem({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.operation,
    required this.data,
    required this.status,
    required this.retryCount,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => SyncQueueItem(
    id: json['id'] as String,
    tableName: json['table_name'] as String,
    recordId: json['record_id'] as String,
    operation: json['operation'] as String,
    data: json['data'] as String,
    status: json['status'] as String,
    retryCount: json['retry_count'] as int? ?? 0,
    errorMessage: json['error_message'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}
