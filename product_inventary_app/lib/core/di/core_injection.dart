import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:product_inventary_app/features/product_inventory/data/models/product_model_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:hive/hive.dart';
import '../shared_preferences/app_preferences.dart';
import '../../database/database_helper.dart';
import '../network/network_service.dart';

Future<void> init(GetIt sl) async {
  // --- External ---
  final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);

  Hive.registerAdapter(ProductModelAdapter());

  sl.registerLazySingleton(() => Hive);
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPrefs);
  sl.registerLazySingleton(() => http.Client());

  // --- Core ---
  sl.registerLazySingleton(() => AppPreferences(sl()));
  sl.registerLazySingleton(() => DatabaseHelper());

  sl.registerLazySingleton(() => NetworkClient(sl()));
}
