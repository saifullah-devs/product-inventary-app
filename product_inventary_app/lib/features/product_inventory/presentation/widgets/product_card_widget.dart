import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  // Selection properties
  final bool isSelectionMode;
  final bool isSelected;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(
      symbol: 'PKR ',
      decimalDigits: 2,
    );

    return Card(
      elevation: isSelected ? 3 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          // Highlight border if selected
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        focusColor: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- The Checkbox ---
              if (isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onTap(),
                  activeColor: colorScheme.primary,
                ),
                const SizedBox(width: 8.0),
              ],

              // 1. Leading Image / Icon with Hero tag
              Hero(
                tag: 'product_icon_${product.id}',
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  // Dynamically show image if URL exists, else fallback to icon
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.broken_image_rounded,
                            color: colorScheme.primary.withValues(alpha: 0.5),
                            size: 32,
                          ),
                        )
                      : Icon(
                          Icons.inventory_2_rounded,
                          color: colorScheme.primary,
                          size: 32,
                        ),
                ),
              ),
              const SizedBox(width: 16.0),

              // 2. Main Content (Category, Name, SKU, Stock)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category label
                    Text(
                      product.category.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    // Product Name
                    Text(
                      product.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    // SKU
                    Text(
                      'SKU: ${product.sku}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8.0),
                    _buildStockBadge(context),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),

              // 3. Trailing (Prices & Actions)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Optional Compare Price (Strikethrough)
                  if (product.comparePrice != null &&
                      product.comparePrice! > product.price)
                    Text(
                      currencyFormat.format(product.comparePrice),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  // Actual Price
                  Text(
                    currencyFormat.format(product.price),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color:
                          product.comparePrice != null &&
                              product.comparePrice! > product.price
                          ? colorScheme
                                .error // Highlight discounted price
                          : colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8.0),

                  // Dropdown menu for edit/delete actions
                  if (!isSelectionMode && (onEdit != null || onDelete != null))
                    SizedBox(
                      height: 32,
                      width: 32,
                      child: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          if (value == 'edit' && onEdit != null) onEdit!();
                          if (value == 'delete' && onDelete != null) {
                            onDelete!();
                          }
                        },
                        itemBuilder: (context) => [
                          if (onEdit != null)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                          if (onDelete != null)
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: colorScheme.error),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a dynamic badge based on the stock level
  Widget _buildStockBadge(BuildContext context) {
    final theme = Theme.of(context);

    Color badgeColor;
    String badgeText;

    if (product.stockQuantity > 10) {
      badgeColor = Colors.green;
      badgeText = 'In Stock: ${product.stockQuantity}';
    } else if (product.stockQuantity > 0) {
      badgeColor = Colors.orange;
      badgeText = 'Low Stock: ${product.stockQuantity}';
    } else {
      badgeColor = theme.colorScheme.error;
      badgeText = 'Out of Stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        badgeText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
