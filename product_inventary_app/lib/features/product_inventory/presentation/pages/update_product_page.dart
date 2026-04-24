import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/product.dart';
import '../bloc/product_bloc.dart';

class UpdateProductPage extends StatefulWidget {
  final String productId;

  const UpdateProductPage({super.key, required this.productId});

  @override
  State<UpdateProductPage> createState() => _UpdateProductPageState();
}

class _UpdateProductPageState extends State<UpdateProductPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _comparePriceController = TextEditingController();
  final _stockController = TextEditingController();

  // Focus nodes
  final _categoryFocus = FocusNode();
  final _skuFocus = FocusNode();
  final _descFocus = FocusNode();
  final _imageUrlFocus = FocusNode();
  final _priceFocus = FocusNode();
  final _comparePriceFocus = FocusNode();
  final _stockFocus = FocusNode();

  bool _isSubmitting = false;
  bool _isInitialized = false;

  Product? _originalProduct;

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(GetProductDetailEvent(widget.productId));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _comparePriceController.dispose();
    _stockController.dispose();

    _categoryFocus.dispose();
    _skuFocus.dispose();
    _descFocus.dispose();
    _priceFocus.dispose();
    _comparePriceFocus.dispose();
    _stockFocus.dispose();
    super.dispose();
  }

  /// Populates the text fields only once when the data arrives
  void _initializeControllers(Product product) {
    _originalProduct = product;
    _nameController.text = product.name;
    _categoryController.text = product.category;
    _skuController.text = product.sku;
    _descriptionController.text = product.description;
    _imageUrlController.text = product.imageUrl;
    _priceController.text = product.price.toString();
    _comparePriceController.text = product.comparePrice?.toString() ?? '';
    _stockController.text = product.stockQuantity.toString();
    _isInitialized = true;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _originalProduct != null) {
      setState(() => _isSubmitting = true);

      final comparePriceText = _comparePriceController.text.trim();
      final double? parsedComparePrice = comparePriceText.isNotEmpty
          ? double.tryParse(comparePriceText)
          : null;

      // Construct the updated entity, preserving the original ID and createdAt
      final updatedProduct = Product(
        id: _originalProduct!.id,
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        sku: _skuController.text.trim().toUpperCase(),
        description: _descriptionController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        comparePrice: parsedComparePrice,
        stockQuantity: int.parse(_stockController.text.trim()),
        createdAt: _originalProduct!.createdAt,
      );

      // Dispatch update event
      context.read<ProductBloc>().add(UpdateProductEvent(updatedProduct));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Product')),
      // BlocConsumer allows us to simultaneously listen for state changes (to populate fields or navigate)
      // and build the UI based on the current state.
      body: BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) {
          // 1. Data Arrived: Populate controllers safely
          if (state is ProductDetailLoaded && !_isInitialized) {
            _initializeControllers(state.product);
          }

          // 2. Submission Response
          if (_isSubmitting) {
            if (state is ProductsLoaded) {
              // Success: The BLoC completed the update and refreshed.
              // We pop and return TRUE so the underlying detail page knows to refresh too.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context, true);
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
        builder: (context, state) {
          // Show loader while fetching the initial data
          if (state is ProductLoading ||
              (state is ProductDetailLoaded && !_isInitialized)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProductError && !_isInitialized) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  TextButton(
                    onPressed: () => context.read<ProductBloc>().add(
                      GetProductDetailEvent(widget.productId),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Render the form once initialized
          if (_isInitialized) {
            return _buildForm(context);
          }

          return const SizedBox();
        },
      ),
    );
  }

  // Extracted to keep the build method clean. This is structurally identical to your Create page.
  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const SizedBox(height: 24),
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
                      value == null || value.trim().isEmpty ? 'Required' : null,
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
                      value == null || value.trim().isEmpty ? 'Required' : null,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_descFocus),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _imageUrlController,
            focusNode: _imageUrlFocus,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Image URL',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.image_outlined),
            ),
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_priceFocus),
          ),
          const SizedBox(height: 16),

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
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
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
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_comparePriceFocus),
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
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
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
                    return null;
                  },
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_stockFocus),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
                FocusScope.of(context).requestFocus(_descFocus),
          ),
          const SizedBox(height: 32),

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
                _isSubmitting ? 'Saving...' : 'Update Product',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
