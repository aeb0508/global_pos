import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class AuditTrailScreen extends StatefulWidget {
  const AuditTrailScreen({super.key});

  @override
  State<AuditTrailScreen> createState() => _AuditTrailScreenState();
}

class _AuditTrailScreenState extends State<AuditTrailScreen> {
  List<dynamic> _logs = [];
  List<dynamic> _displayed = [];
  bool _isLoading = true;
  String? _error;
  String _filterAction = 'all';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 20;
  int _currentPage = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadLogs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate);
      final url =
          '${ApiConfig.auditLogsEndpoint}?type=$_filterAction&start_date=$startStr&end_date=$endStr';

      final response = await ApiService.get(url);

      if (response['success'] == true) {
        final data = (response['data'] as List? ?? []);
        setState(() {
          _logs = data;
          _currentPage = 1;
          _displayed = _logs.take(_pageSize).toList();
          _hasMore = _logs.length > _pageSize;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error =
              response['message']?.toString() ?? 'Failed to load audit logs';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (!_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      setState(() {
        _currentPage++;
        _displayed = _logs.take(_currentPage * _pageSize).toList();
        _hasMore = _displayed.length < _logs.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade600, Colors.indigo.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
          child: Row(
            children: [
              const Icon(Icons.history_edu, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Audit Trail',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20)),
                    Text('Track all system activity and changes',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadLogs,
                  tooltip: 'Refresh'),
            ],
          ),
        ),

        // Filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _filterAction,
                  decoration: const InputDecoration(
                    labelText: 'Action Type',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Actions')),
                    DropdownMenuItem(value: 'create', child: Text('Create')),
                    DropdownMenuItem(value: 'update', child: Text('Update')),
                    DropdownMenuItem(value: 'delete', child: Text('Delete')),
                    DropdownMenuItem(value: 'login', child: Text('Login')),
                    DropdownMenuItem(value: 'logout', child: Text('Logout')),
                  ],
                  onChanged: (v) {
                    setState(() => _filterAction = v!);
                    _loadLogs();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now());
                    if (date != null) {
                      setState(() => _startDate = date);
                      _loadLogs();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true),
                    child: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now());
                    if (date != null) {
                      setState(() => _endDate = date);
                      _loadLogs();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true),
                    child: Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                  ),
                ),
              ),
            ],
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
                              onPressed: _loadLogs,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry')),
                        ],
                      ),
                    )
                  : _logs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_toggle_off,
                                  size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text('No activity logs found',
                                  style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _displayed.length + (_hasMore ? 1 : 0),
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            if (index == _displayed.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }
                            final log =
                                _displayed[index] as Map<String, dynamic>;
                            final action = log['action']?.toString() ?? '';
                            final color = _colorForAction(action);
                            final createdAt = log['created_at']?.toString();
                            String formattedDate = '';
                            if (createdAt != null) {
                              try {
                                formattedDate = DateFormat('MMM dd, yyyy HH:mm')
                                    .format(DateTime.parse(createdAt));
                              } catch (_) {
                                formattedDate = createdAt;
                              }
                            }

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.15),
                                child: Icon(_iconForAction(action),
                                    color: color, size: 18),
                              ),
                              title: Text(log['description']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 13)),
                              subtitle: Text(
                                '${log['user_name'] ?? 'Unknown'}  ·  $formattedDate'
                                '${log['entity_type'] != null ? '  ·  ${log['entity_type']}' : ''}',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600]),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(action.toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: color)),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Color _colorForAction(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      case 'login':
        return Colors.purple;
      case 'logout':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _iconForAction(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return Icons.add_circle_outline;
      case 'update':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.delete_outline;
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      default:
        return Icons.info_outline;
    }
  }
}
