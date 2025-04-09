import 'package:sqflite/sqflite.dart';

/// Class to handle database migrations between versions
class DatabaseMigrations {
  // Migration map that defines how to update from one version to the next
  static final Map<int, Future<void> Function(Database)> migrations = {
    1: (db) async {
      // Initial version - no migration needed
    },
    2: migrateV1ToV2,
    3: migrateV2ToV3,
    // Add more migrations as the app evolves
  };

  /// Apply all necessary migrations to upgrade from [oldVersion] to [newVersion]
  static Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    // Run each migration in sequence
    for (int i = oldVersion + 1; i <= newVersion; i++) {
      if (migrations.containsKey(i)) {
        print('Migrating database to version $i');
        await migrations[i]!(db);
      }
    }
  }

  /// Migration from v1 to v2: Add tags field to vouchers
  static Future<void> migrateV1ToV2(Database db) async {
    // Add a new column for tags
    await db.execute('ALTER TABLE vouchers ADD COLUMN tags TEXT');
  }

  /// Migration from v2 to v3: Add favorite field and last_used_date to vouchers
  static Future<void> migrateV2ToV3(Database db) async {
    // Add favorite column
    await db.execute('ALTER TABLE vouchers ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0');
    
    // Add last used date column
    await db.execute('ALTER TABLE vouchers ADD COLUMN last_used_date TEXT');
    
    // Create a new usage history table to track when vouchers are used
    await db.execute('''
      CREATE TABLE voucher_usage_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        voucher_id INTEGER NOT NULL,
        used_date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (voucher_id) REFERENCES vouchers (id) ON DELETE CASCADE
      )
    ''');
  }
}