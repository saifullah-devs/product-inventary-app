import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:product_inventary_app/core/di/injection_container.dart';
import 'package:product_inventary_app/features/product_inventory/domain/entities/product.dart';
import 'package:product_inventary_app/features/product_inventory/presentation/bloc/product_bloc.dart';
import 'package:product_inventary_app/features/product_inventory/presentation/pages/create_product_page.dart';
import 'package:product_inventary_app/features/product_inventory/presentation/pages/product_detail_page.dart';
import 'package:product_inventary_app/features/product_inventory/presentation/pages/product_list_page.dart';

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
      case RoutesName.productDetail:
        final args = settings.arguments as Map<String, dynamic>;
        final product = args['product'] as Product;
        final bloc = args['bloc'] as ProductBloc;

        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value:
                bloc, // Passing the existing bloc instance to the detail page
            child: ProductDetailPage(product: product),
          ),
        );
      case RoutesName.createProduct:
        final bloc = settings.arguments as ProductBloc;
        return MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: bloc, // Passing the existing bloc instance
            child: const CreateProductPage(),
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
