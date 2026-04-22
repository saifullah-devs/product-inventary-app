import 'package:product_inventary_app/core/network/network_service.dart';

import '../models/product_model.dart';
import 'product_data_source.dart';

class RestProductDataSource implements IProductDataSource {
  final NetworkClient network;

  RestProductDataSource({required this.network});

  @override
  Future<List<ProductModel>> getAllProducts() async {
    final response = await network.request(path: '/products', method: 'GET');
    return (response as List).map((e) => ProductModel.fromJson(e)).toList();
  }

  @override
  Future<ProductModel> getProduct(String id) async {
    final response = await network.request(
      path: '/products/$id',
      method: 'GET',
    );
    return ProductModel.fromJson(response);
  }

  @override
  Future<void> addProduct(ProductModel product) async {
    await network.request(
      path: '/products',
      method: 'POST',
      body: product.toJson(),
    );
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    await network.request(
      path: '/products/${product.id}',
      method: 'PUT',
      body: product.toJson(),
    );
  }

  @override
  Future<void> deleteProduct(String id) async {
    await network.request(path: '/products/$id', method: 'DELETE');
  }

  /// Industrial Batch Operations
  @override
  Future<void> addAll(List<ProductModel> products) async {
    // Standard approach: Send a list to a bulk endpoint
    await network.request(
      path: '/products/bulk',
      method: 'POST',
      body: products.map((p) => p.toJson()).toList(),
    );
  }

  @override
  Future<void> deleteAll() async {
    // Caution: Usually requires high-level permissions
    // await network.request(path: '/products', method: 'DELETE');
  }
}
