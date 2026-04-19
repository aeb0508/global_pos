import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';
import '../utils/snackbar_helper.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _search = '';
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
    setState(() => _loading = true);

    try {
      final res = await ApiService.get(ApiConfig.categoriesEndpoint);
      final list = (res['data'] as List? ?? []).cast<Map<String, dynamic>>();

      if (!mounted) return;
      setState(() {
        _categories = list;
        _applyFilter();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      SnackBarHelper.showError(context, 'Failed to load categories');
    }
  }

  void _applyFilter() {
    _filtered = _search.isEmpty
        ? List.from(_categories)
        : _categories.where((c) {
            final name = (c['name'] ?? '').toString().toLowerCase();
            final description =
                (c['description'] ?? '').toString().toLowerCase();
            return name.contains(_search) || description.contains(_search);
          }).toList();
  }

  void _onSearch(String q) {
    setState(() {
      _search = q.toLowerCase().trim();
      _applyFilter();
    });
  }

  Color _categoryColor(String name) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.orange,
      Colors.green,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.deepOrange,
    ];

    if (name.isEmpty) return colors.first;
    return colors[name.codeUnitAt(0) % colors.length];
  }

  IconData _categoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('electron')) return Icons.devices_rounded;
    if (n.contains('cloth') || n.contains('fashion')) {
      return Icons.checkroom_rounded;
    }
    if (n.contains('food') || n.contains('bever')) {
      return Icons.restaurant_rounded;
    }
    if (n.contains('home') || n.contains('garden')) {
      return Icons.home_rounded;
    }
    if (n.contains('sport') || n.contains('outdoor')) {
      return Icons.sports_soccer_rounded;
    }
    if (n.contains('beauty') || n.contains('care')) {
      return Icons.spa_rounded;
    }
    if (n.contains('book') || n.contains('media')) {
      return Icons.menu_book_rounded;
    }
    if (n.contains('toy') || n.contains('game')) {
      return Icons.toys_rounded;
    }
    return Icons.category_rounded;
  }

  void _showForm({Map<String, dynamic>? category}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CategoriesFormPage(
          category: category,
          onSaved: _load,
        ),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Delete "${category['name']}"? Products in this category will be unassigned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await ApiService.delete(
        '${ApiConfig.categoriesEndpoint}?id=${category['id']}',
      );

      if (!mounted) return;

      _load();
      if (res['success'] == true) {
        SnackBarHelper.showSuccess(context, 'Category deleted');
      } else {
        SnackBarHelper.showError(context, res['message'] ?? 'Failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, viewport) {
                final width = viewport.maxWidth;
                final isPhone = width < 600;
                final isTablet = width >= 600 && width < 1024;

                final horizontalPadding = width < 480
                    ? 12.0
                    : width < 900
                        ? 16.0
                        : 24.0;

                final appBarExpandedHeight = width < 360
                    ? 132.0
                    : width < 600
                        ? 138.0
                        : 146.0;

                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      floating: true,
                      pinned: true,
                      expandedHeight: appBarExpandedHeight,
                      titleSpacing: 12,
                      title: const Row(
                        children: [
                          Icon(
                            Icons.category_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Categories',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade600,
                                Colors.orange.shade800,
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
                                12,
                                horizontalPadding,
                                16,
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 900,
                                  ),
                                  child: TextField(
                                    controller: _searchCtrl,
                                    onChanged: _onSearch,
                                    decoration: InputDecoration(
                                      hintText: 'Search categories by name...',
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: Colors.white70,
                                      ),
                                      suffixIcon: _search.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.clear,
                                                color: Colors.white70,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                _searchCtrl.clear();
                                                _onSearch('');
                                              },
                                            )
                                          : null,
                                      filled: true,
                                      fillColor:
                                          Colors.white.withValues(alpha: 0.15),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      hintStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _load,
                          tooltip: 'Refresh',
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () => _showForm(),
                          tooltip: 'Add Category',
                        ),
                      ],
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        16,
                        horizontalPadding,
                        12,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final statsWidth = constraints.maxWidth;

                                if (statsWidth < 520) {
                                  return Column(
                                    children: [
                                      _StatCard(
                                        label: 'Total Categories',
                                        value: '${_categories.length}',
                                        icon: Icons.category_rounded,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(height: 8),
                                      _StatCard(
                                        label: 'With Description',
                                        value:
                                            '${_categories.where((c) => (c['description'] ?? '').toString().isNotEmpty).length}',
                                        icon: Icons.description_rounded,
                                        color: Colors.purple,
                                      ),
                                      const SizedBox(height: 8),
                                      _StatCard(
                                        label: 'Showing',
                                        value: '${_filtered.length}',
                                        icon: Icons.filter_list_rounded,
                                        color: Colors.teal,
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(
                                      child: _StatCard(
                                        label: 'Total Categories',
                                        value: '${_categories.length}',
                                        icon: Icons.category_rounded,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _StatCard(
                                        label: 'With Description',
                                        value:
                                            '${_categories.where((c) => (c['description'] ?? '').toString().isNotEmpty).length}',
                                        icon: Icons.description_rounded,
                                        color: Colors.purple,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _StatCard(
                                        label: 'Showing',
                                        value: '${_filtered.length}',
                                        icon: Icons.filter_list_rounded,
                                        color: Colors.teal,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_filtered.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text('No categories found'),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          0,
                          horizontalPadding,
                          20,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1400),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final gridWidth = constraints.maxWidth;

                                  final spacing = gridWidth < 600 ? 10.0 : 14.0;

                                  final maxCrossAxisExtent = gridWidth < 360
                                      ? 160.0
                                      : gridWidth < 480
                                          ? 190.0
                                          : gridWidth < 768
                                              ? 220.0
                                              : gridWidth < 1200
                                                  ? 240.0
                                                  : 260.0;

                                  final mainAxisExtent = isPhone
                                      ? 150.0
                                      : isTablet
                                          ? 150.0
                                          : 208.0;

                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _filtered.length,
                                    gridDelegate:
                                        SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: maxCrossAxisExtent,
                                      mainAxisExtent: mainAxisExtent,
                                      crossAxisSpacing: spacing,
                                      mainAxisSpacing: spacing,
                                    ),
                                    itemBuilder: (_, i) {
                                      final item = _filtered[i];
                                      final name =
                                          (item['name'] ?? '').toString();

                                      return _CategoryCard(
                                        category: item,
                                        color: _categoryColor(name),
                                        icon: _categoryIcon(name),
                                        onEdit: () => _showForm(category: item),
                                        onDelete: () => _delete(item),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 180;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: narrow ? 10 : 14,
            vertical: narrow ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            border: Border.all(color: color.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: narrow ? 16 : 18, color: color),
              SizedBox(width: narrow ? 8 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: narrow ? 10 : 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: narrow ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final Color color;
  final IconData icon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.color,
    required this.icon,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = (category['name'] ?? '').toString();
    final desc = (category['description'] ?? '').toString();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 210;

        final headerHeight = compact ? 46.0 : 54.0;
        final bodyPadding = compact ? 7.0 : 8.0;
        final titleSize = compact ? 11.0 : 13.0;
        final descSize = compact ? 9.0 : 10.0;
        final buttonHeight = compact ? 28.0 : 32.0;
        final iconSize = compact ? 20.0 : 24.0;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: cs.outline.withValues(alpha: 0.14),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onEdit,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: headerHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.85),
                        color.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(bodyPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: titleSize,
                            height: 1.2,
                          ),
                        ),
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: descSize,
                              color: cs.onSurface.withValues(alpha: 0.6),
                              height: 1.2,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: onEdit,
                                style: FilledButton.styleFrom(
                                  minimumSize: Size(0, buttonHeight),
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Edit',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: compact ? 11 : 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: buttonHeight,
                              height: buttonHeight,
                              child: IconButton.outlined(
                                onPressed: onDelete,
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: compact ? 16 : 18,
                                ),
                                style: IconButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(
                                    color: Colors.red.withValues(alpha: 0.35),
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                tooltip: 'Delete',
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
      },
    );
  }
}

class _CategoriesFormPage extends StatefulWidget {
  final Map<String, dynamic>? category;
  final VoidCallback onSaved;

  const _CategoriesFormPage({
    this.category,
    required this.onSaved,
  });

  @override
  State<_CategoriesFormPage> createState() => _CategoriesFormPageState();
}

class _CategoriesFormPageState extends State<_CategoriesFormPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?['name'] ?? '');
    _descCtrl =
        TextEditingController(text: widget.category?['description'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final body = {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
    };

    try {
      late final Map<String, dynamic> res;
      final isNew = widget.category == null;

      if (isNew) {
        res = await ApiService.post(ApiConfig.categoriesEndpoint, body);
      } else {
        res = await ApiService.put(
          '${ApiConfig.categoriesEndpoint}?id=${widget.category!['id']}',
          body,
        );
      }

      if (!mounted) return;

      if (res['success'] == true) {
        SnackBarHelper.showSuccess(
          context,
          isNew ? 'Category added' : 'Category updated',
        );
        widget.onSaved();
        Navigator.pop(context);
      } else {
        SnackBarHelper.showError(context, res['message'] ?? 'Failed');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.category == null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isPhone = width < 600;
        final isTablet = width < 1024;

        final horizontalPadding = isPhone
            ? 16.0
            : isTablet
                ? 24.0
                : 40.0;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Icon(
                  isNew ? Icons.add_box_rounded : Icons.edit_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isNew ? 'Add Category' : 'Edit Category',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            elevation: 0,
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
                    icon: Icon(isNew ? Icons.add : Icons.save, size: 18),
                    label: Text(isNew ? 'Add' : 'Save'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange.shade600,
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
                    horizontal: horizontalPadding,
                    vertical: isPhone ? 20.0 : 30.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Info
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.category_rounded,
                                  color: Colors.orange.shade600,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isNew
                                          ? 'Create New Category'
                                          : 'Edit Category',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Fill in the details below',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Category Name Field
                        Text(
                          'Category Name',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameCtrl,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: 'Enter category name *',
                            prefixIcon: const Icon(Icons.category_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            hintText: 'e.g., Electronics, Clothing',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Name is required'
                              : null,
                        ),
                        const SizedBox(height: 20),

                        // Description Field
                        Text(
                          'Description',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descCtrl,
                          minLines: 3,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: 'Enter category description',
                            prefixIcon: const Icon(Icons.description_rounded),
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            hintText:
                                'Optional: Add a description for this category',
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
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
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(isNew ? Icons.add : Icons.save),
                                label: Text(
                                    isNew ? 'Add Category' : 'Save Changes'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.orange.shade600,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
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
      },
    );
  }
}
