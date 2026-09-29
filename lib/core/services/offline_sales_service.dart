import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pharma_connect/core/services/supabase_service.dart';
import 'package:pharma_connect/modules/pos/models/pos_sale.dart';
import 'package:uuid/uuid.dart';

class OfflineSalesService {
  static final OfflineSalesService _instance = OfflineSalesService._internal();
  factory OfflineSalesService() => _instance;
  OfflineSalesService._internal();

  Database? _database;
  final _uuid = const Uuid();
  final _connectivity = Connectivity();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pharma_connect_offline.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Products cache
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        pharmacy_id TEXT,
        name TEXT,
        price INTEGER,
        stock INTEGER,
        batch_id TEXT,
        last_synced TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Offline sales
    await db.execute('''
      CREATE TABLE offline_sales (
        id TEXT PRIMARY KEY,
        pharmacy_id TEXT,
        cashier_id TEXT,
        sale_data TEXT,
        items_data TEXT,
        total_amount INTEGER,
        created_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Offline receipts
    await db.execute('''
      CREATE TABLE offline_receipts (
        id TEXT PRIMARY KEY,
        sale_id TEXT,
        receipt_number TEXT,
        receipt_data TEXT,
        printed_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  // ---- Connectivity ----

  Future<bool> hasInternet() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // ---- Product Cache ----

  Future<void> cacheProducts(
    String pharmacyId,
    List<Map<String, dynamic>> products,
  ) async {
    final db = await database;
    for (final product in products) {
      await db.insert('products', {
        'id': product['id'],
        'pharmacy_id': pharmacyId,
        'name': product['name'],
        'price': product['price'],
        'stock': product['stock'] ?? 0,
        'batch_id': product['batch_id'],
        'last_synced': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<Map<String, dynamic>>> searchProducts(
    String pharmacyId,
    String query,
  ) async {
    final db = await database;
    return await db.query(
      'products',
      where: 'pharmacy_id = ? AND name LIKE ?',
      whereArgs: [pharmacyId, '%$query%'],
      orderBy: 'name ASC',
    );
  }

  Future<Map<String, dynamic>?> getProduct(
    String pharmacyId,
    String productId,
  ) async {
    final db = await database;
    final results = await db.query(
      'products',
      where: 'pharmacy_id = ? AND id = ?',
      whereArgs: [pharmacyId, productId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateProductStock(
    String pharmacyId,
    String productId,
    int quantity,
  ) async {
    // Cache local SQLite, pas le stock de référence : le décrément serveur
    // d'une vente hors ligne passera par stock_apply_movement à la
    // synchronisation (C195). Même motif rawUpdate que
    // offline_sync_service.dart::markFailed() (Module 4).
    final db = await database;
    await db.rawUpdate(
      'UPDATE products SET stock = stock - ?, updated_at = ? '
      'WHERE pharmacy_id = ? AND id = ?',
      [quantity, DateTime.now().toIso8601String(), pharmacyId, productId],
    );
  }

  // ---- Offline Sales ----

  Future<String> saveOfflineSale({
    required String pharmacyId,
    required String cashierId,
    required POSSale sale,
    required List<Map<String, dynamic>> items,
  }) async {
    final db = await database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await db.insert('offline_sales', {
      'id': id,
      'pharmacy_id': pharmacyId,
      'cashier_id': cashierId,
      'sale_data': jsonEncode(sale.toJson()),
      'items_data': jsonEncode(items),
      'total_amount': sale.finalAmount,
      'created_at': now,
      'synced': 0,
    });

    // Update local product stock
    for (final item in items) {
      await updateProductStock(
        pharmacyId,
        item['product_id']!,
        item['quantity'],
      );
    }

    return id;
  }

  Future<List<Map<String, dynamic>>> getOfflineSales() async {
    final db = await database;
    return await db.query(
      'offline_sales',
      where: 'synced = 0',
      orderBy: 'created_at ASC',
    );
  }

  Future<void> markSaleSynced(String id) async {
    final db = await database;
    await db.update(
      'offline_sales',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteOfflineSale(String id) async {
    final db = await database;
    await db.delete('offline_sales', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Sync ----

  // ATTENTION (C195 / C197) : méthode non appelée. Elle insère directement dans
  // pos_sales et pos_sale_items, sans reçu ni mouvement de stock, et contourne
  // les contrôles serveur. Ne pas la rebrancher telle quelle : la reconstruction
  // de C195 doit passer par la RPC pos_create_sale (une vente = une transaction).
  Future<void> syncOfflineSales() async {
    if (!(await hasInternet())) return;

    final db = await database;
    final sales = await getOfflineSales();
    final client = SupabaseService().client;

    for (final sale in sales) {
      try {
        final saleData =
            jsonDecode(sale['sale_data'] as String) as Map<String, dynamic>;
        final itemsData =
            jsonDecode(sale['items_data'] as String) as List<dynamic>;

        // Create sale online
        final response = await client
            .from('pos_sales')
            .insert(saleData)
            .select()
            .single();

        // Create items
        for (final item in itemsData) {
          item['sale_id'] = response['id'];
          await client.from('pos_sale_items').insert(item);
        }

        // Mark as synced
        await markSaleSynced(sale['id'] as String);
      } catch (e) {
        // Mark as failed if retry count exceeded
        await db.update(
          'offline_sales',
          {'synced': -1, 'error_message': e.toString()},
          where: 'id = ?',
          whereArgs: [sale['id']],
        );
      }
    }
  }
}
