import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:product_inventary_app/core/constants/data_source_type.dart';
import 'package:product_inventary_app/core/routes/routes_name.dart';
import '../bloc/product_bloc.dart';
import '../widgets/source_picker_widget.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_alt),
            onPressed: () => _showTransferDialog(context),
          ),
          // Source Switcher
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: () => _showSourcePicker(context),
          ),
        ],
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductInitial || state is SourceSelectionRequired) {
            return const Center(child: SourcePickerWidget());
          }
          if (state is ProductLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProductsLoaded) {
            return _buildProductList(state);
          }
          if (state is ProductError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(
            context,
            RoutesName.createProduct,
            arguments: context.read<ProductBloc>(), // Pass the bloc here!
          );
        },
      ),
    );
  }

  void _showSourcePicker(BuildContext context) {
    // 1. Capture the existing bloc from the current context
    final productBloc = context.read<ProductBloc>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // 2. Wrap the widget with BlocProvider.value
      builder: (_) => BlocProvider.value(
        value: productBloc,
        child: const SourcePickerWidget(),
      ),
    );
  }

  Widget _buildProductList(ProductsLoaded state) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          color: _getSourceColor(state.activeSource).withValues(alpha: .1),
          child: Text(
            'ACTIVE SOURCE: ${state.activeSource.name.toUpperCase()}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _getSourceColor(state.activeSource),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: state.products.length,
            itemBuilder: (context, index) {
              final product = state.products[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text('${product.category} • ${product.priceRange}'),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    RoutesName.productDetail,
                    arguments: {
                      'product': product,
                      'bloc': context.read<ProductBloc>(),
                    },
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => context.read<ProductBloc>().add(
                    DeleteProductEvent(product.id),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getSourceColor(DataSourceType type) {
    switch (type) {
      case DataSourceType.rest:
        return Colors.blue;
      case DataSourceType.sqflite:
        return Colors.orange;
      case DataSourceType.hive:
        return Colors.purple;
    }
  }

  void _showTransferDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Migrate Data"),
        content: const Text("Select target source to copy current data into."),
        actions: [
          TextButton(
            onPressed: () {
              // Example: Transfer from SQflite to REST
              context.read<ProductBloc>().add(
                const TransferDataEvent(
                  from: DataSourceType.sqflite,
                  to: DataSourceType.rest,
                ),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text("SQL to REST"),
          ),
          // Add other permutations as needed
        ],
      ),
    );
  }
}
