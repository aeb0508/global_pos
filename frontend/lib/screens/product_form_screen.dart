import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/modern_dropdown.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  final List<Category> categories;
  final List<Map<String, dynamic>> suppliers;

  const ProductFormScreen({
    super.key,
    this.product,
    required this.categories,
    required this.suppliers,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _costController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _lowStockController;

  String? _selectedCategoryId;
  String? _selectedSupplierId;
  String? _imageUrl;
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _costController =
        TextEditingController(text: p?.costPrice.toString() ?? '');
    _priceController =
        TextEditingController(text: p?.sellingPrice.toString() ?? '');
    _stockController = TextEditingController(
        text: p != null ? p.stockQuantity.toString() : '0');
    _lowStockController = TextEditingController(
        text: p != null ? p.lowStockThreshold.toString() : '0');
    _selectedCategoryId = p?.categoryId;
    _selectedSupplierId = p?.supplierId;
    _imageUrl = p?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;

    setState(() => _isUploading = true);
    final res = await ApiService.uploadImage(
      ApiConfig.uploadImageEndpoint,
      file.name,
      bytes,
    );
    setState(() => _isUploading = false);

    if (res['success'] == true) {
      setState(() {
        _imageUrl = res['url'] as String;
      });
    } else {
      if (mounted) {
        SnackBarHelper.showError(
            context, res['message'] ?? 'Image upload failed');
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final payload = {
      'name': _nameController.text.trim(),
      'barcode': _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      'category_id': _selectedCategoryId,
      'supplier_id': _selectedSupplierId,
      'description': _descriptionController.text.trim(),
      'cost_price': double.parse(_costController.text.trim()),
      'selling_price': double.parse(_priceController.text.trim()),
      'stock_quantity': int.parse(_stockController.text.trim()),
      'low_stock_threshold': int.parse(_lowStockController.text.trim()),
      'image_url': (_imageUrl == null || _imageUrl!.isEmpty) ? null : _imageUrl,
    };

    final isNew = widget.product == null;
    final response = isNew
        ? await ApiService.post(ApiConfig.productsEndpoint, payload)
        : await ApiService.put(
            ApiConfig.productsEndpoint,
            {'id': widget.product!.id, ...payload},
          );

    setState(() => _isSaving = false);

    if (response['success']) {
      if (mounted) {
        Navigator.pop(context, true);
        SnackBarHelper.showSuccess(
          context,
          isNew ? 'Product added successfully' : 'Product updated successfully',
        );
      }
    } else {
      if (mounted) {
        SnackBarHelper.showError(context, response['message'] ?? 'Save failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.product == null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(isNew ? Icons.add_box : Icons.edit, size: 20),
            const SizedBox(width: 8),
            Text(isNew ? 'Add Product' : 'Edit Product'),
          ],
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _saveProduct,
              icon: Icon(isNew ? Icons.add : Icons.save),
              label: Text(isNew ? 'Add' : 'Save'),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final maxWidth = isMobile ? double.infinity : 800.0;

          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image picker section
                      GestureDetector(
                        onTap: _isUploading ? null : _pickImage,
                        child: Container(
                          height: isMobile ? 180 : 220,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.3),
                                Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer
                                    .withValues(alpha: 0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: _isUploading
                              ? const Center(child: CircularProgressIndicator())
                              : _imageUrl != null && _imageUrl!.isNotEmpty
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: CachedNetworkImage(
                                            imageUrl: _imageUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) =>
                                                const Center(
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            ),
                                            errorWidget: (_, __, ___) =>
                                                const Icon(
                                              Icons.broken_image,
                                              size: 48,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: IconButton(
                                            onPressed: () => setState(
                                                () => _imageUrl = null),
                                            icon: const Icon(Icons.close),
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.black54,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 64,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.6),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Click to upload product image',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.6),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Basic Information Section
                      const _SectionHeader(
                          title: 'Basic Information', icon: Icons.info_outline),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Product Name *',
                          hintText: 'Enter product name',
                          prefixIcon: const Icon(Icons.inventory_2),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Product name is required'
                                : null,
                      ),
                      const SizedBox(height: 16),

                      if (isMobile) ...[
                        TextFormField(
                          controller: _barcodeController,
                          decoration: InputDecoration(
                            labelText: 'Barcode',
                            hintText: 'Optional',
                            prefixIcon: const Icon(Icons.qr_code),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ModernDropdown<String?>(
                          label: 'Category',
                          icon: Icons.category,
                          value: widget.categories
                                  .any((c) => c.id == _selectedCategoryId)
                              ? _selectedCategoryId
                              : null,
                          selectedLabel: _selectedCategoryId == null
                              ? 'None'
                              : widget.categories
                                  .firstWhere(
                                      (c) => c.id == _selectedCategoryId)
                                  .name,
                          hint: 'None',
                          items: [
                            const DropdownItem(value: null, label: 'None'),
                            ...widget.categories.map(
                              (c) => DropdownItem(value: c.id, label: c.name),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => _selectedCategoryId = value),
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _barcodeController,
                                decoration: InputDecoration(
                                  labelText: 'Barcode',
                                  hintText: 'Optional',
                                  prefixIcon: const Icon(Icons.qr_code),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ModernDropdown<String?>(
                                label: 'Category',
                                icon: Icons.category,
                                value: widget.categories
                                        .any((c) => c.id == _selectedCategoryId)
                                    ? _selectedCategoryId
                                    : null,
                                selectedLabel: _selectedCategoryId == null
                                    ? 'None'
                                    : widget.categories
                                        .firstWhere(
                                            (c) => c.id == _selectedCategoryId)
                                        .name,
                                hint: 'None',
                                items: [
                                  const DropdownItem(
                                      value: null, label: 'None'),
                                  ...widget.categories.map(
                                    (c) => DropdownItem(
                                        value: c.id, label: c.name),
                                  ),
                                ],
                                onChanged: (value) =>
                                    setState(() => _selectedCategoryId = value),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      ModernDropdown<String?>(
                        label: 'Supplier',
                        icon: Icons.local_shipping_outlined,
                        value: widget.suppliers.any((s) =>
                                s['id'].toString() == _selectedSupplierId)
                            ? _selectedSupplierId
                            : null,
                        selectedLabel: _selectedSupplierId == null
                            ? 'None'
                            : widget.suppliers
                                .firstWhere((s) =>
                                    s['id'].toString() ==
                                    _selectedSupplierId)['name']
                                .toString(),
                        hint: 'None',
                        items: [
                          const DropdownItem(value: null, label: 'None'),
                          ...widget.suppliers.map(
                            (s) => DropdownItem(
                              value: s['id'].toString(),
                              label: s['name'].toString(),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedSupplierId = value),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter product description',
                          prefixIcon: const Icon(Icons.description),
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Pricing Section
                      const _SectionHeader(
                          title: 'Pricing', icon: Icons.attach_money),
                      const SizedBox(height: 16),

                      if (isMobile) ...[
                        TextFormField(
                          controller: _costController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Cost Price *',
                            hintText: '0.00',
                            prefixIcon: const Icon(Icons.attach_money),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return double.tryParse(value) == null
                                ? 'Invalid number'
                                : null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Selling Price *',
                            hintText: '0.00',
                            prefixIcon: const Icon(Icons.sell),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return double.tryParse(value) == null
                                ? 'Invalid number'
                                : null;
                          },
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _costController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Cost Price *',
                                  hintText: '0.00',
                                  prefixIcon: const Icon(Icons.attach_money),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return double.tryParse(value) == null
                                      ? 'Invalid number'
                                      : null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Selling Price *',
                                  hintText: '0.00',
                                  prefixIcon: const Icon(Icons.sell),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return double.tryParse(value) == null
                                      ? 'Invalid number'
                                      : null;
                                },
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 32),

                      // Inventory Section
                      const _SectionHeader(
                          title: 'Inventory', icon: Icons.inventory),
                      const SizedBox(height: 16),

                      if (isMobile) ...[
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Stock Quantity *',
                            hintText: '0',
                            prefixIcon: const Icon(Icons.inventory),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return int.tryParse(value) == null
                                ? 'Invalid number'
                                : null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lowStockController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Low Stock Alert *',
                            hintText: '0',
                            prefixIcon: const Icon(Icons.warning_amber),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return int.tryParse(value) == null
                                ? 'Invalid number'
                                : null;
                          },
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _stockController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Stock Quantity *',
                                  hintText: '0',
                                  prefixIcon: const Icon(Icons.inventory),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return int.tryParse(value) == null
                                      ? 'Invalid number'
                                      : null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _lowStockController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Low Stock Alert *',
                                  hintText: '0',
                                  prefixIcon: const Icon(Icons.warning_amber),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return int.tryParse(value) == null
                                      ? 'Invalid number'
                                      : null;
                                },
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 32),

                      // Action buttons
                      if (isMobile) ...[
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveProduct,
                          icon: Icon(isNew ? Icons.add : Icons.save),
                          label: Text(isNew ? 'Add Product' : 'Save Changes'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed:
                              _isSaving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ] else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                              ),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _isSaving ? null : _saveProduct,
                              icon: Icon(isNew ? Icons.add : Icons.save),
                              label:
                                  Text(isNew ? 'Add Product' : 'Save Changes'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
