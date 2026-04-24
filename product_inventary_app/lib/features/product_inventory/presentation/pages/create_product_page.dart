import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/product.dart';
import '../bloc/product_bloc.dart';

class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for input fields
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _priceController = TextEditingController();
  final _comparePriceController = TextEditingController();
  final _stockController = TextEditingController();

  // Focus nodes for smooth keyboard navigation
  final _categoryFocus = FocusNode();
  final _skuFocus = FocusNode();
  final _descFocus = FocusNode();
  final _imageUrlFocus = FocusNode();
  final _priceFocus = FocusNode();
  final _comparePriceFocus = FocusNode();
  final _stockFocus = FocusNode();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _priceController.dispose();
    _comparePriceController.dispose();
    _stockController.dispose();

    _categoryFocus.dispose();
    _skuFocus.dispose();
    _descFocus.dispose();
    _imageUrlFocus.dispose();
    _priceFocus.dispose();
    _comparePriceFocus.dispose();
    _stockFocus.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      // Handle optional compare price
      final comparePriceText = _comparePriceController.text.trim();
      final double? parsedComparePrice = comparePriceText.isNotEmpty
          ? double.tryParse(comparePriceText)
          : null;

      // Create the entity from form data
      final newProduct = Product(
        // In a real production app, use the 'uuid' package here: const Uuid().v4()
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        sku: _skuController.text
            .trim()
            .toUpperCase(), // Standardize SKU to uppercase
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        comparePrice: parsedComparePrice,
        stockQuantity: int.parse(_stockController.text.trim()),
        createdAt: DateTime.now(),
      );

      // Dispatch event to BLoC
      context.read<ProductBloc>().add(AddProductEvent(newProduct));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (_isSubmitting) {
          if (state is ProductsLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Product created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is ProductError) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Add New Product')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // --- Product Name ---
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_categoryFocus),
              ),
              const SizedBox(height: 16),

              // --- Category & SKU (Row Layout) ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      focusNode: _categoryFocus,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Required'
                          : null,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_skuFocus),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _skuController,
                      focusNode: _skuFocus,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'SKU',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code_2),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Required'
                          : null,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_descFocus),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Image URL ---
              TextFormField(
                controller: _imageUrlController,
                focusNode: _imageUrlFocus,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image_outlined),
                  hintText: 'https://example.com/image.png',
                ),
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_priceFocus),
              ),
              const SizedBox(height: 16),

              // --- Price & Compare Price (Row Layout) ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      focusNode: _priceFocus,
                      textInputAction: TextInputAction.next,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) return 'Invalid';
                        return null;
                      },
                      onFieldSubmitted: (_) => FocusScope.of(
                        context,
                      ).requestFocus(_comparePriceFocus),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _comparePriceController,
                      focusNode: _comparePriceFocus,
                      textInputAction: TextInputAction.next,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Compare at Price',
                        hintText: 'Optional',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.money_off),
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (double.tryParse(value) == null) return 'Invalid';
                        }
                        return null; // Valid because it's optional
                      },
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_stockFocus),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Stock ---
              TextFormField(
                controller: _stockController,
                focusNode: _stockFocus,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
                onFieldSubmitted: (_) => _submitForm(),
              ),
              const SizedBox(height: 16),

              // --- Description ---
              TextFormField(
                controller: _descriptionController,
                focusNode: _descFocus,
                textInputAction: TextInputAction.next,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_imageUrlFocus),
              ),
              const SizedBox(height: 32),

              // --- Submit Button ---
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isSubmitting ? 'Saving...' : 'Save Product',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
