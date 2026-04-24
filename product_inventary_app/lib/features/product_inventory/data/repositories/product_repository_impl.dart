import 'package:dartz/dartz.dart';
import 'package:product_inventary_app/core/shared_preferences/app_preferences.dart';
import 'package:product_inventary_app/core/constants/data_source_type.dart';
import 'package:product_inventary_app/core/error/exceptions.dart';
import 'package:product_inventary_app/core/error/failures.dart';
import '../models/product_model.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_data_source.dart';

class ProductRepositoryImpl implements ProductRepository {
  final IProductDataSource remoteDataSource;
  final IProductDataSource sqfliteDataSource;
  final IProductDataSource hiveDataSource;
  final AppPreferences localPrefs;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.sqfliteDataSource,
    required this.hiveDataSource,
    required this.localPrefs,
  });

  Future<IProductDataSource> _getDataSourceByType(DataSourceType type) async {
    switch (type) {
      case DataSourceType.rest:
        return remoteDataSource;
      case DataSourceType.sqflite:
        return sqfliteDataSource;
      case DataSourceType.hive:
        return hiveDataSource;
    }
  }

  Future<IProductDataSource> _getActiveDataSource() async {
    final type = localPrefs.getActiveSource();
    if (type == null) throw UnselectedSourceException();
    return _getDataSourceByType(type);
  }

  // --- CRUD Operations ---
  @override
  Future<Either<Failure, List<Product>>> getAllProducts({
    required int limit,
    required int offset,
  }) async {
    try {
      final dataSource = await _getActiveDataSource();
      final models = await dataSource.getAllProducts(
        limit: limit,
        offset: offset,
      );
      return Right(models);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, Product>> getProduct(String id) async {
    try {
      final dataSource = await _getActiveDataSource();
      final model = await dataSource.getProduct(id);
      return Right(model);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> createProduct(Product product) async {
    try {
      final dataSource = await _getActiveDataSource();
      await dataSource.addProduct(ProductModel.fromEntity(product));
      return const Right(null);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(Product product) async {
    try {
      final dataSource = await _getActiveDataSource();
      await dataSource.updateProduct(ProductModel.fromEntity(product));
      return const Right(null);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      final dataSource = await _getActiveDataSource();
      await dataSource.deleteProduct(id);
      return const Right(null);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProductsbyID(List<String> ids) async {
    try {
      final dataSource = await _getActiveDataSource();
      await dataSource.deleteAllWithId(ids);
      return const Right(null);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  // --- Source Management ---

  @override
  Future<Either<Failure, void>> setActiveDataSource(DataSourceType type) async {
    try {
      await localPrefs.setActiveSource(type);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DataSourceType?>> getActiveDataSource() async {
    try {
      return Right(localPrefs.getActiveSource());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // --- Data Migration (Cross-Source Transfer) ---
  @override
  Future<Either<Failure, void>> transferData({
    required List<String> productIds,
    required DataSourceType from,
    required DataSourceType to,
  }) async {
    try {
      if (productIds.isEmpty) return const Right(null);

      // 1. Resolve source and destination strategies
      final source = await _getDataSourceByType(from);
      final destination = await _getDataSourceByType(to);

      // 2. Fetch targeted data from the source database
      List<ProductModel> productsToTransfer = [];
      for (String id in productIds) {
        final product = await source.getProduct(id);
        productsToTransfer.add(product);
      }

      // 3. Push the targeted data to the destination via atomic bulk insert
      await destination.addAll(productsToTransfer);

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure("Transfer Failed: ${e.toString()}"));
    }
  }

  Failure _handleException(dynamic e) {
    if (e is UnselectedSourceException) return UnselectedSourceFailure();
    if (e is ServerException) return const ServerFailure();
    if (e is CacheException) return const CacheFailure();
    return UnknownFailure(e.toString());
  }
}
