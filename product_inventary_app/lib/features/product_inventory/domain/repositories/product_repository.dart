import 'package:dartz/dartz.dart';
import 'package:product_inventary_app/core/constants/data_source_type.dart';
import 'package:product_inventary_app/core/error/failures.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  // Product CRUD
  Future<Either<Failure, List<Product>>> getAllProducts();
  Future<Either<Failure, Product>> getProduct(String id);
  Future<Either<Failure, void>> createProduct(Product product);
  Future<Either<Failure, void>> updateProduct(Product product);
  Future<Either<Failure, void>> deleteProduct(String id);

  // Source & Strategy Management
  Future<Either<Failure, void>> setActiveDataSource(DataSourceType type);
  Future<Either<Failure, DataSourceType?>> getActiveDataSource();

  // Data Migration/Transfer
  Future<Either<Failure, void>> transferData({
    required DataSourceType from,
    required DataSourceType to,
  });
}
