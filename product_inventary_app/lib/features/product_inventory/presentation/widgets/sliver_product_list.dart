import 'package:flutter/material.dart';

import '../../domain/entities/product.dart';
import 'product_card_widget.dart';

class SliverProductList extends StatelessWidget {
  final List<Product> products;
  final bool hasReachedMax;
  final Set<String> selectedIds;
  final Function(String) onToggleSelection;
  final Function(Product) onNavigateDetail;
  final Function(Product) onDelete;
  final Function(Product) onEdit;

  const SliverProductList({
    super.key,
    required this.products,
    required this.hasReachedMax,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.onNavigateDetail,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 80, top: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index >= products.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final product = products[index];
          final isSelectionMode = selectedIds.isNotEmpty;

          return ProductCard(
            product: product,
            isSelectionMode: isSelectionMode,
            isSelected: selectedIds.contains(product.id),
            onLongPress: () => onToggleSelection(product.id),
            onTap: () => isSelectionMode
                ? onToggleSelection(product.id)
                : onNavigateDetail(product),
            onDelete: () => isSelectionMode
                ? onToggleSelection(product.id)
                : onDelete(product),
            onEdit: () => isSelectionMode
                ? onToggleSelection(product.id)
                : onEdit(product),
          );
        }, childCount: hasReachedMax ? products.length : products.length + 1),
      ),
    );
  }
}
