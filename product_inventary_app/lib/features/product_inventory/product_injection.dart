import 'package:get_it/get_it.dart';
import 'data/datasources/sqflite_product_data_source.dart';
import 'data/datasources/hive_product_data_source.dart';
import 'data/datasources/rest_product_data_source.dart';
import 'data/repositories/product_repository_impl.dart';
import 'domain/repositories/product_repository.dart';
import 'domain/usecases/create_product_usecase.dart';
import 'domain/usecases/delete_product_usecase.dart';
import 'domain/usecases/delete_products_by_id.dart';
import 'domain/usecases/get_active_source_usecase.dart';
import 'domain/usecases/get_all_products_usecase.dart';
import 'domain/usecases/get_products_usecase.dart';
import 'domain/usecases/set_active_source_usecase.dart';
import 'domain/usecases/transfer_product_data_usecase.dart';
import 'domain/usecases/update_product_usecase.dart';
import 'presentation/bloc/product_bloc.dart';

Future<void> init(GetIt sl) async {
  // --- BLoC ---
  sl.registerFactory(
    () => ProductBloc(
      getAllProducts: sl(),
      getProduct: sl(),
      createProduct: sl(),
      updateProduct: sl(),
      deleteProduct: sl(),
      setActiveSource: sl(),
      getActiveSource: sl(),
      transferProductData: sl(),
      deleteProductsById: sl(),
    ),
  );
  // --- Use Cases ---
  sl.registerLazySingleton(() => GetAllProductsUseCase(sl()));
  sl.registerLazySingleton(() => GetProductUseCase(sl()));
  sl.registerLazySingleton(() => CreateProductUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
  sl.registerLazySingleton(() => DeleteProductUseCase(sl()));
  sl.registerLazySingleton(() => DeleteProductsByIdUseCase(sl()));

  // Source Management & Migration
  sl.registerLazySingleton(() => SetActiveDataSourceUseCase(sl()));
  sl.registerLazySingleton(() => GetActiveDataSourceUseCase(sl()));
  sl.registerLazySingleton(() => TransferDataUseCase(sl()));

  // --- Repository ---
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDataSource: sl<RestProductDataSource>(),
      sqfliteDataSource: sl<SqfliteProductDataSource>(),
      hiveDataSource: sl<HiveProductDataSource>(),
      localPrefs: sl(),
    ),
  );

  // --- Data Sources ---
  sl.registerLazySingleton(() => RestProductDataSource(network: sl()));
  sl.registerLazySingleton(() => SqfliteProductDataSource(sl()));
  sl.registerLazySingleton(() => HiveProductDataSource(sl()));
}
