import 'package:hive/hive.dart';
import 'package:product_inventary_app/core/error/exceptions.dart';
import '../models/product_model.dart';
import 'product_data_source.dart';
import 'package:uuid/uuid.dart';

class HiveProductDataSource implements IProductDataSource {
  static const String boxName = 'products_box';
  final HiveInterface hive;
  final Uuid uuid = const Uuid();
  HiveProductDataSource(this.hive);

  Future<Box<ProductModel>> _getBox() async {
    return await hive.openBox<ProductModel>(boxName);
  }

  @override
  Future<List<ProductModel>> getAllProducts({
    required int limit,
    required int offset,
  }) async {
    final box = await _getBox();

    return box.values.skip(offset).take(limit).toList();
  }

  @override
  Future<ProductModel> getProduct(String id) async {
    final box = await _getBox();
    final product = box.get(id);

    if (product == null) {
      throw CacheException();
    }

    return product;
  }

  @override
  Future<void> addProduct(ProductModel product) async {
    final box = await _getBox();

    // 1. Check if the product has no ID
    String finalId = product.id;
    ProductModel productToSave = product;

    if (finalId.isEmpty) {
      // 2. Generate a new unique ID
      finalId = uuid.v4();

      // 3. Update the model with the new ID
      // (Assuming your ProductModel has a copyWith method. If not,
      // you will need to create a new ProductModel instance here).
      productToSave = product.copyWith(id: finalId);
    }

    // 4. Save to Hive using the guaranteed unique ID
    await box.put(finalId, productToSave);
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    await addProduct(product);
  }

  @override
  Future<void> deleteProduct(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  @override
  Future<void> deleteAllWithId(List<String> ids) async {
    if (ids.isEmpty) return;

    final box = await _getBox();
    await box.deleteAll(ids);
  }

  @override
  Future<void> addAll(List<ProductModel> products) async {
    final box = await _getBox();

    // Create an empty map to store our processed products
    final Map<String, ProductModel> dataMap = {};

    for (var product in products) {
      String finalId = product.id;
      ProductModel productToSave = product;

      if (finalId.isEmpty) {
        finalId = uuid.v4();
        productToSave = product.copyWith(id: finalId);
      }

      dataMap[finalId] = productToSave;
    }

    await box.putAll(dataMap);
  }
}
