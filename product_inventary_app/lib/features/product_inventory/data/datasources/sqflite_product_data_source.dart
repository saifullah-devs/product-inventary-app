import 'package:sqflite/sqflite.dart';
import 'package:product_inventary_app/core/error/exceptions.dart';
import 'package:product_inventary_app/database/database_helper.dart';

import '../models/product_model.dart';
import 'product_data_source.dart';

class SqfliteProductDataSource implements IProductDataSource {
  final DatabaseHelper dbHelper;
  SqfliteProductDataSource(this.dbHelper);

  @override
  Future<ProductModel> getProduct(String id) async {
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> productMaps = await db.query(
      DatabaseHelper.tableProducts,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (productMaps.isEmpty) {
      throw CacheException();
    }

    return ProductModel.fromJson(productMaps.first);
  }

  @override
  Future<List<ProductModel>> getAllProducts({
    required int limit,
    required int offset,
  }) async {
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> productMaps = await db.query(
      DatabaseHelper.tableProducts,
      limit: limit,
      offset: offset,
    );

    return productMaps.map((map) => ProductModel.fromJson(map)).toList();
  }

  @override
  Future<void> addProduct(ProductModel product) async {
    final db = await dbHelper.database;

    await db.insert(
      DatabaseHelper.tableProducts,
      product.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteProduct(String id) async {
    final db = await dbHelper.database;
    await db.delete(
      DatabaseHelper.tableProducts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteAllWithId(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    final db = await dbHelper.database;

    // Dynamically generate the correct number of placeholders (e.g., "?, ?, ?")
    final placeholders = List.filled(ids.length, '?').join(',');

    await db.delete(
      DatabaseHelper.tableProducts,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  @override
  Future<void> addAll(List<ProductModel> products) async {
    final db = await dbHelper.database;

    Batch batch = db.batch();
    for (var product in products) {
      batch.insert(
        DatabaseHelper.tableProducts,
        product.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> updateProduct(ProductModel product) async => addProduct(product);
}
