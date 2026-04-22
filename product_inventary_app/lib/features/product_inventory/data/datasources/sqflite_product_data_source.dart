import 'dart:convert';
import 'package:product_inventary_app/core/error/exceptions.dart';
import 'package:product_inventary_app/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

import '../models/product_model.dart';
import '../models/product_variant_model.dart';
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

    final pMap = productMaps.first;

    final List<Map<String, dynamic>> variantMaps = await db.query(
      DatabaseHelper.tableVariants,
      where: 'product_id = ?',
      whereArgs: [id],
    );

    final variants = variantMaps
        .map(
          (v) => ProductVariantModel(
            id: v['id'],
            sku: v['sku'],
            price: v['price'],
            comparePrice: v['compare_price'],
            stockQuantity: v['stock_quantity'],
            // Attributes are stored as a JSON string in SQflite
            attributes: Map<String, String>.from(jsonDecode(v['attributes'])),
          ),
        )
        .toList();

    return ProductModel(
      id: pMap['id'],
      name: pMap['name'],
      description: pMap['description'],
      category: pMap['category'],
      basePrice: pMap['base_price'],
      baseComparePrice: pMap['base_compare_price'],
      images: (pMap['images'] as String).split(','),
      variants: variants,
    );
  }

  @override
  Future<List<ProductModel>> getAllProducts() async {
    final db = await dbHelper.database;

    // Fetch all products
    final List<Map<String, dynamic>> productMaps = await db.query(
      DatabaseHelper.tableProducts,
    );

    List<ProductModel> products = [];

    for (var pMap in productMaps) {
      // Fetch variants for each product
      final List<Map<String, dynamic>> variantMaps = await db.query(
        DatabaseHelper.tableVariants,
        where: 'product_id = ?',
        whereArgs: [pMap['id']],
      );

      final variants = variantMaps
          .map(
            (v) => ProductVariantModel(
              id: v['id'],
              sku: v['sku'],
              price: v['price'],
              comparePrice: v['compare_price'],
              stockQuantity: v['stock_quantity'],
              attributes: Map<String, String>.from(jsonDecode(v['attributes'])),
            ),
          )
          .toList();

      products.add(
        ProductModel(
          id: pMap['id'],
          name: pMap['name'],
          description: pMap['description'],
          category: pMap['category'],
          basePrice: pMap['base_price'],
          baseComparePrice: pMap['base_compare_price'],
          images: (pMap['images'] as String).split(','),
          variants: variants,
        ),
      );
    }
    return products;
  }

  @override
  Future<void> addProduct(ProductModel product) async {
    final db = await dbHelper.database;

    await db.transaction((txn) async {
      // 1. Insert Product
      await txn.insert(DatabaseHelper.tableProducts, {
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'category': product.category,
        'base_price': product.basePrice,
        'base_compare_price': product.baseComparePrice,
        'images': product.images.join(','),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // 2. Insert Variants
      for (var variant in product.variants) {
        await txn.insert(
          DatabaseHelper.tableVariants,
          {
            'id': variant.id,
            'product_id': product.id,
            'sku': variant.sku,
            'price': variant.price,
            'compare_price': variant.comparePrice,
            'stock_quantity': variant.stockQuantity,
            'attributes': jsonEncode(variant.attributes),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
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
  Future<void> deleteAll() async {
    final db = await dbHelper.database;
    await db.delete(DatabaseHelper.tableProducts);
    await db.delete(DatabaseHelper.tableVariants);
  }

  @override
  Future<void> addAll(List<ProductModel> products) async {
    for (var product in products) {
      await addProduct(product);
    }
  }

  @override
  Future<void> updateProduct(ProductModel product) async => addProduct(product);
}
