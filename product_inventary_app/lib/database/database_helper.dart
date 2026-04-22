import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _dbName = 'app_database.db';
  static const _dbVersion = 1;

  static const tableProducts = 'products';
  static const tableVariants = 'product_variants';

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future _onCreate(Database db, int version) async {
    // Products Table
    await db.execute('''
      CREATE TABLE $tableProducts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT,
        images TEXT, -- Stored as comma-separated strings or JSON
        base_price REAL,
        base_compare_price REAL
      )
    ''');

    // Variants Table
    await db.execute('''
      CREATE TABLE $tableVariants (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        sku TEXT,
        price REAL,
        compare_price REAL,
        stock_quantity INTEGER,
        attributes TEXT, -- Stored as JSON string
        FOREIGN KEY (product_id) REFERENCES $tableProducts (id) ON DELETE CASCADE
      )
    ''');
  }
}
