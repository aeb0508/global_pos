import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> _users = [];
  List<dynamic> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiService.get('${ApiConfig.baseUrl}/users.php');
      if (response['success']) {
        setState(() {
          _users = response['data'];
          _filtered = _users;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _users
          : _users
              .where((u) =>
                  (u['username'] ?? '').toLowerCase().contains(q) ||
                  (u['full_name'] ?? '').toLowerCase().contains(q) ||
                  (u['email'] ?? '').toLowerCase().contains(q) ||
                  (u['role'] ?? '').toLowerCase().contains(q))
              .toList();
    });
  }

  Future<void> _deleteUser(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final response =
        await ApiService.delete('${ApiConfig.baseUrl}/users.php?id=$id');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['success']
            ? 'User deleted successfully'
            : (response['message'] ?? 'Failed')),
        backgroundColor: response['success'] ? Colors.green : Colors.red,
      ));
      if (response['success']) _loadUsers();
    }
  }

  void _showUserForm([Map<String, dynamic>? user]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _UserFormPage(
          user: user,
          onSaved: _loadUsers,
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'manager':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Header
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueGrey.shade600, Colors.blueGrey.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
          child: Row(
            children: [
              const Icon(Icons.manage_accounts_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Users',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20)),
                    Text('Manage system users and roles',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadUsers,
                  tooltip: 'Refresh'),
              IconButton(
                  icon:
                      const Icon(Icons.person_add_rounded, color: Colors.white),
                  onPressed: () => _showUserForm(),
                  tooltip: 'Add User'),
            ],
          ),
        ),

        // Search
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, email or role...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      })
                  : null,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.red[300]),
                        const SizedBox(height: 12),
                        Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                            onPressed: _loadUsers,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry')),
                      ],
                    ))
                  : _filtered.isEmpty
                      ? Center(
                          child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                                _searchController.text.isEmpty
                                    ? 'No users found'
                                    : 'No results for "${_searchController.text}"',
                                style: TextStyle(color: Colors.grey[500])),
                          ],
                        ))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final user =
                                _filtered[index] as Map<String, dynamic>;
                            final role = user['role']?.toString() ?? 'cashier';
                            final isActive = user['is_active'] == 1 ||
                                user['is_active'] == true;
                            final initials =
                                (user['full_name']?.toString().isNotEmpty ==
                                            true
                                        ? user['full_name']
                                            .toString()
                                            .trim()
                                            .split(' ')
                                            .map((w) => w[0])
                                            .take(2)
                                            .join()
                                        : '?')
                                    .toUpperCase();

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: _roleColor(role)
                                          .withValues(alpha: 0.15),
                                      child: Text(initials,
                                          style: TextStyle(
                                              color: _roleColor(role),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(user['full_name'] ?? '',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15)),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _roleColor(role)
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(role.toUpperCase(),
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            _roleColor(role))),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: (isActive
                                                          ? Colors.green
                                                          : Colors.grey)
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                    isActive
                                                        ? 'Active'
                                                        : 'Inactive',
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isActive
                                                            ? Colors.green
                                                            : Colors.grey)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text('@${user['username'] ?? ''}',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600])),
                                          Text(user['email'] ?? '',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[500])),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit_rounded,
                                              color: cs.primary, size: 20),
                                          onPressed: () => _showUserForm(user),
                                          tooltip: 'Edit',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_rounded,
                                              color: Colors.red, size: 20),
                                          onPressed: () =>
                                              _deleteUser(user['id']),
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

class _UserFormPage extends StatefulWidget {
  final Map<String, dynamic>? user;
  final VoidCallback onSaved;

  const _UserFormPage({
    this.user,
    required this.onSaved,
  });

  @override
  State<_UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<_UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _passwordController;
  String _selectedRole = 'cashier';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController(text: widget.user?['username'] ?? '');
    _emailController = TextEditingController(text: widget.user?['email'] ?? '');
    _fullNameController =
        TextEditingController(text: widget.user?['full_name'] ?? '');
    _passwordController = TextEditingController();
    _selectedRole = widget.user?['role'] ?? 'cashier';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'username': _usernameController.text.trim(),
      'email': _emailController.text.trim(),
      'full_name': _fullNameController.text.trim(),
      'role': _selectedRole,
      if (_passwordController.text.isNotEmpty)
        'password': _passwordController.text,
    };

    try {
      final response = widget.user == null
          ? await ApiService.post('${ApiConfig.baseUrl}/users.php', data)
          : await ApiService.put(
              '${ApiConfig.baseUrl}/users.php?id=${widget.user!['id']}', data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            response['message'] ?? (response['success'] ? 'Saved' : 'Failed')),
        backgroundColor: response['success'] ? Colors.green : Colors.red,
      ));

      if (response['success']) {
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
    final isNew = widget.user == null;
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isNew ? 'Add User' : 'Edit User',
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
                onPressed: _isLoading ? null : _saveUser,
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
                              Icons.manage_accounts_rounded,
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
                                  isNew ? 'Create User' : 'Update User',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blueGrey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Provide user credentials and role',
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
                      'Full Name',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      validator: (v) =>
                          v?.trim().isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Username',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                      validator: (v) =>
                          v?.trim().isEmpty == true ? 'Required' : null,
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
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_rounded),
                      ),
                      validator: (v) {
                        if (v?.trim().isEmpty == true) return 'Required';
                        if (!v!.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Password',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: isNew
                            ? 'Password'
                            : 'Password (leave empty to keep)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_rounded),
                      ),
                      validator: (v) =>
                          isNew && (v?.isEmpty == true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Role',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(
                            value: 'manager', child: Text('Manager')),
                        DropdownMenuItem(
                            value: 'cashier', child: Text('Cashier')),
                      ],
                      onChanged: (v) => setState(() => _selectedRole = v!),
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
                            onPressed: _isLoading ? null : _saveUser,
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
                            label: const Text('Save User'),
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
