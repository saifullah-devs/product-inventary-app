import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_variant.dart';
import '../bloc/product_bloc.dart';

class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final _formKey = GlobalKey<FormState>();

  // Base Controllers
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _basePriceCtrl = TextEditingController();
  final _comparePriceCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();

  // Dynamic State
  final List<String> _images = [];
  final List<ProductVariant> _variants = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    _basePriceCtrl.dispose();
    _comparePriceCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  void _addImage() {
    if (_imageUrlCtrl.text.isNotEmpty) {
      setState(() {
        _images.add(_imageUrlCtrl.text.trim());
        _imageUrlCtrl.clear();
      });
    }
  }

  void _addDefaultVariant() {
    // A real-world safety measure: SQflite requires at least one variant for relational integrity
    final basePrice = double.tryParse(_basePriceCtrl.text) ?? 0.0;
    final comparePrice = double.tryParse(_comparePriceCtrl.text) ?? 0.0;
    final skuBase = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text.replaceAll(' ', '-').toUpperCase()
        : 'SKU';

    setState(() {
      _variants.add(
        ProductVariant(
          id: "v-${DateTime.now().millisecondsSinceEpoch}",
          sku: "$skuBase-${_variants.length + 1}",
          attributes: const {"Size": "Default"},
          price: basePrice,
          comparePrice: comparePrice,
          stockQuantity: 10,
        ),
      );
    });
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      if (_variants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please add at least one variant.",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final newProduct = Product(
        id: "p-${DateTime.now().millisecondsSinceEpoch}",
        images: _images.isNotEmpty
            ? _images
            : ["https://via.placeholder.com/150"],
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        basePrice: double.tryParse(_basePriceCtrl.text) ?? 0.0,
        baseComparePrice: double.tryParse(_comparePriceCtrl.text) ?? 0.0,
        variants: _variants,
      );

      context.read<ProductBloc>().add(AddProductEvent(newProduct));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("General Information"),
              _buildTextField(_nameCtrl, "Product Name"),
              _buildTextField(_categoryCtrl, "Category"),
              _buildTextField(_descCtrl, "Description", maxLines: 3),
              const SizedBox(height: 24),

              _buildSectionTitle("Pricing"),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _basePriceCtrl,
                      "Base Price",
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      _comparePriceCtrl,
                      "Compare Price",
                      isNumber: true,
                      isRequired: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle("Images"),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _imageUrlCtrl,
                      decoration: InputDecoration(
                        labelText: "Image URL",
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.add_photo_alternate,
                      color: Colors.blue,
                      size: 32,
                    ),
                    onPressed: _addImage,
                  ),
                ],
              ),
              if (_images.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: _images
                      .map(
                        (url) => Chip(
                          label: const Text(
                            "Image Added",
                            style: TextStyle(fontSize: 12),
                          ),
                          onDeleted: () => setState(() => _images.remove(url)),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle("Variants (${_variants.length})"),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Add Default Variant"),
                    onPressed: _addDefaultVariant,
                  ),
                ],
              ),
              _buildVariantsList(),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _onSave,
                  child: const Text(
                    "Create Product",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label, {
    int maxLines = 1,
    bool isNumber = false,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        validator: isRequired
            ? (val) => val == null || val.isEmpty ? "Required field" : null
            : null,
      ),
    );
  }

  Widget _buildVariantsList() {
    if (_variants.isEmpty) {
      return const Text(
        "No variants added. A product must have at least one variant.",
        style: TextStyle(color: Colors.red),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _variants.length,
      itemBuilder: (context, index) {
        final variant = _variants[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(variant.sku),
            subtitle: Text(
              "Price: \$${variant.price} | Stock: ${variant.stockQuantity}",
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => setState(() => _variants.removeAt(index)),
            ),
          ),
        );
      },
    );
  }
}
