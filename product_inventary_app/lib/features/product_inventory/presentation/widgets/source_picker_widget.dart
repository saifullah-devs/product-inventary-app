import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:product_inventary_app/core/constants/data_source_type.dart';

import '../bloc/product_bloc.dart';

class SourcePickerWidget extends StatelessWidget {
  const SourcePickerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Select Initial Data Source",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _sourceTile(
            context,
            "REST API (Cloud)",
            Icons.cloud,
            DataSourceType.rest,
          ),
          _sourceTile(
            context,
            "SQflite (Relational)",
            Icons.table_rows,
            DataSourceType.sqflite,
          ),
          _sourceTile(
            context,
            "Hive (NoSQL)",
            Icons.topic,
            DataSourceType.hive,
          ),
        ],
      ),
    );
  }

  Widget _sourceTile(
    BuildContext context,
    String title,
    IconData icon,
    DataSourceType type,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        onTap: () => context.read<ProductBloc>().add(SelectSourceEvent(type)),
      ),
    );
  }
}
