import 'package:hive/hive.dart';
import 'package:product_inventary_app/core/error/exceptions.dart';
import '../models/product_model.dart';
import 'product_data_source.dart';

class HiveProductDataSource implements IProductDataSource {
  static const String boxName = 'products_box';
  final HiveInterface hive;

  HiveProductDataSource(this.hive);

  Future<Box> _getBox() async {
    return await hive.openBox(boxName);
  }

  @override
  Future<List<ProductModel>> getAllProducts() async {
    final box = await _getBox();
    return box.values.map((item) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(item);
      return ProductModel.fromJson(map);
    }).toList();
  }

  @override
  Future<ProductModel> getProduct(String id) async {
    final box = await _getBox();
    final data = box.get(id);

    if (data == null) {
      throw CacheException();
    }

    return ProductModel.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<void> addProduct(ProductModel product) async {
    final box = await _getBox();
    await box.put(product.id, product.toJson());
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
  Future<void> deleteAll() async {
    final box = await _getBox();
    await box.clear();
  }

  @override
  Future<void> addAll(List<ProductModel> products) async {
    final box = await _getBox();
    final Map<String, dynamic> dataMap = {
      for (var p in products) p.id: p.toJson(),
    };
    await box.putAll(dataMap);
  }
}
