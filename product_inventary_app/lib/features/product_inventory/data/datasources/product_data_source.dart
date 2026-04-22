import '../models/product_model.dart';

abstract class IProductDataSource {
  Future<List<ProductModel>> getAllProducts();
  Future<ProductModel> getProduct(String id);
  Future<void> addProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);

  // Bulk operations for Transfer/Migration
  Future<void> deleteAll();
  Future<void> addAll(List<ProductModel> products);
}
