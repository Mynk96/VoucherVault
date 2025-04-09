import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../lib/models/voucher.dart';
import '../lib/models/category.dart';
import '../lib/services/database_service.dart';
import '../lib/utils/database_debug.dart';

void main() {
  // Setup sqflite_common_ffi for testing
  late DatabaseService databaseService;
  late DatabaseFactory databaseFactory;
  late String testDbPath;

  setUpAll(() {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory for testing
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Create a database instance with a unique test path
    testDbPath = inMemoryDatabasePath;
    
    // Create a mock database service that uses the in-memory database
    databaseService = TestDatabaseService(testDbPath);
    await databaseService.init();
  });

  tearDown(() async {
    // Delete the test database
    await databaseFactory.deleteDatabase(testDbPath);
  });

  group('Database Operations', () {
    test('Create and retrieve category', () async {
      // Create a test category
      final category = Category(
        name: 'Test Category',
        color: '#FF0000',
        iconCodePoint: 0xe123,
        iconFontFamily: 'MaterialIcons',
      );
      
      // Insert category
      final id = await databaseService.insertCategory(category);
      expect(id, isPositive);
      
      // Retrieve category
      final retrievedCategory = await databaseService.getCategory(id);
      expect(retrievedCategory, isNotNull);
      expect(retrievedCategory!.name, equals('Test Category'));
      expect(retrievedCategory.color, equals('#FF0000'));
    });

    test('Create and retrieve voucher', () async {
      // Create a test voucher
      final voucher = Voucher(
        code: 'TEST123',
        description: 'Test Voucher',
        store: 'Test Store',
        discountAmount: 10.0,
        discountType: 'percentage',
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        tags: ['test', 'sample'],
      );
      
      // Insert voucher
      final id = await databaseService.insertVoucher(voucher);
      expect(id, isPositive);
      
      // Retrieve voucher
      final retrievedVoucher = await databaseService.getVoucher(id);
      expect(retrievedVoucher, isNotNull);
      expect(retrievedVoucher!.code, equals('TEST123'));
      expect(retrievedVoucher.description, equals('Test Voucher'));
      expect(retrievedVoucher.tags.length, equals(2));
      expect(retrievedVoucher.tags.contains('test'), isTrue);
    });

    test('Update voucher', () async {
      // Create a test voucher
      final voucher = Voucher(
        code: 'UPDATE123',
        description: 'Original Description',
        store: 'Test Store',
        discountAmount: 10.0,
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );
      
      // Insert voucher
      final id = await databaseService.insertVoucher(voucher);
      
      // Retrieve voucher, modify, and update
      final retrievedVoucher = await databaseService.getVoucher(id);
      final updatedVoucher = retrievedVoucher!.copyWith(
        description: 'Updated Description',
        isFavorite: true,
      );
      
      final success = await databaseService.updateVoucher(updatedVoucher);
      expect(success, isTrue);
      
      // Retrieve again and check for updates
      final afterUpdateVoucher = await databaseService.getVoucher(id);
      expect(afterUpdateVoucher!.description, equals('Updated Description'));
      expect(afterUpdateVoucher.isFavorite, isTrue);
    });

    test('Delete voucher', () async {
      // Create a test voucher
      final voucher = Voucher(
        code: 'DELETE123',
        description: 'To Be Deleted',
        store: 'Test Store',
        discountAmount: 10.0,
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );
      
      // Insert voucher
      final id = await databaseService.insertVoucher(voucher);
      
      // Delete voucher
      final success = await databaseService.deleteVoucher(id);
      expect(success, isTrue);
      
      // Try to retrieve deleted voucher
      final retrievedVoucher = await databaseService.getVoucher(id);
      expect(retrievedVoucher, isNull);
    });

    test('Mark voucher as used', () async {
      // Create a test voucher
      final voucher = Voucher(
        code: 'USETEST123',
        description: 'Usage Test',
        store: 'Test Store',
        discountAmount: 15.0,
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );
      
      // Insert voucher
      final id = await databaseService.insertVoucher(voucher);
      
      // Mark as used with notes
      final success = await databaseService.markVoucherAsUsed(
        id, 
        notes: 'Used for testing',
      );
      expect(success, isTrue);
      
      // Check voucher status
      final retrievedVoucher = await databaseService.getVoucher(id);
      expect(retrievedVoucher!.isUsed, isTrue);
      expect(retrievedVoucher.lastUsedDate, isNotNull);
      
      // Check usage history
      final usageHistory = await databaseService.getVoucherUsageHistory(id);
      expect(usageHistory.length, equals(1));
      expect(usageHistory.first['notes'], equals('Used for testing'));
    });

    test('Toggle favorite status', () async {
      // Create a test voucher
      final voucher = Voucher(
        code: 'FAVORITE123',
        description: 'Favorite Test',
        store: 'Test Store',
        discountAmount: 20.0,
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        isFavorite: false,
      );
      
      // Insert voucher
      final id = await databaseService.insertVoucher(voucher);
      
      // Toggle favorite
      final success = await databaseService.toggleVoucherFavorite(id);
      expect(success, isTrue);
      
      // Check favorite status
      final retrievedVoucher = await databaseService.getVoucher(id);
      expect(retrievedVoucher!.isFavorite, isTrue);
      
      // Toggle again
      await databaseService.toggleVoucherFavorite(id);
      final retrievedAgain = await databaseService.getVoucher(id);
      expect(retrievedAgain!.isFavorite, isFalse);
    });

    test('Search vouchers', () async {
      // Create test vouchers
      await databaseService.insertVoucher(Voucher(
        code: 'SEARCH1',
        description: 'First search test',
        store: 'Store A',
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      ));
      
      await databaseService.insertVoucher(Voucher(
        code: 'SEARCH2',
        description: 'Second search test',
        store: 'Store B',
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        tags: ['test', 'search'],
      ));
      
      await databaseService.insertVoucher(Voucher(
        code: 'OTHER',
        description: 'Not in search',
        store: 'Store C',
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      ));
      
      // Search by code
      final codeResults = await databaseService.searchVouchers('SEARCH');
      expect(codeResults.length, equals(2));
      
      // Search by tag
      final tagResults = await databaseService.getVouchersByTag('test');
      expect(tagResults.length, equals(1));
      expect(tagResults.first.code, equals('SEARCH2'));
      
      // Search by store
      final storeResults = await databaseService.searchVouchers('Store B');
      expect(storeResults.length, equals(1));
      expect(storeResults.first.store, equals('Store B'));
    });

    test('Get voucher statistics', () async {
      final now = DateTime.now();
      
      // Create various test vouchers
      // Active
      await databaseService.insertVoucher(Voucher(
        code: 'ACTIVE1',
        description: 'Active voucher',
        store: 'Store A',
        expiryDate: now.add(const Duration(days: 30)),
      ));
      
      // Expiring soon
      await databaseService.insertVoucher(Voucher(
        code: 'EXPIRING1',
        description: 'Expiring soon',
        store: 'Store B',
        expiryDate: now.add(const Duration(days: 3)),
      ));
      
      // Expired
      await databaseService.insertVoucher(Voucher(
        code: 'EXPIRED1',
        description: 'Expired voucher',
        store: 'Store C',
        expiryDate: now.subtract(const Duration(days: 10)),
      ));
      
      // Used
      final usedVoucher = Voucher(
        code: 'USED1',
        description: 'Used voucher',
        store: 'Store D',
        expiryDate: now.add(const Duration(days: 15)),
      );
      final usedId = await databaseService.insertVoucher(usedVoucher);
      await databaseService.markVoucherAsUsed(usedId);
      
      // Favorite
      await databaseService.insertVoucher(Voucher(
        code: 'FAV1',
        description: 'Favorite voucher',
        store: 'Store E',
        expiryDate: now.add(const Duration(days: 20)),
        isFavorite: true,
      ));
      
      // Get statistics
      final stats = await databaseService.getVoucherStatistics();
      
      expect(stats['total'], equals(5));
      expect(stats['active'], equals(3)); // ACTIVE1, EXPIRING1, FAV1
      expect(stats['expired'], equals(1)); // EXPIRED1
      expect(stats['used'], equals(1)); // USED1
      expect(stats['expiringSoon'], equals(1)); // EXPIRING1
      expect(stats['favorites'], equals(1)); // FAV1
    });
  });
}

/// Test version of DatabaseService that uses a test-specific database path
class TestDatabaseService extends DatabaseService {
  final String _testDbPath;
  
  TestDatabaseService(this._testDbPath);
  
  @override
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // Open the database with migration support
      _database = await openDatabase(
        _testDbPath,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      
      _isInitialized = true;
      
      // Initialize default categories if needed
      await _initializeDefaultCategories();
    } catch (e) {
      print('Error initializing test database: $e');
      rethrow;
    }
  }
}