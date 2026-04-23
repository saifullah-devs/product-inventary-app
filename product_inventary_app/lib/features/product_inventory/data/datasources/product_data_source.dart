import '../models/product_model.dart';

abstract class IProductDataSource {
  Future<List<ProductModel>> getAllProducts({
    required int limit,
    required int offset,
  });

  Future<ProductModel> getProduct(String id);
  Future<void> addProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);

  // Bulk operations
  Future<void> deleteAllWithId(List<String> ids);
  Future<void> addAll(List<ProductModel> products);
}
