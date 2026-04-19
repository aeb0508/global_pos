import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../providers/app_settings_provider.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';
import '../widgets/product_image_widget.dart';
import '../widgets/modern_dropdown.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  final String? initialSearch;
  const ProductsScreen({super.key, this.initialSearch});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> _products = [];
  List<Category> _categories = [];
  List<Map<String, dynamic>> _suppliers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategoryId;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  // Pagination
  int _currentPage = 0;
  final int _itemsPerPage = 20;
  bool _isLoadingMore = false;
  bool _hasMoreItems = true;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialSearch ?? '';
    _searchController.text = _searchQuery;
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  void _loadMoreProducts() {
    if (_isLoadingMore || !_hasMoreItems) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          // Check if we've loaded all filtered products
          final filtered = _filteredProducts;
          _hasMoreItems = (_currentPage + 1) * _itemsPerPage < filtered.length;
        });
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadProducts(), _loadCategories(), _loadSuppliers()]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadProducts() async {
    try {
      final response = await ApiService.get(ApiConfig.productsEndpoint);
      if (response['success'] == true) {
        setState(() {
          _products = (response['data'] as List)
              .map((json) => Product.fromJson(json))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadCategories() async {
    try {
      final response = await ApiService.get(ApiConfig.categoriesEndpoint);
      if (response['success']) {
        setState(() {
          _categories = (response['data'] as List)
              .map((json) => Category.fromJson(json))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSuppliers() async {
    try {
      final response = await ApiService.get(ApiConfig.suppliersEndpoint);
      if (response['success'] == true) {
        setState(() {
          _suppliers = (response['data'] as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
  }

  List<Product> get _filteredProducts {
    return _products.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.barcode?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
      final matchesCategory =
          _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<Product> get _displayedProducts {
    final filtered = _filteredProducts;
    final endIndex =
        ((_currentPage + 1) * _itemsPerPage).clamp(0, filtered.length);
    return filtered.sublist(0, endIndex);
  }

  int get _lowStockCount =>
      _products.where((p) => p.stockQuantity <= p.lowStockThreshold).length;

  double get _totalValue => _products.fold<double>(
      0, (sum, p) => sum + p.sellingPrice * p.stockQuantity);

  Future<void> _showProductForm({Product? product}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(
          product: product,
          categories: _categories,
          suppliers: _suppliers,
        ),
      ),
    );
    if (result == true) await _loadProducts();
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final response = await ApiService.delete(
          '${ApiConfig.productsEndpoint}?id=${product.id}');
      if (response['success']) {
        await _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deleted successfully')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildBody()),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.indigo.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              // Title and actions
              Row(
                children: [
                  const Icon(Icons.inventory_2_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Products',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh,
                        color: Colors.white, size: 20),
                    onPressed: _loadData,
                    tooltip: 'Refresh',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.add_circle,
                        color: Colors.white, size: 20),
                    onPressed: () => _showProductForm(),
                    tooltip: 'Add Product',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Search bar
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _currentPage = 0;
                    _hasMoreItems = true;
                  });
                },
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 13),
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.white70, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: Colors.white70, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Stats cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _buildStatsCards(),
          ),
        ),
        // Category filter
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: _buildCategoryFilter(),
          ),
        ),
        // Products grid
        _buildProductsGrid(),
        // Loading indicator
        _buildLoadingIndicator(),
      ],
    );
  }

  Widget _buildStatsCards() {
    final currency = context.watch<AppSettingsProvider>().currencySymbol;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.inventory_2_rounded,
            label: 'Total',
            value: '${_products.length}',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.warning_amber_rounded,
            label: 'Low Stock',
            value: '$_lowStockCount',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.attach_money_rounded,
            label: 'Value',
            value: '${_totalValue.toStringAsFixed(0)} $currency',
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return ModernDropdown<String?>(
      label: 'Category',
      icon: Icons.filter_list_rounded,
      value: _selectedCategoryId,
      selectedLabel: _selectedCategoryId == null
          ? 'All Categories'
          : _categories.firstWhere((c) => c.id == _selectedCategoryId).name,
      hint: 'All Categories',
      items: [
        const DropdownItem(value: null, label: 'All Categories'),
        ..._categories.map(
          (c) => DropdownItem(value: c.id, label: c.name),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedCategoryId = value;
          _currentPage = 0;
          _hasMoreItems = true;
        });
      },
    );
  }

  Widget _buildProductsGrid() {
    final products = _displayedProducts;
    final allFiltered = _filteredProducts;

    if (allFiltered.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No products found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final crossAxisCount = width < 600
              ? 2
              : width < 900
                  ? 3
                  : width < 1200
                      ? 4
                      : width < 1600
                          ? 5
                          : width < 2000
                              ? 6
                              : 7;

          final cardHeight = width < 600 ? 232.0 : 220.0;

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: cardHeight,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _ProductCard(
                  product: products[index],
                  onTap: () => _showProductForm(product: products[index]),
                  onDelete: () => _deleteProduct(products[index]),
                );
              },
              childCount: products.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    if (!_isLoadingMore) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowStock = product.stockQuantity <= product.lowStockThreshold;
    final isOutOfStock = product.stockQuantity <= 0;
    final stockColor = isOutOfStock
        ? Colors.red
        : isLowStock
            ? Colors.orange
            : Colors.green;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image section
            SizedBox(
              height: 96,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: ProductImageWidget(
                      imageUrl: product.imageUrl,
                      size: 80,
                    ),
                  ),
                  // Stock badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: stockColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        isOutOfStock
                            ? 'Out'
                            : isLowStock
                                ? 'Low'
                                : '${product.stockQuantity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product name
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Price
                        Text(
                          '${product.sellingPrice.toStringAsFixed(2)} ${context.watch<AppSettingsProvider>().currencySymbol}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (product.categoryName != null &&
                            product.categoryName!.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              Icon(Icons.category_outlined,
                                  size: 11, color: Colors.grey.shade600),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  product.categoryName!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (product.barcode != null &&
                            product.barcode!.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              Icon(Icons.qr_code_2,
                                  size: 11, color: Colors.grey.shade600),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  product.barcode!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: onTap,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text(
                              'Edit',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: IconButton(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline, size: 15),
                            color: Colors.red,
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              side: BorderSide(
                                color: Colors.red.withOpacity(0.3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
