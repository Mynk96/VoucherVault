import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/voucher.dart';
import '../models/category.dart';
import '../services/database_service.dart';

/// Utility class to initialize and populate the database for development purposes
class DatabaseInitializer {
  final DatabaseService _databaseService;
  
  DatabaseInitializer(this._databaseService);
  
  /// Reset and recreate the database
  Future<void> resetDatabase() async {
    if (!await _confirmDatabaseReset()) return;
    
    print('Resetting database...');
    
    // Delete the database file
    final dbPath = await _databaseService.getDatabasePath();
    final dbFile = File(dbPath);
    
    if (await dbFile.exists()) {
      await dbFile.delete();
      print('Database file deleted.');
    }
    
    // Reinitialize the database
    await _databaseService.init();
    print('Database reinitialized with schema version ${DatabaseService._databaseVersion}');
    
    // Initialize with sample data
    await _initializeSampleData();
  }
  
  /// Initialize the database with sample categories and vouchers
  Future<void> _initializeSampleData() async {
    print('Adding sample data...');
    
    // Get already initialized categories
    final existingCategories = await _databaseService.getCategories();
    
    // Add sample vouchers
    final now = DateTime.now();
    
    // Sample vouchers for demo purposes
    final sampleVouchers = [
      Voucher(
        code: 'WELCOME25',
        description: '25% off your first order',
        store: 'SuperMart',
        discountAmount: 25,
        discountType: 'percentage',
        expiryDate: now.add(const Duration(days: 30)),
        categoryId: existingCategories[0].id, // Food & Drink
        tags: ['groceries', 'welcome'],
        isFavorite: true,
      ),
      Voucher(
        code: 'MOVIE50',
        description: 'Buy 1 ticket get 1 free',
        store: 'CineWorld',
        discountAmount: 50,
        discountType: 'percentage',
        expiryDate: now.add(const Duration(days: 15)),
        categoryId: existingCategories[3].id, // Entertainment
        tags: ['movies', 'entertainment'],
      ),
      Voucher(
        code: 'TRAVEL100',
        description: '\$100 off any booking over \$500',
        store: 'TravelWise',
        discountAmount: 100,
        discountType: 'fixed',
        expiryDate: now.add(const Duration(days: 60)),
        categoryId: existingCategories[2].id, // Travel
        tags: ['travel', 'vacation'],
      ),
      Voucher(
        code: 'SUMMER20',
        description: '20% off summer collection',
        store: 'Fashion World',
        discountAmount: 20,
        discountType: 'percentage',
        expiryDate: now.add(const Duration(days: 5)),
        categoryId: existingCategories[1].id, // Shopping
        tags: ['clothes', 'summer', 'discount'],
      ),
      Voucher(
        code: 'COFFEE10',
        description: '10% off any coffee',
        store: 'Coffee Express',
        discountAmount: 10,
        discountType: 'percentage',
        expiryDate: now.subtract(const Duration(days: 10)), // Expired
        categoryId: existingCategories[0].id, // Food & Drink
        tags: ['coffee', 'drinks'],
      ),
      Voucher(
        code: 'BDAY25',
        description: '25% off for your birthday',
        store: 'GiftMaster',
        discountAmount: 25,
        discountType: 'percentage',
        expiryDate: now.add(const Duration(days: 90)),
        categoryId: existingCategories[4].id, // Other
        tags: ['gifts', 'birthday'],
        isFavorite: true,
      ),
    ];
    
    // Create a used voucher
    final usedVoucher = Voucher(
      code: 'LUNCH15',
      description: '15% off lunch menu',
      store: 'Cafe Deluxe',
      discountAmount: 15,
      discountType: 'percentage',
      expiryDate: now.add(const Duration(days: 14)),
      categoryId: existingCategories[0].id, // Food & Drink
      tags: ['lunch', 'food'],
      isUsed: true,
      lastUsedDate: now.subtract(const Duration(days: 2)),
    );
    
    // Insert vouchers
    for (final voucher in [...sampleVouchers, usedVoucher]) {
      final id = await _databaseService.insertVoucher(voucher);
      print('Added sample voucher with ID: $id');
      
      // Add usage history for the used voucher
      if (voucher.isUsed && voucher.lastUsedDate != null) {
        await _databaseService.markVoucherAsUsed(
          id, 
          notes: 'Used during sample data initialization',
        );
      }
    }
    
    print('Sample data added successfully!');
  }
  
  Future<bool> _confirmDatabaseReset() async {
    if (!kDebugMode) {
      print('⚠️ WARNING: Database reset is only available in debug mode');
      return false;
    }
    
    print('⚠️ WARNING: This will delete all data in the database.');
    print('Are you sure you want to reset the database? (y/n)');
    
    final response = stdin.readLineSync()?.toLowerCase() ?? 'n';
    return response == 'y' || response == 'yes';
  }
}

/// Command line tool to initialize the database
void main() async {
  print('Voucher Manager - Database Initializer');
  print('======================================');
  
  print('Initializing database service...');
  final databaseService = DatabaseService();
  await databaseService.init();
  
  print('Creating initializer...');
  final initializer = DatabaseInitializer(databaseService);
  
  print('Ready. Select an option:');
  print('1. Reset database and add sample data');
  print('2. Show database statistics');
  print('3. Exit');
  
  final option = stdin.readLineSync();
  
  switch (option) {
    case '1':
      await initializer.resetDatabase();
      break;
    case '2':
      final stats = await databaseService.getVoucherStatistics();
      print('Database Statistics:');
      print('- Total vouchers: ${stats['total']}');
      print('- Active vouchers: ${stats['active']}');
      print('- Expired vouchers: ${stats['expired']}');
      print('- Used vouchers: ${stats['used']}');
      print('- Expiring soon: ${stats['expiringSoon']}');
      print('- Favorites: ${stats['favorites']}');
      
      final categories = await databaseService.getCategories();
      print('- Categories: ${categories.length}');
      
      final dbPath = await databaseService.getDatabasePath();
      print('- Database path: $dbPath');
      break;
    default:
      print('Exiting...');
  }
  
  exit(0);
}