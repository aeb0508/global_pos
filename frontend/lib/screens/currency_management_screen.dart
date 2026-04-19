import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class CurrencyManagementScreen extends StatefulWidget {
  const CurrencyManagementScreen({super.key});

  @override
  State<CurrencyManagementScreen> createState() =>
      _CurrencyManagementScreenState();
}

class _CurrencyManagementScreenState extends State<CurrencyManagementScreen> {
  static const int _itemsPerPage = 10;

  List<dynamic> _currencies = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterType = 'all'; // all, active, inactive, base
  int _displayedCount = _itemsPerPage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await ApiService.get(ApiConfig.currenciesEndpoint);
    if (mounted) {
      setState(() {
        _currencies = res['success'] ? (res['data'] ?? []) : [];
        _isLoading = false;
        _displayedCount = _itemsPerPage;
      });
    }
  }

  List<dynamic> get _filteredCurrencies {
    var filtered = _currencies.where((currency) {
      final name = (currency['name'] as String? ?? '').toLowerCase();
      final code = (currency['code'] as String? ?? '').toLowerCase();
      final matchesSearch = name.contains(_searchQuery.toLowerCase()) ||
          code.contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      switch (_filterType) {
        case 'active':
          return currency['is_active'] == 1 || currency['is_active'] == true;
        case 'inactive':
          return currency['is_active'] != 1 && currency['is_active'] != true;
        case 'base':
          return currency['is_base'] == 1 || currency['is_base'] == true;
        default:
          return true;
      }
    }).toList();
    return filtered;
  }

  void _loadMore() {
    setState(() => _displayedCount += _itemsPerPage);
  }

  int get _activeCurrencies => _currencies
      .where((c) => c['is_active'] == 1 || c['is_active'] == true)
      .length;

  Map<String, dynamic>? get _baseCurrency =>
      _currencies.firstWhere((c) => c['is_base'] == 1 || c['is_base'] == true,
          orElse: () => null);

  void _showForm({Map<String, dynamic>? currency}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CurrencyFormPage(
          currency: currency,
          onSaved: _load,
        ),
      ),
    );
  }

  Future<void> _setBase(dynamic currency) async {
    final res = await ApiService.put(
      '${ApiConfig.currenciesEndpoint}?id=${currency['id']}',
      {'set_base': true},
    );
    if (res['success'] && mounted) {
      // Reload provider so currency symbol updates app-wide
      Provider.of<AppSettingsProvider>(context, listen: false).loadSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${currency['code']} set as base currency'),
            backgroundColor: Colors.green),
      );
      _load();
    }
  }

  Future<void> _delete(dynamic currency) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Currency'),
        content: Text('Delete ${currency['name']}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      final res = await ApiService.delete(
          '${ApiConfig.currenciesEndpoint}?id=${currency['id']}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Done'),
            backgroundColor: res['success'] == true ? Colors.green : Colors.red,
          ),
        );
        if (res['success'] == true) _load();
      }
    }
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
            Text('Loading currencies...',
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
                Icon(Icons.currency_exchange_rounded,
                    color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Multi-Currency',
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
                    colors: [Colors.teal.shade600, Colors.teal.shade800],
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
                      //   'Multi-Currency',
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
                          hintText: 'Search currencies by code or name...',
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
                onPressed: () => _showForm(),
                tooltip: 'Add Currency',
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _load,
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
                          label: 'Total Currencies',
                          value: _currencies.length.toString(),
                          icon: Icons.currency_exchange_rounded,
                          gradient: [
                            Colors.blue.shade400,
                            Colors.blue.shade600
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GradientMetricCard(
                          label: 'Active Currencies',
                          value: _activeCurrencies.toString(),
                          icon: Icons.check_circle_rounded,
                          gradient: [
                            Colors.green.shade400,
                            Colors.green.shade600
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GradientMetricCard(
                          label: 'Base Currency',
                          value: _baseCurrency?['code'] ?? 'None',
                          icon: Icons.star_rounded,
                          gradient: [
                            Colors.amber.shade400,
                            Colors.amber.shade600
                          ],
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
                          label: 'Active',
                          isSelected: _filterType == 'active',
                          onTap: () => setState(() => _filterType = 'active'),
                        ),
                        const SizedBox(width: 8),
                        _FilterTab(
                          label: 'Inactive',
                          isSelected: _filterType == 'inactive',
                          onTap: () => setState(() => _filterType = 'inactive'),
                        ),
                        const SizedBox(width: 8),
                        _FilterTab(
                          label: 'Base',
                          isSelected: _filterType == 'base',
                          onTap: () => setState(() => _filterType = 'base'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Currencies Panel ────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverToBoxAdapter(
              child: _CurrenciesPanel(
                currencies: _filteredCurrencies,
                displayedCount: _displayedCount,
                onLoadMore: _loadMore,
                onEdit: _showForm,
                onSetBase: _setBase,
                onDelete: _delete,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyFormPage extends StatefulWidget {
  final Map<String, dynamic>? currency;
  final VoidCallback onSaved;

  const _CurrencyFormPage({
    this.currency,
    required this.onSaved,
  });

  @override
  State<_CurrencyFormPage> createState() => _CurrencyFormPageState();
}

class _CurrencyFormPageState extends State<_CurrencyFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _symbol;
  late final TextEditingController _rate;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.currency;
    _code = TextEditingController(text: c?['code'] ?? '');
    _name = TextEditingController(text: c?['name'] ?? '');
    _symbol = TextEditingController(text: c?['symbol'] ?? '');
    _rate = TextEditingController(
      text: c?['exchange_rate']?.toString() ?? '1.0',
    );
    _isActive = c == null || c['is_active'] == 1 || c['is_active'] == true;
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _symbol.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final body = {
      'code': _code.text.trim().toUpperCase(),
      'name': _name.text.trim(),
      'symbol': _symbol.text.trim(),
      'exchange_rate': double.parse(_rate.text),
      'is_active': _isActive ? 1 : 0,
    };

    try {
      final res = widget.currency == null
          ? await ApiService.post(ApiConfig.currenciesEndpoint, body)
          : await ApiService.put(
              '${ApiConfig.currenciesEndpoint}?id=${widget.currency!['id']}',
              body,
            );

      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.currency == null
                ? 'Currency added successfully'
                : 'Currency updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to save currency'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.currency == null;
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isNew ? 'Add Currency' : 'Edit Currency',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal.shade600,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.teal.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isPhone ? 16.0 : 24.0,
                vertical: isPhone ? 20.0 : 30.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.teal.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.currency_exchange,
                              color: Colors.teal.shade600,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isNew ? 'New Currency' : 'Edit Currency',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.teal.shade700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Configure currency details',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.teal.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Code',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _code,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: InputDecoration(
                                  labelText: 'e.g. EUR',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                validator: (v) =>
                                    (v?.isEmpty == true) ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Symbol',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _symbol,
                                decoration: InputDecoration(
                                  labelText: 'e.g. €',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                validator: (v) =>
                                    (v?.isEmpty == true) ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Currency Name',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _name,
                      decoration: InputDecoration(
                        labelText: 'Enter full currency name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (v) =>
                          (v?.isEmpty == true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Exchange Rate',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _rate,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'vs base currency',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        helperText:
                            'e.g. 1.08 means 1 base = 1.08 of this currency',
                      ),
                      validator: (v) {
                        if (v?.isEmpty == true) return 'Required';
                        if (double.tryParse(v!) == null ||
                            double.parse(v) <= 0) {
                          return 'Invalid rate';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.teal.shade200),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Active',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          Switch(
                            value: _isActive,
                            onChanged: (v) => setState(() => _isActive = v),
                            activeThumbColor: Colors.teal,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel'),
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isLoading ? null : _save,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: const Text('Save Currency'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: Colors.teal.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
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
              color:
                  isSelected ? cs.primary : cs.outline.withValues(alpha: 0.3)),
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

// ── Currencies Panel ───────────────────────────────────────────────────────
class _CurrenciesPanel extends StatelessWidget {
  final List<dynamic> currencies;
  final int displayedCount;
  final VoidCallback onLoadMore;
  final void Function({Map<String, dynamic>? currency}) onEdit;
  final Function(dynamic) onSetBase;
  final Function(dynamic) onDelete;

  const _CurrenciesPanel({
    required this.currencies,
    required this.displayedCount,
    required this.onLoadMore,
    required this.onEdit,
    required this.onSetBase,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayedCurrencies = currencies.take(displayedCount).toList();
    final hasMore = currencies.length > displayedCount;

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
                Icon(Icons.currency_exchange_rounded,
                    size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text('Currencies',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface)),
                const Spacer(),
                Text(
                    '${displayedCurrencies.length}/${currencies.length} currencies',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
          const Divider(height: 1),
          if (currencies.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                  child: Text('No currencies found',
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.4)))),
            )
          else
            Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedCurrencies.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1, color: cs.outline.withValues(alpha: 0.08)),
                  itemBuilder: (context, index) {
                    final currency =
                        displayedCurrencies[index] as Map<String, dynamic>;
                    final isBase =
                        currency['is_base'] == 1 || currency['is_base'] == true;
                    final isActive = currency['is_active'] == 1 ||
                        currency['is_active'] == true;
                    final rate =
                        double.tryParse(currency['exchange_rate'].toString()) ??
                            0;
                    final statusColor = isActive ? Colors.green : Colors.red;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isBase
                                  ? Colors.blue.withValues(alpha: 0.1)
                                  : statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                                isBase
                                    ? Icons.star_rounded
                                    : Icons.currency_exchange_rounded,
                                size: 18,
                                color: isBase ? Colors.blue : statusColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                        '${currency['code']} - ${currency['name']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13),
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(width: 8),
                                    if (isBase)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text('Base',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('Rate: ${rate.toStringAsFixed(4)}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: cs.onSurface
                                                .withValues(alpha: 0.5))),
                                    Text('  ·  ',
                                        style: TextStyle(
                                            color: cs.onSurface
                                                .withValues(alpha: 0.3))),
                                    Text(isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: statusColor,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(currency['symbol'] ?? '',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: cs.onSurface)),
                              Text('Symbol',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          cs.onSurface.withValues(alpha: 0.4))),
                            ],
                          ),
                          const SizedBox(width: 12),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                onEdit(currency: currency);
                              } else if (value == 'set_base') {
                                onSetBase(currency);
                              } else if (value == 'delete') {
                                onDelete(currency);
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
                              if (!isBase)
                                const PopupMenuItem(
                                  value: 'set_base',
                                  child: Row(
                                    children: [
                                      Icon(Icons.star_rounded,
                                          size: 18, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Set as Base'),
                                    ],
                                  ),
                                ),
                              if (!isBase)
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
                                size: 18,
                                color: cs.onSurface.withValues(alpha: 0.5)),
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
                            'Load More (${currencies.length - displayedCount} remaining)'),
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
