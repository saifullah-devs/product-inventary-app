import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:product_inventary_app/core/constants/data_source_type.dart';
import 'package:product_inventary_app/core/routes/routes_name.dart';
import '../../domain/entities/product.dart';
import '../bloc/product_bloc.dart';
import '../widgets/inventory_header.dart';
import '../widgets/selection_bottom_bar.dart';
import '../widgets/sliver_product_list.dart';
import '../widgets/source_picker_widget.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isFetchingUI = false;

  // --- Selection State ---
  final Set<String> _selectedIds = {};
  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom && !_isFetchingUI) {
      final currentState = context.read<ProductBloc>().state;
      if (currentState is ProductsLoaded) {
        if (!currentState.isFetchingMore && !currentState.hasReachedMax) {
          // LOCK THE UI SYNCHRONOUSLY
          _isFetchingUI = true;

          context.read<ProductBloc>().add(const LoadAllProductsEvent());
        }
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  // --- Selection Handlers ---
  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductsLoaded) {
            _isFetchingUI = state.isFetchingMore;
          } else if (state is ProductError) {
            _isFetchingUI = false;
          }
        },
        builder: (context, state) {
          if (state is ProductInitial || state is SourceSelectionRequired) {
            return const Center(child: SourcePickerWidget());
          }

          final currentSource = state.activeSource;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // HEADER ALWAYS SHOWS (if we have a source)
              if (currentSource != null)
                InventoryHeader(
                  activeSource: currentSource,
                  onSourcePicker: () => _showSourcePicker(context),
                ),

              // BODY CHANGES BASED ON STATE
              if (state is ProductLoading && !_isSelectionMode)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state is ProductError)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message),
                        ElevatedButton(
                          onPressed: () => _showSourcePicker(context),
                          child: const Text("Change Source"),
                        ),
                      ],
                    ),
                  ),
                )
              else if (state is ProductsLoaded)
                SliverProductList(
                  products: state.products,
                  hasReachedMax: state.hasReachedMax,
                  selectedIds: _selectedIds,
                  onToggleSelection: _toggleSelection,
                  onNavigateDetail: (product) => Navigator.pushNamed(
                    context,
                    RoutesName.productDetail,
                    arguments: product.id,
                  ),
                  onDelete: (product) => _confirmDelete(context, product),
                  onEdit: (product) async {
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
                ),
            ],
          );
        },
      ),

      // Hide FAB when in selection mode
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () async {
                // 1. Await the navigation
                final shouldRefresh = await Navigator.pushNamed(
                  context,
                  RoutesName.createProduct,
                );

                // 2. If the page returns 'true', refresh the list
                if (shouldRefresh == true && context.mounted) {
                  context.read<ProductBloc>().add(
                    const LoadAllProductsEvent(isRefresh: true),
                  );
                }
              },
            ),

      // Show Bulk Actions when in selection mode
      bottomNavigationBar: _selectedIds.isNotEmpty
          ? SelectionBottomBar(
              count: _selectedIds.length,
              onCancel: _clearSelection,
              onTransfer: () => _showTransferDialog(
                context,
                specificIds: _selectedIds.toList(),
                activeSource:
                    context.read<ProductBloc>().state.activeSource ??
                    DataSourceType.rest,
              ),
              onDelete: () => _confirmBulkDelete(context),
            )
          : null,
    );
  }

  void _confirmBulkDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Selected'),
        content: Text(
          'Are you sure you want to delete ${_selectedIds.length} items?',
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
              // Dispatch bulk delete event
              context.read<ProductBloc>().add(
                DeleteProductsByIdEvent(_selectedIds.toList()),
              );
              _clearSelection();
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // 1. Add 'activeSource' as a required parameter
  void _showTransferDialog(
    BuildContext context, {
    List<String>? specificIds,
    required DataSourceType activeSource,
  }) {
    final currentState = context.read<ProductBloc>().state;
    List<String> idsToTransfer = specificIds ?? [];

    if (idsToTransfer.isEmpty && currentState is ProductsLoaded) {
      idsToTransfer = currentState.products.map((p) => p.id).toList();
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          specificIds != null ? "Transfer Selected" : "Migrate All Data",
        ),
        content: Text(
          // Optional: Update the text to show where the data is coming from
          "Transferring ${idsToTransfer.length} items from ${activeSource.name.toUpperCase()}.",
        ),
        actions: [
          // 2. Only show the REST button if we ARE NOT currently on REST
          if (activeSource != DataSourceType.rest)
            TextButton(
              onPressed: () {
                context.read<ProductBloc>().add(
                  TransferDataEvent(
                    productIds: idsToTransfer,
                    from: activeSource, // 3. Use the dynamic source here!
                    to: DataSourceType.rest,
                  ),
                );
                _clearSelection();
                Navigator.pop(dialogContext);
              },
              child: const Text("To REST"),
            ),

          // Only show the HIVE button if we ARE NOT currently on HIVE
          if (activeSource != DataSourceType.hive)
            TextButton(
              onPressed: () {
                context.read<ProductBloc>().add(
                  TransferDataEvent(
                    productIds: idsToTransfer,
                    from: activeSource, // Dynamic source here too
                    to: DataSourceType.hive,
                  ),
                );
                _clearSelection();
                Navigator.pop(dialogContext);
              },
              child: const Text("To HIVE"),
            ),

          // Added SQFLITE target just in case you need it!
          if (activeSource != DataSourceType.sqflite)
            TextButton(
              onPressed: () {
                context.read<ProductBloc>().add(
                  TransferDataEvent(
                    productIds: idsToTransfer,
                    from: activeSource, // Dynamic source
                    to: DataSourceType.sqflite,
                  ),
                );
                _clearSelection();
                Navigator.pop(dialogContext);
              },
              child: const Text("To SQFLITE"),
            ),
        ],
      ),
    );
  }

  void _showSourcePicker(BuildContext context) {
    final productBloc = context.read<ProductBloc>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: productBloc,
        child: const SourcePickerWidget(),
      ),
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
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
