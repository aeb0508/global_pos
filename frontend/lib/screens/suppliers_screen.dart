import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';
import 'home_screen.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  List<dynamic> _all = [];
  List<dynamic> _filtered = [];
  Map<String, dynamic>? _selected;
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get(ApiConfig.suppliersEndpoint);
      if (mounted) {
        setState(() {
          _all = res['success'] == true ? (res['data'] as List? ?? []) : [];
          _filtered = List.from(_all);
          _isLoading = false;

          if (_selected != null) {
            Map<String, dynamic>? selectedMatch;
            for (final s in _all) {
              if (s['id'].toString() == _selected!['id'].toString()) {
                selectedMatch = Map<String, dynamic>.from(s);
                break;
              }
            }
            _selected = selectedMatch;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _applySearch(String query) {
    if (query.isEmpty) {
      setState(() => _filtered = List.from(_all));
      return;
    }

    final q = query.toLowerCase();
    setState(() {
      _filtered = _all.where((s) {
        return (s['name'] ?? '').toString().toLowerCase().contains(q) ||
            (s['email'] ?? '').toString().toLowerCase().contains(q) ||
            (s['phone'] ?? '').toString().toLowerCase().contains(q) ||
            (s['contact_person'] ?? '').toString().toLowerCase().contains(q);
      }).toList();
    });
  }

  void _showForm([Map<String, dynamic>? supplier]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _SupplierFormPage(
          supplier: supplier,
          onSaved: _load,
        ),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> supplier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Delete "${supplier['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await ApiService.delete(
        '${ApiConfig.suppliersEndpoint}?id=${supplier['id']}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Done'),
            backgroundColor: res['success'] == true ? Colors.green : Colors.red,
          ),
        );

        if (res['success'] == true) {
          if (_selected?['id'].toString() == supplier['id'].toString()) {
            setState(() => _selected = null);
          }
          _load();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  int get _withEmail =>
      _all.where((s) => (s['email'] ?? '').toString().isNotEmpty).length;

  int get _withContact => _all
      .where((s) => (s['contact_person'] ?? '').toString().isNotEmpty)
      .length;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                if (width < 700) {
                  return _buildPhoneLayout(cs, width);
                } else if (width < 1100) {
                  return _buildTabletLayout(cs, width);
                } else {
                  return _buildDesktopLayout(cs, width);
                }
              },
            ),
    );
  }

  Widget _buildPhoneLayout(ColorScheme cs, double width) {
    final horizontalPadding = width < 360 ? 12.0 : 16.0;

    return Column(
      children: [
        _SuppliersHeader(
          titleFontSize: 20,
          horizontalPadding: horizontalPadding,
          searchController: _searchCtrl,
          onSearch: _applySearch,
          onRefresh: _load,
          onAdd: () => _showForm(),
          searchHint: 'Search suppliers...',
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 10,
          ),
          color: cs.surface,
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _StatChip(
                label: 'Total',
                value: '${_all.length}',
                color: cs.primary,
              ),
              _StatChip(
                label: 'Email',
                value: '$_withEmail',
                color: Colors.green,
              ),
              _StatChip(
                label: 'Contact',
                value: '$_withContact',
                color: Colors.orange,
              ),
            ],
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? _NoSuppliers(cs: cs)
              : ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: math.max(10, horizontalPadding - 4),
                    vertical: 8,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (ctx, i) => _SupplierTile(
                    supplier: _filtered[i],
                    isSelected: false,
                    onTap: () => _showMobileDetail(_filtered[i]),
                    onEdit: () => _showForm(_filtered[i]),
                    onDelete: () => _delete(_filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(ColorScheme cs, double width) {
    final leftWidth = width.clamp(700, 1099) * 0.42;

    return Row(
      children: [
        SizedBox(
          width: leftWidth,
          child: Column(
            children: [
              _SuppliersHeader(
                titleFontSize: 22,
                horizontalPadding: 16,
                searchController: _searchCtrl,
                onSearch: _applySearch,
                onRefresh: _load,
                onAdd: () => _showForm(),
                searchHint: 'Search name, email, contact...',
              ),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: cs.surface,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _StatChip(
                      label: 'Total',
                      value: '${_all.length}',
                      color: cs.primary,
                    ),
                    _StatChip(
                      label: 'Email',
                      value: '$_withEmail',
                      color: Colors.green,
                    ),
                    _StatChip(
                      label: 'Contact',
                      value: '$_withContact',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _filtered.isEmpty
                    ? _NoSuppliers(cs: cs)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) => _SupplierTile(
                          supplier: _filtered[i],
                          isSelected: _selected?['id'].toString() ==
                              _filtered[i]['id'].toString(),
                          onTap: () => setState(() => _selected = _filtered[i]),
                          onEdit: () => _showForm(_filtered[i]),
                          onDelete: () => _delete(_filtered[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: cs.outline.withValues(alpha: 0.15)),
        Expanded(
          child: _selected == null
              ? _EmptyDetail(cs: cs)
              : _SupplierDetail(
                  supplier: _selected!,
                  onEdit: () => _showForm(_selected),
                  onDelete: () => _delete(_selected!),
                  cs: cs,
                ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(ColorScheme cs, double width) {
    final leftWidth = width < 1300 ? 360.0 : 400.0;

    return Row(
      children: [
        SizedBox(
          width: leftWidth,
          child: Column(
            children: [
              _SuppliersHeader(
                titleFontSize: 24,
                horizontalPadding: 16,
                searchController: _searchCtrl,
                onSearch: _applySearch,
                onRefresh: _load,
                onAdd: () => _showForm(),
                searchHint: 'Search name, email, contact...',
              ),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: cs.surface,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _StatChip(
                      label: 'Total',
                      value: '${_all.length}',
                      color: cs.primary,
                    ),
                    _StatChip(
                      label: 'Email',
                      value: '$_withEmail',
                      color: Colors.green,
                    ),
                    _StatChip(
                      label: 'Contact',
                      value: '$_withContact',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _filtered.isEmpty
                    ? _NoSuppliers(cs: cs)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) => _SupplierTile(
                          supplier: _filtered[i],
                          isSelected: _selected?['id'].toString() ==
                              _filtered[i]['id'].toString(),
                          onTap: () => setState(() => _selected = _filtered[i]),
                          onEdit: () => _showForm(_filtered[i]),
                          onDelete: () => _delete(_filtered[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: cs.outline.withValues(alpha: 0.15)),
        Expanded(
          child: _selected == null
              ? _EmptyDetail(cs: cs)
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: _SupplierDetail(
                      supplier: _selected!,
                      onEdit: () => _showForm(_selected),
                      onDelete: () => _delete(_selected!),
                      cs: cs,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  void _showMobileDetail(Map<String, dynamic> supplier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _SupplierDetail(
            supplier: supplier,
            onEdit: () {
              Navigator.pop(ctx);
              _showForm(supplier);
            },
            onDelete: () {
              Navigator.pop(ctx);
              _delete(supplier);
            },
            cs: Theme.of(context).colorScheme,
          ),
        ),
      ),
    );
  }
}

class _SuppliersHeader extends StatelessWidget {
  final double titleFontSize;
  final double horizontalPadding;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final VoidCallback onRefresh;
  final VoidCallback onAdd;
  final String searchHint;

  const _SuppliersHeader({
    required this.titleFontSize,
    required this.horizontalPadding,
    required this.searchController,
    required this.onSearch,
    required this.onRefresh,
    required this.onAdd,
    required this.searchHint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade600,
            Colors.deepPurple.shade800,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        16,
        math.max(12, horizontalPadding - 4),
        16,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Suppliers',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.refresh, color: Colors.white, size: 20),
                  onPressed: onRefresh,
                  tooltip: 'Refresh',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  onPressed: onAdd,
                  tooltip: 'Add Supplier',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),
            StatefulBuilder(
              builder: (context, setLocalState) {
                return TextField(
                  controller: searchController,
                  onChanged: (v) {
                    setLocalState(() {});
                    onSearch(v);
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.white70,
                      size: 18,
                    ),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white70,
                              size: 18,
                            ),
                            onPressed: () {
                              searchController.clear();
                              setLocalState(() {});
                              onSearch('');
                            },
                          )
                        : null,
                    hintText: searchHint,
                    hintStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSuppliers extends StatelessWidget {
  final ColorScheme cs;
  const _NoSuppliers({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 48,
            color: cs.onSurface.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Text(
            'No suppliers found',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.45)),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierTile extends StatelessWidget {
  final Map<String, dynamic> supplier;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SupplierTile({
    required this.supplier,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = (supplier['name'] ?? '').toString();
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? cs.primary.withValues(alpha: 0.08) : cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? cs.primary.withValues(alpha: 0.4)
              : cs.outline.withValues(alpha: 0.12),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isSelected
                    ? cs.primary
                    : cs.primary.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? cs.onPrimary : cs.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isSelected ? cs.primary : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((supplier['contact_person'] ?? '')
                        .toString()
                        .isNotEmpty)
                      Text(
                        supplier['contact_person'].toString(),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                icon: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
                tooltip: 'Options',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  final ColorScheme cs;
  const _EmptyDetail({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_shipping_outlined,
                size: 52,
                color: cs.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select a supplier',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Click any supplier to view details',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierDetail extends StatelessWidget {
  final Map<String, dynamic> supplier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ColorScheme cs;

  const _SupplierDetail({
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final name = (supplier['name'] ?? '').toString();
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    final fields = <_DetailField>[
      if ((supplier['contact_person'] ?? '').toString().isNotEmpty)
        _DetailField(
          Icons.person_outline,
          'Contact Person',
          supplier['contact_person'].toString(),
        ),
      if ((supplier['email'] ?? '').toString().isNotEmpty)
        _DetailField(
          Icons.email_outlined,
          'Email',
          supplier['email'].toString(),
        ),
      if ((supplier['phone'] ?? '').toString().isNotEmpty)
        _DetailField(
          Icons.phone_outlined,
          'Phone',
          supplier['phone'].toString(),
        ),
      if ((supplier['address'] ?? '').toString().isNotEmpty)
        _DetailField(
          Icons.location_on_outlined,
          'Address',
          supplier['address'].toString(),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 700;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 16 : 24),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  bottom: BorderSide(color: cs.outline.withValues(alpha: 0.12)),
                ),
              ),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  cs.primary.withValues(alpha: 0.15),
                              child: Text(
                                initials,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  for (final f in fields.take(2))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: Row(
                                        children: [
                                          Icon(
                                            f.icon,
                                            size: 13,
                                            color: cs.onSurface
                                                .withValues(alpha: 0.45),
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              f.value,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: cs.onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: onEdit,
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Edit'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: onDelete,
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: cs.primary.withValues(alpha: 0.15),
                          child: Text(
                            initials,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              for (final f in fields.take(2))
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Row(
                                    children: [
                                      Icon(
                                        f.icon,
                                        size: 13,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.45),
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          f.value,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: cs.onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton.outlined(
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Edit',
                            ),
                            const SizedBox(height: 6),
                            IconButton.outlined(
                              onPressed: onDelete,
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red,
                              ),
                              tooltip: 'Delete',
                              style: IconButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 16 : 20),
              child: LayoutBuilder(
                builder: (context, c) {
                  final twoRows = c.maxWidth < 560;

                  if (twoRows) {
                    return Column(
                      children: [
                        _StatCard(
                          label: 'Products Supplied',
                          value: (supplier['product_count'] ?? '0').toString(),
                          icon: Icons.inventory_2_outlined,
                          color: cs.primary,
                        ),
                        const SizedBox(height: 12),
                        _ProductsLinkCard(
                          supplier: supplier,
                          cs: cs,
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Products Supplied',
                          value: (supplier['product_count'] ?? '0').toString(),
                          icon: Icons.inventory_2_outlined,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ProductsLinkCard(
                          supplier: supplier,
                          cs: cs,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 20, 0, compact ? 16 : 20, 12),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Contact Details',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if ((supplier['product_count'] ?? 0).toString() != '0')
                    TextButton.icon(
                      onPressed: () => _showSupplierProducts(context, supplier),
                      icon: const Icon(Icons.inventory_2_outlined, size: 14),
                      label: Text('${supplier['product_count']} Products'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: fields.isEmpty
                  ? Center(
                      child: Text(
                        'No contact details available',
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.4)),
                      ),
                    )
                  : ListView(
                      padding:
                          EdgeInsets.symmetric(horizontal: compact ? 16 : 20),
                      children: fields
                          .map((f) => _DetailRow(field: f, cs: cs))
                          .toList(),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _DetailField {
  final IconData icon;
  final String label;
  final String value;
  const _DetailField(this.icon, this.label, this.value);
}

class _DetailRow extends StatelessWidget {
  final _DetailField field;
  final ColorScheme cs;

  const _DetailRow({required this.field, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(field.icon, size: 16, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  field.value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsLinkCard extends StatelessWidget {
  final Map<String, dynamic> supplier;
  final ColorScheme cs;

  const _ProductsLinkCard({required this.supplier, required this.cs});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showSupplierProducts(context, supplier),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 20, color: cs.primary),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: cs.primary.withValues(alpha: 0.6),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'View Products',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tap to browse',
              style: TextStyle(
                fontSize: 11,
                color: cs.primary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showSupplierProducts(
    BuildContext context, Map<String, dynamic> supplier) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => _SupplierProductsPage(supplier: supplier),
    ),
  );
}

class _SupplierProductsPage extends StatefulWidget {
  final Map<String, dynamic> supplier;
  const _SupplierProductsPage({required this.supplier});

  @override
  State<_SupplierProductsPage> createState() => _SupplierProductsPageState();
}

class _SupplierProductsPageState extends State<_SupplierProductsPage> {
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.get(
        '${ApiConfig.suppliersEndpoint}?products=${widget.supplier['id']}',
      );
      if (mounted) {
        setState(() {
          _products =
              res['success'] == true ? (res['data'] as List? ?? []) : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = widget.supplier['name']?.toString() ?? '';
    final count = _products.length;

    return LayoutBuilder(
      builder: (context, viewport) {
        final screenWidth = viewport.maxWidth;
        final horizontalPadding = screenWidth < 600 ? 12.0 : 20.0;
        final expandedHeight = screenWidth < 600 ? 150.0 : 165.0;
        final titleSize = screenWidth < 600 ? 16.0 : 18.0;
        final subtitleSize = screenWidth < 600 ? 12.0 : 13.0;
        final iconBoxSize = screenWidth < 600 ? 36.0 : 40.0;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                pinned: true,
                expandedHeight: expandedHeight,
                backgroundColor: cs.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cs.primary,
                          cs.primary.withValues(alpha: 0.82),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          16,
                          horizontalPadding,
                          16,
                        ),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: iconBoxSize,
                                height: iconBoxSize,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: titleSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isLoading
                                          ? 'Loading...'
                                          : '$count product${count == 1 ? '' : 's'}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.82),
                                        fontSize: subtitleSize,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_products.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: cs.onSurface.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products linked to this supplier',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.45),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    20,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1500),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final spacing = width < 700 ? 10.0 : 12.0;

                            final maxCrossAxisExtent = width < 420
                                ? 210.0
                                : width < 700
                                    ? 240.0
                                    : width < 1100
                                        ? 260.0
                                        : 280.0;

                            final mainAxisExtent = width < 420
                                ? 185.0
                                : width < 700
                                    ? 200.0
                                    : width < 1100
                                        ? 210.0
                                        : 220.0;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _products.length,
                              gridDelegate:
                                  SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: maxCrossAxisExtent,
                                mainAxisExtent: mainAxisExtent,
                                crossAxisSpacing: spacing,
                                mainAxisSpacing: spacing,
                              ),
                              itemBuilder: (ctx, i) => _ProductCard(
                                p: _products[i],
                                cs: cs,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic p;
  final ColorScheme cs;

  const _ProductCard({required this.p, required this.cs});

  @override
  Widget build(BuildContext context) {
    final stock = int.tryParse(p['stock_quantity']?.toString() ?? '0') ?? 0;
    final threshold =
        int.tryParse(p['low_stock_threshold']?.toString() ?? '10') ?? 10;
    final isOut = stock <= 0;
    final isLow = !isOut && stock <= threshold;
    final stockColor =
        isOut ? Colors.red : (isLow ? Colors.orange : Colors.green);
    final price = double.tryParse(p['selling_price']?.toString() ?? '0') ?? 0.0;
    final cost = double.tryParse(p['cost_price']?.toString() ?? '0') ?? 0.0;
    final imageUrl = p['image_url']?.toString();
    final category = p['category_name']?.toString();
    final currency = context.watch<AppSettingsProvider>().currencySymbol;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 230;

        final imageHeight = compact ? 60.0 : 70.0;
        final outerPadding = compact ? 8.0 : 10.0;
        final titleSize = compact ? 11.0 : 12.0;
        final priceSize = compact ? 12.0 : 13.0;
        final metaSize = compact ? 9.0 : 10.0;
        final pillFont = compact ? 8.0 : 9.0;

        return InkWell(
          onTap: () {
            Navigator.pop(context);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => HomeScreen(
                  initialIndex: 2,
                  initialProductSearch: p['name']?.toString() ?? '',
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.outline.withValues(alpha: 0.14)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    Container(
                      height: imageHeight,
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                      child: (imageUrl != null && imageUrl.isNotEmpty)
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.inventory_2_outlined,
                                size: compact ? 24 : 30,
                                color: cs.onSurface.withValues(alpha: 0.2),
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: compact ? 24 : 30,
                                color: cs.onSurface.withValues(alpha: 0.2),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 6 : 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: stockColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isOut
                              ? 'Out'
                              : isLow
                                  ? 'Low'
                                  : '$stock',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: pillFont,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (category != null && category.isNotEmpty)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: width * 0.55),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 6 : 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surface.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: cs.outline.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: compact ? 7.5 : 8.5,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(outerPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['name']?.toString() ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: titleSize,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${price.toStringAsFixed(2)} $currency',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: priceSize,
                            color: cs.primary,
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(height: 2),
                          Text(
                            'cost ${cost.toStringAsFixed(2)} $currency',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: metaSize,
                              color: cs.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          isOut ? 'Out of stock' : '$stock in stock',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: metaSize,
                            color: stockColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: isOut
                                ? 0
                                : (stock / (threshold * 4).clamp(1, 9999))
                                    .clamp(0.0, 1.0),
                            minHeight: 3,
                            backgroundColor: cs.outline.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation(stockColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SupplierFormPage extends StatefulWidget {
  final Map<String, dynamic>? supplier;
  final VoidCallback onSaved;

  const _SupplierFormPage({this.supplier, required this.onSaved});

  @override
  State<_SupplierFormPage> createState() => _SupplierFormPageState();
}

class _SupplierFormPageState extends State<_SupplierFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _contact;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.supplier?['name'] ?? '');
    _email = TextEditingController(text: widget.supplier?['email'] ?? '');
    _phone = TextEditingController(text: widget.supplier?['phone'] ?? '');
    _address = TextEditingController(text: widget.supplier?['address'] ?? '');
    _contact =
        TextEditingController(text: widget.supplier?['contact_person'] ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'address': _address.text.trim(),
      'contact_person': _contact.text.trim(),
    };

    try {
      final res = widget.supplier == null
          ? await ApiService.post(ApiConfig.suppliersEndpoint, data)
          : await ApiService.put(
              '${ApiConfig.suppliersEndpoint}?id=${widget.supplier!['id']}',
              data,
            );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Done'),
          backgroundColor: res['success'] == true ? Colors.green : Colors.red,
        ),
      );

      if (res['success'] == true) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.supplier == null;
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isNew ? 'Add Supplier' : 'Edit Supplier',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey.shade700,
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
                  foregroundColor: Colors.blueGrey.shade700,
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
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueGrey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.business_rounded,
                              color: Colors.blueGrey,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isNew ? 'Create Supplier' : 'Update Supplier',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blueGrey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Provide supplier details',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Supplier Name',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _name,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Supplier Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business_rounded),
                      ),
                      validator: (v) =>
                          v?.trim().isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Contact Person',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _contact,
                      decoration: const InputDecoration(
                        labelText: 'Contact Person',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Email',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Phone',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Address',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _address,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                        alignLabelWithHint: true,
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
                            label: const Text('Save Supplier'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
