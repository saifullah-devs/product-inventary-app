import 'package:get_it/get_it.dart';
import 'package:product_inventary_app/core/di/core_injection.dart' as core_di;
import 'package:product_inventary_app/features/product_inventory/product_injection.dart'
    as product_di;

final sl = GetIt.instance;

Future<void> init() async {
  await core_di.init(sl);
  await product_di.init(sl);
}
