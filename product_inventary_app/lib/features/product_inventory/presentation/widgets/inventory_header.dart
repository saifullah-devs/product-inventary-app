import 'package:flutter/material.dart';
import 'package:product_inventary_app/core/constants/data_source_type.dart';

class InventoryHeader extends StatelessWidget {
  final DataSourceType activeSource;
  final VoidCallback onSourcePicker;

  const InventoryHeader({
    super.key,
    required this.activeSource,
    required this.onSourcePicker,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          title: const Text('Inventory Manager'),
          actions: [
            IconButton(
              icon: const Icon(Icons.storage),
              onPressed: onSourcePicker,
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: _getSourceColor(activeSource).withValues(alpha: 0.1),
            child: Text(
              'ACTIVE SOURCE: ${activeSource.name.toUpperCase()}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _getSourceColor(activeSource),
                fontWeight: FontWeight.bold,
              ),
            ),
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
}
