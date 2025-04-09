import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/voucher.dart';
import '../models/category.dart';
import '../services/database_service.dart';

/// A utility class for database debugging and management
class DatabaseDebugUtil {
  final DatabaseService _databaseService;

  DatabaseDebugUtil(this._databaseService);

  /// Get the database file path
  Future<String> getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, DatabaseService._databaseName);
  }

  /// Get database file size in KB
  Future<double> getDatabaseSize() async {
    final path = await getDatabasePath();
    final file = File(path);
    if (await file.exists()) {
      final bytes = await file.length();
      return bytes / 1024; // Convert to KB
    }
    return 0;
  }

  /// Export database to a JSON string for debugging
  Future<Map<String, dynamic>> exportDatabaseToJson() async {
    final vouchersData = await _databaseService.getVouchers();
    final categoriesData = await _databaseService.getCategories();

    return {
      'vouchers': vouchersData.map((v) => v.toMap()).toList(),
      'categories': categoriesData.map((c) => c.toMap()).toList(),
    };
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final voucherCount = (await _databaseService.getVouchers()).length;
    final categoryCount = (await _databaseService.getCategories()).length;
    final dbSize = await getDatabaseSize();

    return {
      'voucherCount': voucherCount,
      'categoryCount': categoryCount,
      'databaseSizeKB': dbSize.toStringAsFixed(2),
    };
  }

  /// Get all active tables in the database
  Future<List<String>> getTableNames() async {
    final path = await getDatabasePath();
    final db = await openDatabase(path);
    
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'");
      
      return tables.map((t) => t['name'] as String).toList();
    } finally {
      await db.close();
    }
  }

  /// Get the structure of a specific table
  Future<List<Map<String, dynamic>>> getTableStructure(String tableName) async {
    final path = await getDatabasePath();
    final db = await openDatabase(path);
    
    try {
      return await db.rawQuery("PRAGMA table_info($tableName)");
    } finally {
      await db.close();
    }
  }

  /// Execute a raw SQL query (for debugging purposes only)
  Future<List<Map<String, dynamic>>> executeRawQuery(String sql, [List<dynamic>? arguments]) async {
    final path = await getDatabasePath();
    final db = await openDatabase(path);
    
    try {
      return await db.rawQuery(sql, arguments);
    } finally {
      await db.close();
    }
  }

  /// Backup the database to external storage
  Future<String> backupDatabase() async {
    final dbPath = await getDatabasePath();
    final dbFile = File(dbPath);
    
    if (!await dbFile.exists()) {
      throw Exception('Database file does not exist');
    }
    
    final documentsDir = await getApplicationDocumentsDirectory();
    final backupPath = join(documentsDir.path, 
        'voucher_manager_backup_${DateTime.now().millisecondsSinceEpoch}.db');
    
    try {
      // Copy the database file to the backup location
      await dbFile.copy(backupPath);
      return backupPath;
    } catch (e) {
      throw Exception('Failed to backup database: $e');
    }
  }

  /// Restore the database from a backup file
  Future<void> restoreDatabase(String backupPath) async {
    final dbPath = await getDatabasePath();
    final backupFile = File(backupPath);
    
    if (!await backupFile.exists()) {
      throw Exception('Backup file does not exist');
    }
    
    try {
      // Close the database before restoring
      final db = await openDatabase(dbPath);
      await db.close();
      
      // Copy the backup file to the database location
      await backupFile.copy(dbPath);
    } catch (e) {
      throw Exception('Failed to restore database: $e');
    }
  }

  /// Delete all data from a specific table
  Future<int> clearTable(String tableName) async {
    final path = await getDatabasePath();
    final db = await openDatabase(path);
    
    try {
      return await db.delete(tableName);
    } finally {
      await db.close();
    }
  }

  /// Reset the entire database (delete and recreate)
  Future<void> resetDatabase() async {
    final path = await getDatabasePath();
    await deleteDatabase(path);
    
    // Reinitialize the database
    await _databaseService.init();
  }
}