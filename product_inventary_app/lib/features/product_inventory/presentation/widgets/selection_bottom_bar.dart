import 'package:flutter/material.dart';

class SelectionBottomBar extends StatelessWidget {
  final int count;
  final VoidCallback onCancel;
  final VoidCallback onTransfer;
  final VoidCallback onDelete;

  const SelectionBottomBar({
    super.key,
    required this.count,
    required this.onCancel,
    required this.onTransfer,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          ),
          TextButton.icon(
            onPressed: onTransfer,
            icon: const Icon(Icons.sync_alt),
            label: const Text('Transfer'),
          ),
          TextButton.icon(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            label: Text('Delete', style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );
  }
}
