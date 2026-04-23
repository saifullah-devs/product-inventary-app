import 'package:product_inventary_app/core/constants/app_url.dart';
import 'package:product_inventary_app/core/network/network_service.dart';

import '../models/product_model.dart';
import 'product_data_source.dart';

class RestProductDataSource implements IProductDataSource {
  final NetworkClient network;

  RestProductDataSource({required this.network});

  @override
  Future<List<ProductModel>> getAllProducts({
    required int limit,
    required int offset,
  }) async {
    final response = await network.request(
      path: AppUrl.productsEndpoint,
      method: 'GET',
      queryParameters: {'limit': limit, 'offset': offset},
    );

    return (response as List).map((e) => ProductModel.fromJson(e)).toList();
  }

  @override
  Future<ProductModel> getProduct(String id) async {
    final response = await network.request(
      path: AppUrl.productsEndpoint,
      method: 'GET',
      queryParameters: {'id': id},
    );
    return ProductModel.fromJson(response);
  }

  @override
  Future<void> addProduct(ProductModel product) async {
    await network.request(
      path: AppUrl.productsEndpoint,
      method: 'POST',
      body: product.toJson(),
    );
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    await network.request(
      path: '${AppUrl.productsEndpoint}/${product.id}',
      method: 'PUT',
      body: product.toJson(),
    );
  }

  @override
  Future<void> deleteProduct(String id) async {
    await network.request(
      path: '${AppUrl.productsEndpoint}/$id',
      method: 'DELETE',
    );
  }

  @override
  Future<void> addAll(List<ProductModel> products) async {
    await network.request(
      path: '${AppUrl.productsEndpoint}/bulk',
      method: 'POST',
      body: products.map((p) => p.toJson()).toList(),
    );
  }

  @override
  Future<void> deleteAllWithId(List<String> ids) async {
    if (ids.isEmpty) return;

    await network.request(
      path: AppUrl.productsBulkEndpoint,
      method: 'DELETE',
      body: {'ids': ids},
    );
  }
}
