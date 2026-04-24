import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:product_inventary_app/core/routes/routes_name.dart';

import '../bloc/product_bloc.dart';
import '../../domain/entities/product.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId; // Now accepts ONLY the ID

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(GetProductDetailEvent(widget.productId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading || state is ProductInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProductError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => context.read<ProductBloc>().add(
                          GetProductDetailEvent(widget.productId),
                        ),
                        child: const Text('Refresh'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Return'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          if (state is ProductDetailLoaded) {
            return _buildDetailContent(context, state.product);
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final currencyFormat = NumberFormat.currency(
      symbol: 'PKR',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat.yMMMMd().add_jm();

    final hasDiscount =
        product.comparePrice != null && product.comparePrice! > product.price;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Hero(
                      tag: 'product_icon_${product.id}',
                      child: product.imageUrl.isNotEmpty
                          ? Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      size: 100,
                                      color: colorScheme.primary.withValues(
                                        alpha: .5,
                                      ),
                                    ),
                                  ),
                            )
                          : Center(
                              child: Icon(
                                Icons.inventory_2_rounded,
                                size: 100,
                                color: colorScheme.primary.withValues(
                                  alpha: .5,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Category ---
                      Text(
                        product.category.toUpperCase(),
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // --- Title & Stock Badge ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          _buildStockBadge(context, product.stockQuantity),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // --- Price & Compare Price ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              currencyFormat.format(product.price),
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                currencyFormat.format(product.comparePrice),
                                style: textTheme.headlineMedium?.copyWith(
                                  color: hasDiscount
                                      ? colorScheme.error
                                      : colorScheme.primary,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 32),

                      // --- Description ---
                      Text(
                        'Description',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const Divider(height: 64),

                      // --- System Information ---
                      Text(
                        'System Information',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Added SKU to metadata
                      _buildMetadataRow(
                        context,
                        icon: Icons.qr_code_2,
                        label: 'SKU',
                        value: product.sku,
                      ),
                      const SizedBox(height: 12),
                      _buildMetadataRow(
                        context,
                        icon: Icons.fingerprint,
                        label: 'Product ID',
                        value: product.id,
                      ),
                      const SizedBox(height: 12),
                      _buildMetadataRow(
                        context,
                        icon: Icons.calendar_today_outlined,
                        label: 'Created At',
                        value: dateFormat.format(product.createdAt),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- Bottom Action Bar ---
        BottomAppBar(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _confirmDelete(context, product),
                icon: Icon(Icons.delete_outline, color: colorScheme.error),
                label: Text(
                  'Delete',
                  style: TextStyle(color: colorScheme.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.error),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () async {
                  // 1. Await the navigation
                  final shouldRefresh = await Navigator.pushNamed(
                    context,
                    RoutesName.updateProduct,
                    arguments: product.id,
                  );

                  // 2. If the page returns 'true', refresh the list
                  if (shouldRefresh == true && context.mounted) {
                    context.read<ProductBloc>().add(
                      const LoadAllProductsEvent(isRefresh: true),
                    );
                  }
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Product'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStockBadge(BuildContext context, int stockQuantity) {
    final theme = Theme.of(context);
    Color badgeColor = stockQuantity > 10
        ? Colors.green
        : (stockQuantity > 0 ? Colors.orange : theme.colorScheme.error);
    String badgeText = stockQuantity > 10
        ? 'In Stock ($stockQuantity)'
        : (stockQuantity > 0 ? 'Low Stock ($stockQuantity)' : 'Out of Stock');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        badgeText,
        style: theme.textTheme.labelMedium?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetadataRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to permanently delete "${product.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ProductBloc>().add(DeleteProductEvent(product.id));
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
