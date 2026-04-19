import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

// Conditional import for file download
import 'backup_restore_io.dart' if (dart.library.html) 'backup_restore_web.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  List<dynamic> _backups = [];
  bool _isLoading = true;
  bool _isCreatingBackup = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadBackups();
    }
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    try {
      final response =
          await ApiService.get('${ApiConfig.baseUrl}/backup_restore.php');
      if (response['success'] == true) {
        setState(() {
          _backups = response['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isCreatingBackup = true);
    try {
      final response = await ApiService.post(
          '${ApiConfig.baseUrl}/backup_restore.php', {'action': 'backup'});
      if (response['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully')),
        );
        _loadBackups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() => _isCreatingBackup = false);
    }
  }

  Future<void> _restoreBackup(String filename) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: const Text(
            'This will restore the database to this backup. Current data will be replaced. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await ApiService.post(
          '${ApiConfig.baseUrl}/backup_restore.php',
          {'action': 'restore', 'filename': filename},
        );
        if (response['success'] == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Database restored successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _downloadBackup(Map<String, dynamic> backup) async {
    final filename = backup['filename'] as String;
    final downloadUrl =
        '${ApiConfig.baseUrl}/backup_restore.php?action=download&filename=$filename';
    try {
      await downloadFile(downloadUrl, filename);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(kIsWeb
                  ? '"$filename" download started'
                  : '"$filename" saved to Downloads')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 0,
            title: const Row(
              children: [
                Icon(Icons.backup, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Backup & Restore',
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
                    colors: [Colors.green.shade600, Colors.green.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: _isCreatingBackup
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.backup, color: Colors.white),
                onPressed: _isCreatingBackup ? null : _createBackup,
                tooltip: 'Create Backup',
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadBackups,
                tooltip: 'Refresh',
              ),
            ],
          ),
          if (_isLoading)
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()))
          else if (_backups.isEmpty)
            const SliverFillRemaining(
                child: Center(child: Text('No backups available')))
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final backup =
                        _backups[index] as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.folder_zip, size: 40),
                        title: Text(backup['filename'] ?? ''),
                        subtitle: Text(
                            'Created: ${backup['created_at']} | Size: ${backup['size']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.restore),
                              onPressed: () =>
                                  _restoreBackup(backup['filename']),
                              tooltip: 'Restore',
                            ),
                            IconButton(
                              icon: const Icon(Icons.download),
                              onPressed: () => _downloadBackup(backup),
                              tooltip: 'Download',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _backups.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
