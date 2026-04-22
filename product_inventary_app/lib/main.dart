import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/di/injection_container.dart' as di;
import 'core/routes/routes.dart';
import 'core/routes/routes_name.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clean Architecture Flutter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: RoutesName.allProducts,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
