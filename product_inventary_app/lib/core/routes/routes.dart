import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:product_inventary_app/core/di/injection_container.dart';
import 'package:product_inventary_app/features/product_inventory/presentation/bloc/product_bloc.dart';
import 'package:product_inventary_app/features/product_inventory/presentation/pages/create_product_page.dart';
import 'package:product_inventary_app/features/product_inventory/presentation/pages/product_detail_page.dart';
import 'package:product_inventary_app/features/product_inventory/presentation/pages/product_list_page.dart';
import 'package:product_inventary_app/features/product_inventory/presentation/pages/update_product_page.dart';

import 'routes_name.dart';

class AppRoutes {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RoutesName.allProducts:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<ProductBloc>()..add(CheckInitialSourceEvent()),
            child: const ProductListPage(),
          ),
        );
      case RoutesName.createProduct:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<ProductBloc>(),
            child: const CreateProductPage(),
          ),
        );

      case RoutesName.updateProduct:
        final productId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<ProductBloc>(),
            child: UpdateProductPage(productId: productId),
          ),
        );

      case RoutesName.productDetail:
        final productId = settings.arguments as String;

        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<ProductBloc>(),
            child: ProductDetailPage(productId: productId),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
