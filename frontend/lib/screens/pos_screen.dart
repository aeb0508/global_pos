import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/customer.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/multi_payment_dialog.dart';
import '../widgets/customer_form_dialog.dart';
import 'home_screen.dart';

class PosScreen extends StatefulWidget {
  final Map<String, dynamic>? orderToEdit;
  const PosScreen({super.key, this.orderToEdit});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Product> _displayedProducts = [];
  List<Category> _categories = [];
  List<Customer> _customers = [];
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  static const int _pageSize = 12;
  int _currentPage = 1;
  bool _hasMore = false;
  bool _loadingMore = false;
  String _paymentMethod = 'cash';
  List<Map<String, dynamic>> _splitPayments = [];
  String? _giftCardNumber;
  double _giftCardAmount = 0;
  String? _selectedCategoryId;
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final results = await Future.wait([
      ApiService.get(ApiConfig.productsEndpoint),
      ApiService.get(ApiConfig.categoriesEndpoint),
      ApiService.get(ApiConfig.customersEndpoint),
    ]);

    if (!mounted) return;

    setState(() {
      if (results[0]['success'] == true) {
        _products = (results[0]['data'] as List)
            .map((json) => Product.fromJson(json))
            .toList();
      }
      _filteredProducts = _products;
      _resetPagination();

      if (results[1]['success'] == true) {
        _categories = (results[1]['data'] as List)
            .map((json) => Category.fromJson(json))
            .toList();
      }

      if (results[2]['success'] == true) {
        _customers = (results[2]['data'] as List)
            .map((json) => Customer.fromJson(json))
            .toList();
      }
    });

    if (widget.orderToEdit != null && mounted) {
      _loadOrderForEditing();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _resetPagination() {
    _currentPage = 1;
    _displayedProducts = _filteredProducts.take(_pageSize).toList();
    _hasMore = _filteredProducts.length > _pageSize;
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadingMore = true;
      setState(() {
        _currentPage++;
        _displayedProducts =
            _filteredProducts.take(_currentPage * _pageSize).toList();
        _hasMore = _displayedProducts.length < _filteredProducts.length;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    try {
      final response = await ApiService.get(ApiConfig.productsEndpoint);
      if (response['success'] == true && mounted) {
        setState(() {
          _products = (response['data'] as List)
              .map((json) => Product.fromJson(json))
              .toList();
          _filteredProducts = _products;
          _resetPagination();
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Failed to load products: $e');
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final response = await ApiService.get(ApiConfig.categoriesEndpoint);
      if (response['success'] == true && mounted) {
        setState(() {
          _categories = (response['data'] as List)
              .map((json) => Category.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Failed to load categories: $e');
      }
    }
  }

  Future<void> _loadCustomers() async {
    try {
      final response = await ApiService.get(ApiConfig.customersEndpoint);
      if (response['success'] == true && mounted) {
        setState(() {
          _customers = (response['data'] as List)
              .map((json) => Customer.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Failed to load customers: $e');
      }
    }
  }

  void _loadOrderForEditing() {
    if (widget.orderToEdit == null) return;

    final cart = Provider.of<CartProvider>(context, listen: false);
    final order = widget.orderToEdit!;

    cart.clear();

    // Load customer if exists
    if (order['customer_id'] != null) {
      final customerId = order['customer_id'].toString();
      if (customerId.isNotEmpty) {
        final customer = _customers.firstWhere(
          (c) => c.id == customerId,
          orElse: () => Customer(
              id: '', name: '', email: null, phone: null, address: null),
        );
        if (customer.id.isNotEmpty) {
          setState(() => _selectedCustomer = customer);
        }
      }
    }

    // Load items into cart
    if (order['items'] != null && order['items'] is List) {
      for (final item in order['items']) {
        final productId = item['product_id'].toString();
        if (productId.isNotEmpty) {
          final product = _products.firstWhere(
            (p) => p.id == productId,
            orElse: () => Product(
              id: '',
              name: '',
              categoryId: null,
              costPrice: 0,
              sellingPrice: 0,
              stockQuantity: 0,
              lowStockThreshold: 0,
            ),
          );

          if (product.id.isNotEmpty) {
            final quantity = int.tryParse(item['quantity'].toString()) ?? 1;
            final clampedQty = quantity.clamp(1, product.stockQuantity);
            cart.addProduct(product);
            if (clampedQty > 1) {
              cart.updateQuantity(product.id, clampedQty);
            }
            if (clampedQty < quantity && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${product.name}: requested $quantity but only $clampedQty in stock.',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      }
    }

    // Load discount if exists
    if (order['discount'] != null) {
      final discount = double.tryParse(order['discount'].toString()) ?? 0;
      if (discount > 0) cart.setDiscount(discount);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #${order['order_number']} loaded for editing'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _searchProducts(String query) {
    setState(() {
      _filteredProducts = _products
          .where((p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              (p.barcode?.contains(query) ?? false))
          .where((p) =>
              _selectedCategoryId == null ||
              p.categoryId == _selectedCategoryId)
          .toList();
      _resetPagination();
    });
  }

  void _filterByCategory(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _filteredProducts = _products
          .where((p) => categoryId == null || p.categoryId == categoryId)
          .where((p) =>
              p.name
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ||
              (p.barcode?.contains(_searchController.text) ?? false))
          .toList();
      _resetPagination();
    });
  }

  void _handleSearch(String query) {
    if (query.isEmpty) {
      _searchProducts('');
      return;
    }

    // Try to find by barcode first
    final productByBarcode = _products.firstWhere(
      (p) => p.barcode == query,
      orElse: () => Product(
        id: '',
        name: '',
        categoryId: null,
        costPrice: 0,
        sellingPrice: 0,
        stockQuantity: 0,
        lowStockThreshold: 0,
      ),
    );

    if (productByBarcode.id.isNotEmpty) {
      // Found by barcode - add to cart
      if (productByBarcode.stockQuantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product out of stock!'),
            backgroundColor: Colors.red,
          ),
        );
        _searchController.clear();
        return;
      }

      final isLowStock =
          productByBarcode.stockQuantity <= productByBarcode.lowStockThreshold;

      Provider.of<CartProvider>(context, listen: false)
          .addProduct(productByBarcode);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLowStock
                ? 'Added ${productByBarcode.name} - Low stock: ${productByBarcode.stockQuantity} left!'
                : 'Added ${productByBarcode.name}',
            style: const TextStyle(fontSize: 12),
          ),
          duration: Duration(milliseconds: isLowStock ? 2000 : 500),
          backgroundColor: isLowStock ? Colors.orange : Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 16, left: 16, right: 400),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );
      _searchController.clear();
    } else {
      // Not found by barcode - search by name
      _searchProducts(query);
    }
  }

  void _showSplitPaymentDialog() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => MultiPaymentDialog(
        totalAmount: cart.total - _giftCardAmount,
        onComplete: (payments) {
          setState(() => _splitPayments = payments);
          _processCheckout(isSplit: true);
        },
      ),
    );
  }

  void _cancelOrder() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.items.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Cancel Order'),
          ],
        ),
        content: const Text(
            'Are you sure you want to cancel this order? All items will be removed from the cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      cart.clear();
      setState(() {
        _splitPayments = [];
        _giftCardNumber = null;
        _giftCardAmount = 0;
        _selectedCustomer = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 16, left: 16, right: 400),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            duration: Duration(milliseconds: 500),
          ),
        );
      }
    }
  }

  Future<void> _checkout() async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirm Order'),
          ],
        ),
        content: Consumer<CartProvider>(
          builder: (context, cart, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to complete this order?'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Items:',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('${cart.items.length}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          (cart.total - _giftCardAmount).toStringAsFixed(2),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _processCheckout(status: 'completed');
    }
  }

  Future<void> _savePending() async => _processCheckout(status: 'pending');

  void _showGiftCardDialog() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => _GiftCardDialog(
        totalAmount: cart.total,
        onApply: (cardNumber, amount) {
          setState(() {
            _giftCardNumber = cardNumber;
            _giftCardAmount = amount;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _processCheckout(
      {bool isSplit = false, String status = 'completed'}) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (cart.items.isEmpty) return;
    // Handle gift card redemption first (only on completion)
    if (status == 'completed' &&
        _giftCardNumber != null &&
        _giftCardAmount > 0) {
      try {
        final redeemResponse = await ApiService.post(
          '${ApiConfig.baseUrl}/gift_cards.php',
          {
            'redeem': true,
            'card_number': _giftCardNumber,
            'amount': _giftCardAmount,
          },
        );

        if (redeemResponse['success'] != true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    redeemResponse['message'] ?? 'Gift card redemption failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Gift card error: $e'),
                backgroundColor: Colors.red),
          );
        }
        return;
      }
    }

    final items = cart.items
        .map((item) => {
              'product_id': item.product.id,
              'product_name': item.product.name,
              'quantity': item.quantity,
              'unit_price': item.product.sellingPrice,
              'total_price': item.total,
            })
        .toList();

    final isEditing = widget.orderToEdit != null;
    final editingId = isEditing ? widget.orderToEdit!['id']?.toString() : null;

    try {
      Map<String, dynamic> response;

      if (isEditing && editingId != null) {
        final updateData = {
          'status': status,
          'customer_id':
              (_selectedCustomer != null && _selectedCustomer!.id.isNotEmpty)
                  ? _selectedCustomer!.id
                  : null,
          'subtotal': cart.subtotal,
          'discount': cart.discount,
          'tax': cart.tax,
          'total': cart.total,
          'payment_method': isSplit ? 'split' : _paymentMethod,
          'items': items,
        };
        response = await ApiService.put(
            '${ApiConfig.ordersEndpoint}?id=$editingId', updateData);
      } else {
        if (auth.user == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Session expired. Please log in again.'),
              backgroundColor: Colors.red,
            ));
          }
          return;
        }
        final orderData = <String, dynamic>{
          'user_id': auth.user!.id,
          'customer_id':
              (_selectedCustomer != null && _selectedCustomer!.id.isNotEmpty)
                  ? _selectedCustomer!.id
                  : null,
          'subtotal': cart.subtotal,
          'discount': cart.discount,
          'tax': cart.tax,
          'total': cart.total,
          'payment_method': isSplit ? 'split' : _paymentMethod,
          'status': status,
          'items': items,
        };
        if (isSplit) orderData['payments'] = _splitPayments;
        response = await ApiService.post(ApiConfig.ordersEndpoint, orderData);
      }

      if (response['success'] == true && mounted) {
        final orderNumber = isEditing
            ? widget.orderToEdit!['order_number']
            : response['data']['order_number'];

        cart.clear();
        setState(() {
          _splitPayments = [];
          _giftCardNumber = null;
          _giftCardAmount = 0;
          _selectedCustomer = null;
        });

        _loadProducts();

        await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  status == 'pending' ? Icons.schedule : Icons.check_circle,
                  color: status == 'pending' ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(status == 'pending'
                    ? 'Order Saved as Pending'
                    : 'Order Completed'),
              ],
            ),
            content: Text(status == 'pending'
                ? 'Order $orderNumber saved as pending!'
                : 'Order $orderNumber completed!${_giftCardAmount > 0 ? '\n\nGift card applied: ${_giftCardAmount.toStringAsFixed(2)}' : ''}'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        if (isEditing && mounted) {
          final originalStatus =
              widget.orderToEdit!['status']?.toString() ?? 'pending';
          final targetIndex = originalStatus == 'pending' ? 4 : 3;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HomeScreen(initialIndex: targetIndex),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to process order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process order: $e')),
        );
      }
    }
  }

  void _showDiscountDialog() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => _DiscountDialog(
        currentDiscount: cart.discount,
        subtotal: cart.subtotal,
        onApply: (discount) {
          cart.setDiscount(discount);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildProductsPanel(),
        ),
        // Cart panel
        Container(
          width: MediaQuery.of(context).size.width < 900 ? 320 : 350,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
                left: BorderSide(color: Theme.of(context).colorScheme.outline)),
          ),
          child: _buildCartPanel(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return _MobilePosLayout(
      productsPanel: _buildProductsPanel(),
      cartPanel: _buildCartPanel(),
    );
  }

  Widget _buildProductsPanel() {
    return Column(
      children: [
        // Top bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.4),
            border: Border(
              bottom: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _TopBarField(
                      controller: _searchController,
                      hint: 'Scan barcode or search products…',
                      icon: Icons.search,
                      accentColor: Theme.of(context).colorScheme.primary,
                      onChanged: _handleSearch,
                      onSubmitted: (value) {
                        _handleSearch(value);
                      },
                      onClear: () {
                        _searchController.clear();
                        _searchProducts('');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Refresh Data',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        _loadProducts();
                        _loadCategories();
                        _loadCustomers();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.refresh,
                          size: 20,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryChip(
                      label: 'All',
                      selected: _selectedCategoryId == null,
                      onTap: () => _filterByCategory(null),
                    ),
                    ..._categories.map((cat) => _CategoryChip(
                          label: cat.name,
                          selected: _selectedCategoryId == cat.id,
                          onTap: () => _filterByCategory(cat.id),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        // Products grid
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount =
                    (constraints.maxWidth / 160).floor().clamp(2, 6);
                return GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  physics: const ClampingScrollPhysics(),
                  cacheExtent: 1200,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisExtent: 160,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _displayedProducts.length +
                      (_hasMore ? crossAxisCount : 0),
                  itemBuilder: (context, index) {
                    if (index >= _displayedProducts.length) {
                      return index == _displayedProducts.length
                          ? const Center(
                              child: Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ))
                          : const SizedBox.shrink();
                    }
                    return _ProductCard(product: _displayedProducts[index]);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartPanel() {
    return _CartPanel(
      paymentMethod: _paymentMethod,
      onPaymentMethodChanged: (value) =>
          setState(() => _paymentMethod = value!),
      onCheckout: _checkout,
      onSavePending: _savePending,
      onCancelOrder: _cancelOrder,
      onApplyDiscount: _showDiscountDialog,
      onSplitPayment: _showSplitPaymentDialog,
      onApplyGiftCard: _showGiftCardDialog,
      giftCardAmount: _giftCardAmount,
      selectedCustomer: _selectedCustomer,
      customers: _customers,
      onCustomerChanged: (c) => setState(() => _selectedCustomer = c),
      onCustomerAdded: _loadCustomers,
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  void _onTap(BuildContext context, bool isOutOfStock, bool isLowStock) {
    if (isOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Product out of stock!'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (isLowStock) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Low stock warning: Only ${product.stockQuantity} left!'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
    }
    Provider.of<CartProvider>(context, listen: false).addProduct(product);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'Added ${product.name}',
        style: const TextStyle(fontSize: 12),
      ),
      duration: const Duration(milliseconds: 500),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 400),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.stockQuantity <= 0;
    final isLowStock =
        !isOutOfStock && product.stockQuantity <= product.lowStockThreshold;
    final colorScheme = Theme.of(context).colorScheme;

    final stockColor = isOutOfStock
        ? Colors.red
        : isLowStock
            ? Colors.orange
            : Colors.green;
    final stockLabel = isOutOfStock
        ? 'Out of stock'
        : isLowStock
            ? 'Low: ${product.stockQuantity}'
            : '${product.stockQuantity} in stock';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _onTap(context, isOutOfStock, isLowStock),
        child: Stack(
          children: [
            // Full card background: image or placeholder
            Positioned.fill(
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? ColorFiltered(
                      colorFilter: isOutOfStock
                          ? const ColorFilter.matrix([
                              0.5,
                              0,
                              0,
                              0,
                              0,
                              0,
                              0.5,
                              0,
                              0,
                              0,
                              0,
                              0,
                              0.5,
                              0,
                              0,
                              0,
                              0,
                              0,
                              1,
                              0,
                            ])
                          : const ColorFilter.mode(
                              Colors.transparent, BlendMode.dst),
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 350,
                        memCacheHeight: 350,
                        placeholder: (_, __) => _PlaceholderBg(
                            colorScheme: colorScheme,
                            isOutOfStock: isOutOfStock),
                        errorWidget: (_, __, ___) => _PlaceholderBg(
                            colorScheme: colorScheme,
                            isOutOfStock: isOutOfStock),
                      ),
                    )
                  : _PlaceholderBg(
                      colorScheme: colorScheme, isOutOfStock: isOutOfStock),
            ),
            // Bottom gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.72),
                    ],
                    stops: const [0.45, 1.0],
                  ),
                ),
              ),
            ),
            // Stock pill — top right
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: stockColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  stockLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // Name + price at bottom
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Consumer<AppSettingsProvider>(
                          builder: (context, settings, _) => Text(
                            '${product.sellingPrice.toStringAsFixed(2)} ${settings.currencySymbol}',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (!isOutOfStock)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add,
                              color: colorScheme.onPrimary, size: 18),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Mobile POS layout: products on top tab, cart on bottom tab
class _MobilePosLayout extends StatefulWidget {
  final Widget productsPanel;
  final Widget cartPanel;
  const _MobilePosLayout(
      {required this.productsPanel, required this.cartPanel});

  @override
  State<_MobilePosLayout> createState() => _MobilePosLayoutState();
}

class _MobilePosLayoutState extends State<_MobilePosLayout> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: IndexedStack(
            index: _tab,
            children: [widget.productsPanel, widget.cartPanel],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(
                top: BorderSide(color: cs.outline.withValues(alpha: 0.2))),
          ),
          child: Row(
            children: [
              Expanded(
                child: _MobileTabBtn(
                  icon: Icons.grid_view_rounded,
                  label: 'Products',
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
              ),
              Expanded(
                child: Consumer<CartProvider>(
                  builder: (context, cart, _) => _MobileTabBtn(
                    icon: Icons.shopping_cart_rounded,
                    label: 'Cart (${cart.items.length})',
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                    badge: cart.items.isNotEmpty,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileTabBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool badge;
  const _MobileTabBtn(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap,
      this.badge = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: selected ? cs.primaryContainer : cs.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 20,
                color: selected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color:
                    selected ? cs.primary : cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderBg extends StatelessWidget {
  final ColorScheme colorScheme;
  final bool isOutOfStock;
  const _PlaceholderBg({required this.colorScheme, required this.isOutOfStock});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isOutOfStock
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.shopping_bag_outlined,
            size: 40,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
      ),
    );
  }
}

class _TopBarField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color accentColor;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;

  const _TopBarField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.accentColor,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4)),
          prefixIcon: Icon(icon, size: 18, color: accentColor),
          suffixIcon: onClear != null
              ? IconButton(
                  icon: Icon(Icons.close,
                      size: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4)),
                  onPressed: onClear,
                  splashRadius: 16,
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.35),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerSelectorTile extends StatelessWidget {
  final Customer? selectedCustomer;
  final List<Customer> customers;
  final ValueChanged<Customer?> onChanged;
  final VoidCallback onCustomerAdded;

  const _CustomerSelectorTile({
    required this.selectedCustomer,
    required this.customers,
    required this.onChanged,
    required this.onCustomerAdded,
  });

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CustomerPickerSheet(
        customers: customers,
        selected: selectedCustomer,
        onSelect: (c) {
          onChanged(c);
          Navigator.pop(context);
        },
        onCustomerAdded: onCustomerAdded,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomer = selectedCustomer != null;
    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              child: Text(
                hasCustomer ? selectedCustomer!.name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasCustomer ? selectedCustomer!.name : 'Walk-in Customer',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasCustomer && selectedCustomer!.email != null)
                    Text(
                      selectedCustomer!.email!,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (hasCustomer)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(Icons.close,
                    size: 16, color: Colors.white.withValues(alpha: 0.7)),
              )
            else
              Icon(Icons.keyboard_arrow_down,
                  size: 18, color: Colors.white.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}

class _CustomerPickerSheet extends StatefulWidget {
  final List<Customer> customers;
  final Customer? selected;
  final ValueChanged<Customer?> onSelect;
  final VoidCallback onCustomerAdded;

  const _CustomerPickerSheet({
    required this.customers,
    required this.onSelect,
    required this.onCustomerAdded,
    this.selected,
  });

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final _search = TextEditingController();
  List<Customer> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.customers;
    _search.addListener(() {
      final q = _search.text.toLowerCase();
      setState(() {
        _filtered = widget.customers
            .where((c) =>
                c.name.toLowerCase().contains(q) ||
                (c.email?.toLowerCase().contains(q) ?? false))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomerFormDialog(
        onSaved: (newCustomer) {
          Navigator.pop(context);
          widget.onCustomerAdded();
          // Select the newly added customer
          if (newCustomer != null) {
            widget.onSelect(newCustomer);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.people_outline, size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  Text('Select Customer',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.person_add, size: 20),
                    onPressed: _showAddCustomerDialog,
                    tooltip: 'Add Customer',
                    style: IconButton.styleFrom(
                      backgroundColor: cs.primaryContainer,
                      foregroundColor: cs.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                ),
                child: TextField(
                  controller: _search,
                  autofocus: true,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search customers…',
                    hintStyle: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.4)),
                    prefixIcon: Icon(Icons.search,
                        size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            // Walk-in option
            ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: cs.surfaceContainerHighest,
                child: Icon(Icons.person_outline,
                    size: 18, color: cs.onSurfaceVariant),
              ),
              title: const Text('Walk-in Customer',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              trailing: widget.selected == null
                  ? Icon(Icons.check_circle, color: cs.primary, size: 18)
                  : null,
              onTap: () => widget.onSelect(null),
            ),
            const Divider(height: 1),
            // Customer list
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text('No customers found',
                          style: TextStyle(color: cs.outline, fontSize: 13)))
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 56),
                      itemBuilder: (_, i) {
                        final c = _filtered[i];
                        final isSelected = widget.selected?.id == c.id;
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: isSelected
                                ? cs.primaryContainer
                                : cs.surfaceContainerHighest,
                            child: Text(
                              c.name[0].toUpperCase(),
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? cs.onPrimaryContainer
                                      : cs.onSurfaceVariant),
                            ),
                          ),
                          title: Text(c.name,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                          subtitle: c.email != null
                              ? Text(c.email!,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          cs.onSurface.withValues(alpha: 0.5)))
                              : null,
                          trailing: isSelected
                              ? Icon(Icons.check_circle,
                                  color: cs.primary, size: 18)
                              : null,
                          onTap: () => widget.onSelect(c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  final String paymentMethod;
  final ValueChanged<String?> onPaymentMethodChanged;
  final VoidCallback onCheckout;
  final VoidCallback onSavePending;
  final VoidCallback onCancelOrder;
  final VoidCallback onApplyDiscount;
  final VoidCallback onSplitPayment;
  final VoidCallback onApplyGiftCard;
  final double giftCardAmount;
  final Customer? selectedCustomer;
  final List<Customer> customers;
  final ValueChanged<Customer?> onCustomerChanged;
  final VoidCallback onCustomerAdded;

  const _CartPanel({
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
    required this.onCheckout,
    required this.onSavePending,
    required this.onCancelOrder,
    required this.onApplyDiscount,
    required this.onSplitPayment,
    required this.onApplyGiftCard,
    required this.giftCardAmount,
    required this.customers,
    required this.onCustomerChanged,
    required this.onCustomerAdded,
    this.selectedCustomer,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        return Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: cs.primary,
                boxShadow: [
                  BoxShadow(
                      color: cs.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text('Order',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      if (cart.items.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${cart.items.length} item${cart.items.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Customer selector tile
                  _CustomerSelectorTile(
                    selectedCustomer: selectedCustomer,
                    customers: customers,
                    onChanged: onCustomerChanged,
                    onCustomerAdded: onCustomerAdded,
                  ),
                ],
              ),
            ),

            // ── Cart items ───────────────────────────────────────
            Expanded(
              child: cart.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined,
                              size: 56,
                              color: cs.outline.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('Cart is empty',
                              style: TextStyle(
                                  color: cs.outline,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('Tap a product to add it',
                              style: TextStyle(
                                  color: cs.outline.withValues(alpha: 0.6),
                                  fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        // Show stock-limit warning if triggered
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final warning = cart.consumeStockLimitWarning();
                          if (warning != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Max stock reached for $warning'),
                              backgroundColor: Colors.orange,
                              duration: const Duration(seconds: 2),
                            ));
                          }
                        });
                        final item = cart.items[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: cs.outline.withValues(alpha: 0.12)),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1))
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          child: Row(
                            children: [
                              // Product colour dot
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.shopping_bag_outlined,
                                    size: 18, color: cs.onPrimaryContainer),
                              ),
                              const SizedBox(width: 10),
                              // Name + unit price
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Consumer<AppSettingsProvider>(
                                      builder: (context, settings, _) => Text(
                                        '${item.product.sellingPrice.toStringAsFixed(2)} ${settings.currencySymbol} each',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: cs.onSurface
                                                .withValues(alpha: 0.5)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Qty stepper
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _QtyBtn(
                                    icon: Icons.remove,
                                    onTap: () => cart.updateQuantity(
                                        item.product.id, item.quantity - 1),
                                  ),
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '${item.quantity}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  _QtyBtn(
                                    icon: Icons.add,
                                    onTap: () => cart.updateQuantity(
                                        item.product.id, item.quantity + 1),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              // Line total
                              SizedBox(
                                width: 52,
                                child: Consumer<AppSettingsProvider>(
                                  builder: (context, settings, _) => Text(
                                    '${item.total.toStringAsFixed(2)} ${settings.currencySymbol}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: cs.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Delete
                              GestureDetector(
                                onTap: () =>
                                    cart.removeProduct(item.product.id),
                                child: Icon(Icons.close,
                                    size: 16,
                                    color: cs.error.withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // ── Summary + actions ────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                    top: BorderSide(color: cs.outline.withValues(alpha: 0.15))),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -2))
                ],
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                children: [
                  // Subtotal / discount / tax rows
                  Builder(builder: (context) {
                    final sym =
                        context.watch<AppSettingsProvider>().currencySymbol;
                    return Column(
                      children: [
                        _SummaryRow(
                            label: 'Subtotal',
                            value: '${cart.subtotal.toStringAsFixed(2)} $sym'),
                        if (cart.discount > 0) ...[
                          const SizedBox(height: 4),
                          _SummaryRow(
                              label: 'Discount',
                              value:
                                  '-${cart.discount.toStringAsFixed(2)} $sym',
                              valueColor: Colors.red),
                        ],
                        if (giftCardAmount > 0) ...[
                          const SizedBox(height: 4),
                          _SummaryRow(
                              label: 'Gift Card',
                              value:
                                  '-${giftCardAmount.toStringAsFixed(2)} $sym',
                              valueColor: Colors.green),
                        ],
                        const SizedBox(height: 4),
                        _SummaryRow(
                            label: 'Tax',
                            value: '${cart.tax.toStringAsFixed(2)} $sym'),
                      ],
                    );
                  }),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      Consumer<AppSettingsProvider>(
                        builder: (context, settings, _) => Text(
                          '${(cart.total - giftCardAmount).toStringAsFixed(2)} ${settings.currencySymbol}',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: cs.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Discount + Gift Card + Split row
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.discount_outlined,
                          label: cart.discount > 0 ? 'Disc ✓' : 'Disc',
                          active: cart.discount > 0,
                          onTap: onApplyDiscount,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.card_giftcard,
                          label: giftCardAmount > 0 ? 'Gift ✓' : 'Gift',
                          active: giftCardAmount > 0,
                          onTap: cart.items.isEmpty ? null : onApplyGiftCard,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.call_split,
                          label: 'Split',
                          onTap: cart.items.isEmpty ? null : onSplitPayment,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Payment method selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: cs.outline.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _PaymentMethodButton(
                            label: 'Cash',
                            icon: Icons.payments_rounded,
                            selected: paymentMethod == 'cash',
                            onTap: () => onPaymentMethodChanged('cash'),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _PaymentMethodButton(
                            label: 'Card',
                            icon: Icons.credit_card_rounded,
                            selected: paymentMethod == 'card',
                            onTap: () => onPaymentMethodChanged('card'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Action buttons
                  Row(
                    children: [
                      // Cancel button
                      SizedBox(
                        height: 52,
                        width: 52,
                        child: OutlinedButton(
                          onPressed: cart.items.isEmpty ? null : onCancelOrder,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: Colors.red,
                            side: BorderSide(
                                color: cart.items.isEmpty
                                    ? cs.outline.withValues(alpha: 0.3)
                                    : Colors.red.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Icon(Icons.close_rounded, size: 24),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Pending button
                      SizedBox(
                        height: 52,
                        width: 52,
                        child: OutlinedButton(
                          onPressed: cart.items.isEmpty ? null : onSavePending,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Icon(Icons.schedule_rounded, size: 24),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Complete button
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: cart.items.isEmpty ? null : onCheckout,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    size: 20),
                                const SizedBox(width: 8),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Complete',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          height: 1),
                                    ),
                                    Consumer<AppSettingsProvider>(
                                      builder: (context, settings, _) => Text(
                                        '${(cart.total - giftCardAmount).toStringAsFixed(2)} ${settings.currencySymbol}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            height: 1.2),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: cs.onPrimaryContainer),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SummaryRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6))),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? cs.onSurface)),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      this.onTap,
      this.active = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? cs.primaryContainer
              : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active
                  ? cs.primary.withValues(alpha: 0.4)
                  : cs.outline.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 14,
                color: active
                    ? cs.primary
                    : enabled
                        ? cs.onSurface.withValues(alpha: 0.7)
                        : cs.onSurface.withValues(alpha: 0.3)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: active
                          ? cs.primary
                          : enabled
                              ? cs.onSurface.withValues(alpha: 0.7)
                              : cs.onSurface.withValues(alpha: 0.3))),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentMethodButton(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 20,
                color: selected
                    ? cs.onPrimary
                    : cs.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? cs.onPrimary
                        : cs.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }
}

class _DiscountDialog extends StatefulWidget {
  final double currentDiscount;
  final double subtotal;
  final Function(double) onApply;

  const _DiscountDialog({
    required this.currentDiscount,
    required this.subtotal,
    required this.onApply,
  });

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  String _discountType = 'percentage';
  final _discountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.currentDiscount > 0) {
      _discountController.text = widget.currentDiscount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  void _applyDiscount() {
    final value = double.tryParse(_discountController.text) ?? 0;
    final discount =
        _discountType == 'percentage' ? widget.subtotal * (value / 100) : value;

    if (discount > widget.subtotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discount cannot exceed subtotal')),
      );
      return;
    }
    widget.onApply(discount);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Apply Discount'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'percentage', label: Text('Percentage')),
                ButtonSegment(value: 'fixed', label: Text('Fixed Amount')),
              ],
              selected: {_discountType},
              onSelectionChanged: (s) =>
                  setState(() => _discountType = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _discountType == 'percentage'
                    ? 'Discount (%)'
                    : 'Discount Amount (\$)',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(_discountType == 'percentage'
                    ? Icons.percent
                    : Icons.attach_money),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => widget.onApply(0), child: const Text('Remove')),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(onPressed: _applyDiscount, child: const Text('Apply')),
      ],
    );
  }
}

class _GiftCardDialog extends StatefulWidget {
  final double totalAmount;
  final Function(String cardNumber, double amount) onApply;

  const _GiftCardDialog({
    required this.totalAmount,
    required this.onApply,
  });

  @override
  State<_GiftCardDialog> createState() => _GiftCardDialogState();
}

class _GiftCardDialogState extends State<_GiftCardDialog> {
  final _cardNumberController = TextEditingController();
  bool _isLoading = false;
  bool _loadingCards = true;
  Map<String, dynamic>? _cardInfo;
  List<dynamic> _giftCards = [];

  @override
  void initState() {
    super.initState();
    _loadGiftCards();
  }

  Future<void> _loadGiftCards() async {
    try {
      final response =
          await ApiService.get('${ApiConfig.baseUrl}/gift_cards.php');
      if (mounted && response['success'] == true) {
        setState(() {
          _giftCards = (response['data'] as List)
              .where((c) => c['status'] == 'active')
              .toList();
          _loadingCards = false;
        });
      } else if (mounted) {
        setState(() => _loadingCards = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingCards = false);
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    super.dispose();
  }

  Future<void> _checkCard() async {
    if (_cardNumberController.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.get(
        '${ApiConfig.baseUrl}/gift_cards.php?card_number=${_cardNumberController.text}',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response['success'] && response['data'] != null) {
            final card = response['data'];
            if (card['status'] != 'active') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gift card is ${card['status']}'),
                  backgroundColor: Colors.red,
                ),
              );
              _cardInfo = null;
            } else {
              _cardInfo = card;
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gift card not found'),
                backgroundColor: Colors.red,
              ),
            );
            _cardInfo = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyCard() {
    if (_cardInfo == null) return;

    final balance = double.parse(_cardInfo!['current_balance'].toString());
    final amountToApply =
        balance >= widget.totalAmount ? widget.totalAmount : balance;

    widget.onApply(_cardInfo!['card_number'], amountToApply);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Apply Gift Card'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _loadingCards
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : DropdownButtonFormField<String>(
                    initialValue: _cardNumberController.text.isEmpty
                        ? null
                        : _cardNumberController.text,
                    decoration: InputDecoration(
                      labelText: 'Gift Card Number',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.card_giftcard),
                      suffixIcon: _cardNumberController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() {
                                  _cardNumberController.clear();
                                  _cardInfo = null;
                                });
                              },
                            )
                          : null,
                    ),
                    items: _giftCards.map((card) {
                      return DropdownMenuItem<String>(
                        value: card['card_number'],
                        child: Text(
                          '${card['card_number']} - ${card['current_balance']}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _cardNumberController.text = value;
                        _checkCard();
                      }
                    },
                    hint: const Text('Select or enter card number'),
                  ),
            const SizedBox(height: 12),
            TextField(
              controller: _cardNumberController,
              decoration: InputDecoration(
                labelText: 'Or Enter Card Number',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.edit),
                suffixIcon: IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  onPressed: _isLoading ? null : _checkCard,
                ),
              ),
              onSubmitted: (_) => _checkCard(),
            ),
            if (_cardInfo != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Card Balance:',
                            style: TextStyle(
                                fontSize: 13, color: cs.onPrimaryContainer)),
                        Text(
                          double.parse(_cardInfo!['current_balance'].toString())
                              .toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order Total:',
                            style: TextStyle(
                                fontSize: 13, color: cs.onPrimaryContainer)),
                        Text(
                          widget.totalAmount.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Amount to Apply:',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: cs.onPrimaryContainer)),
                        Text(
                          (double.parse(_cardInfo!['current_balance']
                                          .toString()) >=
                                      widget.totalAmount
                                  ? widget.totalAmount
                                  : double.parse(
                                      _cardInfo!['current_balance'].toString()))
                              .toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _cardInfo == null ? null : _applyCard,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
