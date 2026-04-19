import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class TaxManagementScreen extends StatefulWidget {
  const TaxManagementScreen({super.key});

  @override
  State<TaxManagementScreen> createState() => _TaxManagementScreenState();
}

class _TaxManagementScreenState extends State<TaxManagementScreen> {
  static const int _itemsPerPage = 10;

  List<dynamic> _taxRates = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterType = 'all'; // all, high, low, default
  int _displayedCount = _itemsPerPage;
  final Map<String, TextEditingController> _rateControllers = {};

  @override
  void initState() {
    super.initState();
    _loadTaxRates();
  }

  Future<void> _loadTaxRates() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get(ApiConfig.taxRatesEndpoint);
      if (mounted) {
        setState(() {
          _taxRates = response['success'] == true
              ? (response['data'] as List? ?? [])
              : [];
          _isLoading = false;
          _displayedCount = _itemsPerPage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tax rates: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<dynamic> get _filteredTaxRates {
    var filtered = _taxRates.where((rate) {
      final name = (rate['name'] as String? ?? '').toLowerCase();
      final matchesSearch = name.contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      final rateValue = double.tryParse(rate['rate'].toString()) ?? 0;
      switch (_filterType) {
        case 'high':
          return rateValue >= 15;
        case 'low':
          return rateValue < 15;
        case 'default':
          return rate['is_default'] == 1;
        default:
          return true;
      }
    }).toList();
    return filtered;
  }

  void _loadMore() {
    setState(() => _displayedCount += _itemsPerPage);
  }

  double get _averageTaxRate {
    if (_taxRates.isEmpty) return 0;
    final total = _taxRates.fold<double>(
      0,
      (sum, rate) => sum + (double.tryParse(rate['rate'].toString()) ?? 0),
    );
    return total / _taxRates.length;
  }

  double get _highestTaxRate {
    if (_taxRates.isEmpty) return 0;
    return _taxRates.fold<double>(
      0,
      (max, rate) {
        final rateValue = double.tryParse(rate['rate'].toString()) ?? 0;
        return rateValue > max ? rateValue : max;
      },
    );
  }

  Future<void> _deleteTaxRate(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this tax rate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response =
            await ApiService.delete('${ApiConfig.taxRatesEndpoint}?id=$id');
        if (response['success'] && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tax rate deleted successfully')),
          );
          _loadTaxRates();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _showTaxRateDialog([Map<String, dynamic>? taxRate]) {
    showDialog(
      context: context,
      builder: (context) => _TaxRateDialog(
        taxRate: taxRate,
        onSaved: () {
          Navigator.pop(context);
          _loadTaxRates();
        },
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _rateControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: cs.primary),
            const SizedBox(height: 16),
            Text('Loading tax rates...',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6))),
          ],
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar with Search ─────────────────────────────
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 120,
            title: const Row(
              children: [
                Icon(Icons.receipt_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Tax Management',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ],
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade600, Colors.purple.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // const Text(
                      //   'Tax Management',
                      //   style: TextStyle(
                      //     fontSize: 24,
                      //     fontWeight: FontWeight.bold,
                      //     color: Colors.white,
                      //   ),
                      // ),
                      const SizedBox(height: 8),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search tax rates by category...',
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          hintStyle: const TextStyle(color: Colors.white70),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => _showTaxRateDialog(),
                tooltip: 'Add Tax Rate',
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadTaxRates,
                tooltip: 'Refresh',
              ),
            ],
          ),

          // ── Metric Cards ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _GradientMetricCard(
                          label: 'Total Tax Rates',
                          value: _taxRates.length.toString(),
                          icon: Icons.receipt_rounded,
                          gradient: [
                            Colors.blue.shade400,
                            Colors.blue.shade600
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GradientMetricCard(
                          label: 'Average Rate',
                          value: '${_averageTaxRate.toStringAsFixed(1)}%',
                          icon: Icons.trending_up_rounded,
                          gradient: [
                            Colors.amber.shade400,
                            Colors.amber.shade600
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GradientMetricCard(
                          label: 'Highest Rate',
                          value: '${_highestTaxRate.toStringAsFixed(1)}%',
                          icon: Icons.arrow_upward_rounded,
                          gradient: [Colors.red.shade400, Colors.red.shade600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Filter Tabs ────────────────────────────────────────
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterTab(
                          label: 'All',
                          isSelected: _filterType == 'all',
                          onTap: () => setState(() => _filterType = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterTab(
                          label: 'High Rate (≥15%)',
                          isSelected: _filterType == 'high',
                          onTap: () => setState(() => _filterType = 'high'),
                        ),
                        const SizedBox(width: 8),
                        _FilterTab(
                          label: 'Low Rate (<15%)',
                          isSelected: _filterType == 'low',
                          onTap: () => setState(() => _filterType = 'low'),
                        ),
                        const SizedBox(width: 8),
                        _FilterTab(
                          label: 'Default',
                          isSelected: _filterType == 'default',
                          onTap: () => setState(() => _filterType = 'default'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tax Rates Panel ────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverToBoxAdapter(
              child: _TaxRatesPanel(
                taxRates: _filteredTaxRates,
                displayedCount: _displayedCount,
                onLoadMore: _loadMore,
                onEdit: _showTaxRateDialog,
                onDelete: _deleteTaxRate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gradient Metric Card ───────────────────────────────────────────────────
class _GradientMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _GradientMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Filter Tab ─────────────────────────────────────────────────────────────
class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : cs.surface,
          border: Border.all(
              color: isSelected ? cs.primary : cs.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? cs.primary : cs.onSurface,
          ),
        ),
      ),
    );
  }
}

// ── Tax Rates Panel ────────────────────────────────────────────────────────
class _TaxRatesPanel extends StatelessWidget {
  final List<dynamic> taxRates;
  final int displayedCount;
  final VoidCallback onLoadMore;
  final Function(Map<String, dynamic>?) onEdit;
  final Function(int) onDelete;

  const _TaxRatesPanel({
    required this.taxRates,
    required this.displayedCount,
    required this.onLoadMore,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayedRates = taxRates.take(displayedCount).toList();
    final hasMore = taxRates.length > displayedCount;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(Icons.receipt_long_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text('Tax Rates',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface)),
                const Spacer(),
                Text('${displayedRates.length}/${taxRates.length} rates',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
          const Divider(height: 1),
          if (taxRates.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                  child: Text('No tax rates found',
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)))),
            )
          else
            Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedRates.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: cs.outline.withValues(alpha: 0.08)),
                  itemBuilder: (context, index) {
                    final rate = displayedRates[index] as Map<String, dynamic>;
                    final rateValue =
                        double.tryParse(rate['rate'].toString()) ?? 0;
                    final isDefault = rate['is_default'] == 1;
                    final rateColor = rateValue >= 15
                        ? Colors.red
                        : rateValue >= 10
                            ? Colors.orange
                            : Colors.green;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: rateColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.receipt_rounded,
                                size: 18, color: rateColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(rate['name'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13),
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(width: 8),
                                    if (isDefault)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text('Default',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.green,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(rate['description'] ?? 'No description',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: cs.onSurface.withValues(alpha: 0.45)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${rateValue.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: rateColor)),
                              Text('Tax Rate',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: cs.onSurface.withValues(alpha: 0.4))),
                            ],
                          ),
                          const SizedBox(width: 12),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                onEdit(rate);
                              } else if (value == 'delete') {
                                onDelete(int.parse(rate['id'].toString()));
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_rounded,
                                        size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            icon: Icon(Icons.more_vert_rounded,
                                size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onLoadMore,
                        icon: const Icon(Icons.expand_more_rounded),
                        label: Text(
                            'Load More (${taxRates.length - displayedCount} remaining)'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Tax Rate Dialog ────────────────────────────────────────────────────────
class _TaxRateDialog extends StatefulWidget {
  final Map<String, dynamic>? taxRate;
  final VoidCallback onSaved;

  const _TaxRateDialog({this.taxRate, required this.onSaved});

  @override
  State<_TaxRateDialog> createState() => _TaxRateDialogState();
}

class _TaxRateDialogState extends State<_TaxRateDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _rateController;
  late TextEditingController _descriptionController;
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.taxRate?['name'] ?? '');
    _rateController =
        TextEditingController(text: widget.taxRate?['rate']?.toString() ?? '');
    _descriptionController =
        TextEditingController(text: widget.taxRate?['description'] ?? '');
    _isDefault = widget.taxRate?['is_default'] == 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTaxRate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'name': _nameController.text,
      'rate': double.parse(_rateController.text),
      'description': _descriptionController.text,
      'is_default': _isDefault ? 1 : 0,
    };

    try {
      final response = widget.taxRate == null
          ? await ApiService.post(ApiConfig.taxRatesEndpoint, data)
          : await ApiService.put(
              '${ApiConfig.taxRatesEndpoint}?id=${widget.taxRate!['id']}',
              data);

      if (response['success'] && mounted) {
        // Reload provider so tax rate updates app-wide
        Provider.of<AppSettingsProvider>(context, listen: false).loadSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'])),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.purple.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.receipt_rounded,
                      color: cs.onPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.taxRate == null ? 'Add Tax Rate' : 'Edit Tax Rate',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Tax Name',
                      hintText: 'e.g., Sales Tax, VAT',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.label_outline),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Tax name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _rateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Tax Rate (%)',
                      hintText: 'e.g., 10',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.percent_rounded),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Rate is required';
                      final rate = double.tryParse(value!);
                      if (rate == null || rate < 0 || rate > 100) {
                        return 'Enter a valid rate between 0 and 100';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Add notes about this tax rate...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.description_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isDefault
                          ? Colors.green.withValues(alpha: 0.1)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _isDefault
                              ? Colors.green.withValues(alpha: 0.3)
                              : cs.outline.withValues(alpha: 0.2)),
                    ),
                    child: CheckboxListTile(
                      title: const Text('Set as Default Tax Rate',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: const Text(
                          'Applied to new orders automatically',
                          style: TextStyle(fontSize: 12)),
                      value: _isDefault,
                      onChanged: (value) {
                        setState(() => _isDefault = value ?? false);
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  child: Text('Cancel',
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7))),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _saveTaxRate,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Save Tax Rate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
