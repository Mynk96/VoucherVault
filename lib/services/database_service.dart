import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/voucher.dart';
import '../models/category.dart';

class DatabaseService {
  static const String _databaseName = 'voucher_manager.db';
  static const int _databaseVersion = 1;
  
  // Tables
  static const String vouchersTable = 'vouchers';
  static const String categoriesTable = 'categories';
  
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  
  factory DatabaseService() {
    return _instance;
  }
  
  DatabaseService._internal();
  
  late Database _database;
  
  Future<void> init() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
    
    // Initialize default categories if needed
    await _initializeDefaultCategories();
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // Create vouchers table
    await db.execute('''
      CREATE TABLE $vouchersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL,
        description TEXT NOT NULL,
        store TEXT NOT NULL,
        discount_amount REAL NOT NULL,
        discount_type TEXT NOT NULL,
        created_date TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        category_id INTEGER,
        image_url TEXT,
        is_used INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES $categoriesTable (id) ON DELETE SET NULL
      )
    ''');
    
    // Create categories table
    await db.execute('''
      CREATE TABLE $categoriesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        icon_code_point INTEGER NOT NULL,
        icon_font_family TEXT NOT NULL
      )
    ''');
  }
  
  Future<void> _initializeDefaultCategories() async {
    final existingCategories = await getCategories();
    
    if (existingCategories.isEmpty) {
      // Insert default categories
      for (final category in defaultCategories) {
        await insertCategory(category);
      }
    }
  }
  
  // Voucher CRUD operations
  Future<List<Voucher>> getVouchers() async {
    final List<Map<String, dynamic>> maps = await _database.query(vouchersTable);
    
    return List.generate(maps.length, (i) {
      return Voucher.fromMap(maps[i]);
    });
  }
  
  Future<Voucher?> getVoucher(int id) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      vouchersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Voucher.fromMap(maps.first);
    }
    
    return null;
  }
  
  Future<int> insertVoucher(Voucher voucher) async {
    return await _database.insert(
      vouchersTable,
      voucher.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<bool> updateVoucher(Voucher voucher) async {
    if (voucher.id == null) {
      return false;
    }
    
    final count = await _database.update(
      vouchersTable,
      voucher.toMap(),
      where: 'id = ?',
      whereArgs: [voucher.id],
    );
    
    return count > 0;
  }
  
  Future<bool> deleteVoucher(int id) async {
    final count = await _database.delete(
      vouchersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    return count > 0;
  }
  
  // Category CRUD operations
  Future<List<Category>> getCategories() async {
    final List<Map<String, dynamic>> maps = await _database.query(categoriesTable);
    
    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }
  
  Future<Category?> getCategory(int id) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      categoriesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    
    return null;
  }
  
  Future<int> insertCategory(Category category) async {
    return await _database.insert(
      categoriesTable,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<bool> updateCategory(Category category) async {
    if (category.id == null) {
      return false;
    }
    
    final count = await _database.update(
      categoriesTable,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    
    return count > 0;
  }
  
  Future<bool> deleteCategory(int id) async {
    // First, update all vouchers with this category to have null category
    await _database.update(
      vouchersTable,
      {'category_id': null},
      where: 'category_id = ?',
      whereArgs: [id],
    );
    
    // Then delete the category
    final count = await _database.delete(
      categoriesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    return count > 0;
  }
  
  // Advanced queries
  Future<List<Voucher>> getVouchersByCategory(int categoryId) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      vouchersTable,
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    
    return List.generate(maps.length, (i) {
      return Voucher.fromMap(maps[i]);
    });
  }
  
  Future<List<Voucher>> searchVouchers(String query) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      vouchersTable,
      where: 'code LIKE ? OR description LIKE ? OR store LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    
    return List.generate(maps.length, (i) {
      return Voucher.fromMap(maps[i]);
    });
  }
  
  Future<List<Voucher>> getExpiringVouchers(int daysThreshold) async {
    final now = DateTime.now();
    final thresholdDate = now.add(Duration(days: daysThreshold));
    
    final List<Map<String, dynamic>> maps = await _database.rawQuery('''
      SELECT * FROM $vouchersTable 
      WHERE expiry_date BETWEEN ? AND ? 
      AND is_used = 0
    ''', [
      now.toIso8601String().substring(0, 10),
      thresholdDate.toIso8601String().substring(0, 10),
    ]);
    
    return List.generate(maps.length, (i) {
      return Voucher.fromMap(maps[i]);
    });
  }
}
