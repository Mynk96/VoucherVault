import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/voucher.dart';
import '../models/category.dart' as app_category;
import 'database_migrations.dart';

class DatabaseService {
  static const String _databaseName = 'voucher_manager.db';
  static const int _databaseVersion = 3; // Increased version to support migrations
  
  // Tables
  static const String vouchersTable = 'vouchers';
  static const String categoriesTable = 'categories';
  static const String usageHistoryTable = 'voucher_usage_history';
  
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  
  factory DatabaseService() {
    return _instance;
  }
  
  DatabaseService._internal();
  
  late Database _database;
  bool _isInitialized = false;
  
  // Getter for the database
  Database get database {
    if (!_isInitialized) {
      throw StateError('Database not initialized. Call init() first.');
    }
    return _database;
  }
  
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);
      
      // Open the database with migration support
      _database = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) {
          debugPrint('Database opened successfully');
        },
      );
      
      _isInitialized = true;
      
      // Initialize default categories if needed
      await _initializeDefaultCategories();
      
      debugPrint('Database initialized successfully');
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }
  
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('Creating database at version $version');
    
    // Create categories table first (needed for foreign key references)
    await db.execute('''
      CREATE TABLE $categoriesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        icon_code_point INTEGER NOT NULL,
        icon_font_family TEXT NOT NULL
      )
    ''');
    
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
        tags TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        last_used_date TEXT,
        FOREIGN KEY (category_id) REFERENCES $categoriesTable (id) ON DELETE SET NULL
      )
    ''');
    
    // Create usage history table
    await db.execute('''
      CREATE TABLE $usageHistoryTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        voucher_id INTEGER NOT NULL,
        used_date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (voucher_id) REFERENCES $vouchersTable (id) ON DELETE CASCADE
      )
    ''');
    
    // Enable foreign key support
    await db.execute('PRAGMA foreign_keys = ON');
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from $oldVersion to $newVersion');
    await DatabaseMigrations.migrate(db, oldVersion, newVersion);
  }
  
  Future<void> _initializeDefaultCategories() async {
    final existingCategories = await getCategories();
    
    if (existingCategories.isEmpty) {
      debugPrint('Initializing default categories');
      // Insert default categories
      for (final category in app_category.defaultCategories) {
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
  Future<List<app_category.Category>> getCategories() async {
    final List<Map<String, dynamic>> maps = await _database.query(categoriesTable);
    
    return List.generate(maps.length, (i) {
      return app_category.Category.fromMap(maps[i]);
    });
  }
  
  Future<app_category.Category?> getCategory(int id) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      categoriesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return app_category.Category.fromMap(maps.first);
    }
    
    return null;
  }
  
  Future<int> insertCategory(app_category.Category category) async {
    return await _database.insert(
      categoriesTable,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  Future<bool> updateCategory(app_category.Category category) async {
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
      orderBy: 'expiry_date ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Voucher.fromMap(maps[i]);
    });
  }
  
  Future<List<Voucher>> searchVouchers(String query) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      vouchersTable,
      where: 'code LIKE ? OR description LIKE ? OR store LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'expiry_date ASC',
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
      ORDER BY expiry_date ASC
    ''', [
      now.toIso8601String().substring(0, 10),
      thresholdDate.toIso8601String().substring(0, 10),
    ]);
    
    return List.generate(maps.length, (i) {
      return Voucher.fromMap(maps[i]);
    });
  }
  
  // New methods for additional features
  Future<List<Voucher>> getFavoriteVouchers() async {
    final List<Map<String, dynamic>> maps = await _database.query(
      vouchersTable,
      where: 'is_favorite = 1',
      orderBy: 'expiry_date ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Voucher.fromMap(maps[i]);
    });
  }
  
  Future<List<Voucher>> getVouchersByTag(String tag) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      vouchersTable,
      where: 'tags LIKE ?',
      whereArgs: ['%$tag%'],
      orderBy: 'expiry_date ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Voucher.fromMap(maps[i]);
    });
  }
  
  Future<bool> toggleVoucherFavorite(int id) async {
    // Get the current voucher
    final voucher = await getVoucher(id);
    if (voucher == null) return false;
    
    // Toggle favorite status
    final updatedVoucher = voucher.toggleFavorite();
    return await updateVoucher(updatedVoucher);
  }
  
  Future<bool> markVoucherAsUsed(int id, {String? notes}) async {
    // Get the current voucher
    final voucher = await getVoucher(id);
    if (voucher == null) return false;
    
    // Create a transaction to update voucher and add usage history
    final now = DateTime.now();
    
    // Begin transaction
    await _database.transaction((txn) async {
      // Update voucher
      await txn.update(
        vouchersTable,
        {
          'is_used': 1,
          'last_used_date': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      // Add usage history record
      await txn.insert(
        usageHistoryTable,
        {
          'voucher_id': id,
          'used_date': now.toIso8601String(),
          'notes': notes,
        },
      );
    });
    
    return true;
  }
  
  Future<List<Map<String, dynamic>>> getVoucherUsageHistory(int voucherId) async {
    return await _database.query(
      usageHistoryTable,
      where: 'voucher_id = ?',
      whereArgs: [voucherId],
      orderBy: 'used_date DESC',
    );
  }
  
  // Get vouchers statistics
  Future<Map<String, dynamic>> getVoucherStatistics() async {
    final now = DateTime.now();
    
    // Total vouchers
    final totalVouchers = Sqflite.firstIntValue(
      await _database.rawQuery('SELECT COUNT(*) FROM $vouchersTable')
    ) ?? 0;
    
    // Used vouchers
    final usedVouchers = Sqflite.firstIntValue(
      await _database.rawQuery('SELECT COUNT(*) FROM $vouchersTable WHERE is_used = 1')
    ) ?? 0;
    
    // Expired vouchers
    final expiredVouchers = Sqflite.firstIntValue(
      await _database.rawQuery(
        'SELECT COUNT(*) FROM $vouchersTable WHERE expiry_date < ? AND is_used = 0', 
        [now.toIso8601String().substring(0, 10)]
      )
    ) ?? 0;
    
    // Active vouchers
    final activeVouchers = Sqflite.firstIntValue(
      await _database.rawQuery(
        'SELECT COUNT(*) FROM $vouchersTable WHERE expiry_date >= ? AND is_used = 0', 
        [now.toIso8601String().substring(0, 10)]
      )
    ) ?? 0;
    
    // Expiring soon (next 7 days)
    final expiringVouchers = Sqflite.firstIntValue(
      await _database.rawQuery(
        '''SELECT COUNT(*) FROM $vouchersTable 
           WHERE expiry_date BETWEEN ? AND ? AND is_used = 0''', 
        [
          now.toIso8601String().substring(0, 10),
          now.add(const Duration(days: 7)).toIso8601String().substring(0, 10)
        ]
      )
    ) ?? 0;
    
    // Favorite vouchers
    final favoriteVouchers = Sqflite.firstIntValue(
      await _database.rawQuery('SELECT COUNT(*) FROM $vouchersTable WHERE is_favorite = 1')
    ) ?? 0;
    
    return {
      'total': totalVouchers,
      'used': usedVouchers,
      'expired': expiredVouchers,
      'active': activeVouchers,
      'expiringSoon': expiringVouchers,
      'favorites': favoriteVouchers,
    };
  }
  
  // Utility method to get the database file path
  Future<String> getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, _databaseName);
  }
}
