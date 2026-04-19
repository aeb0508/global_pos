import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class LoyaltyProgramScreen extends StatefulWidget {
  const LoyaltyProgramScreen({super.key});

  @override
  State<LoyaltyProgramScreen> createState() => _LoyaltyProgramScreenState();
}

class _LoyaltyProgramScreenState extends State<LoyaltyProgramScreen> {
  Map<String, dynamic>? _program;
  List<dynamic> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final programResponse =
          await ApiService.get('${ApiConfig.baseUrl}/loyalty_program.php');
      final customersResponse =
          await ApiService.get('${ApiConfig.baseUrl}/loyalty_customers.php');

      if (programResponse['success'] && customersResponse['success']) {
        setState(() {
          _program = programResponse['data'];
          _customers = customersResponse['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 0,
            title: const Row(
              children: [
                Icon(Icons.stars, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Loyalty Program',
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
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => _showProgramDialog(),
                tooltip: 'Configure Program',
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadData,
                tooltip: 'Refresh',
              ),
            ],
          ),
          if (_program != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                        child: _StatCard(
                            title: 'Points per \$1',
                            value: _program!['points_per_dollar'].toString(),
                            icon: Icons.monetization_on,
                            color: Colors.green)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _StatCard(
                            title: 'Points for Reward',
                            value: _program!['points_for_reward'].toString(),
                            icon: Icons.card_giftcard,
                            color: Colors.orange)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _StatCard(
                            title: 'Reward Value',
                            value:
                                '${_program!['reward_value']} ${context.watch<AppSettingsProvider>().currencySymbol}',
                            icon: Icons.attach_money,
                            color: Colors.blue)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _StatCard(
                            title: 'Total Members',
                            value: _customers.length.toString(),
                            icon: Icons.people,
                            color: Colors.purple)),
                  ],
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text('Loyalty Members',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          if (_customers.isEmpty)
            const SliverFillRemaining(
                child: Center(child: Text('No loyalty members yet')))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverToBoxAdapter(
                child: Card(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _customers.length,
                    itemBuilder: (context, index) {
                      final customer = _customers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getTierColor(customer['tier']),
                          child: Text(customer['tier'][0].toUpperCase(),
                              style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(customer['name']),
                        subtitle: Text(
                            '${customer['points']} points • ${_getTierName(customer['tier'])} Member'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => _addPoints(customer),
                                tooltip: 'Add Points'),
                            IconButton(
                                icon: const Icon(Icons.history),
                                onPressed: () => _showHistory(customer),
                                tooltip: 'View History'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'bronze':
        return Colors.brown;
      case 'silver':
        return Colors.grey;
      case 'gold':
        return Colors.amber;
      case 'platinum':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _getTierName(String tier) {
    return tier[0].toUpperCase() + tier.substring(1);
  }

  void _showProgramDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ProgramPage(
          program: _program,
          onSaved: () {
            _loadData();
          },
        ),
      ),
    );
  }

  void _addPoints(Map<String, dynamic> customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AddPointsPage(
          customer: customer,
          onSaved: () {
            _loadData();
          },
        ),
      ),
    );
  }

  void _showHistory(Map<String, dynamic> customer) {
    // Show points history
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('History for ${customer['name']}')),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ProgramPage extends StatefulWidget {
  final Map<String, dynamic>? program;
  final VoidCallback onSaved;

  const _ProgramPage({this.program, required this.onSaved});

  @override
  State<_ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<_ProgramPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _pointsPerDollarController;
  late TextEditingController _pointsForRewardController;
  late TextEditingController _rewardValueController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pointsPerDollarController = TextEditingController(
      text: widget.program?['points_per_dollar']?.toString() ?? '10',
    );
    _pointsForRewardController = TextEditingController(
      text: widget.program?['points_for_reward']?.toString() ?? '100',
    );
    _rewardValueController = TextEditingController(
      text: widget.program?['reward_value']?.toString() ?? '10',
    );
  }

  @override
  void dispose() {
    _pointsPerDollarController.dispose();
    _pointsForRewardController.dispose();
    _rewardValueController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'points_per_dollar': int.parse(_pointsPerDollarController.text),
      'points_for_reward': int.parse(_pointsForRewardController.text),
      'reward_value': double.parse(_rewardValueController.text),
    };

    try {
      final response = await ApiService.post(
          '${ApiConfig.baseUrl}/loyalty_program.php', data);
      if (response['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Program updated successfully')),
        );
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configure Loyalty Program',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.loyalty_rounded,
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
                                  'Loyalty Program Settings',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blueGrey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Configure points and rewards for your loyalty program',
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _pointsPerDollarController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Points per Dollar Spent',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.point_of_sale),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pointsForRewardController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Points Required for Reward',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.card_giftcard),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _rewardValueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText:
                        'Reward Value (${context.watch<AppSettingsProvider>().currencySymbol})',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.attach_money),
                    prefixText:
                        context.watch<AppSettingsProvider>().currencySymbol,
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _save,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Save Program Settings'),
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
          ),
        ),
      ),
    );
  }
}

class _AddPointsPage extends StatefulWidget {
  final Map<String, dynamic> customer;
  final VoidCallback onSaved;

  const _AddPointsPage({required this.customer, required this.onSaved});

  @override
  State<_AddPointsPage> createState() => _AddPointsPageState();
}

class _AddPointsPageState extends State<_AddPointsPage> {
  final _pointsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _addPoints() async {
    final points = int.tryParse(_pointsController.text);
    if (points == null || points <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid points')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post(
        '${ApiConfig.baseUrl}/loyalty_customers.php',
        {
          'customer_id': widget.customer['customer_id'],
          'points': points,
          'action': 'add',
        },
      );

      if (response['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Points added successfully')),
        );
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Points - ${widget.customer['name']}',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isPhone ? 16.0 : 24.0,
            vertical: isPhone ? 20.0 : 30.0,
          ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add_circle_rounded,
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
                                'Add Loyalty Points',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey.shade800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Award points to customer for purchases or special occasions',
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
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_circle,
                              color: Colors.blueGrey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.customer['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Current Points: ${widget.customer['points']}',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
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
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _pointsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Points to Add',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.add),
                  hintText: 'Enter number of points to award',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _addPoints,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_circle),
                  label: const Text('Add Points'),
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
        ),
      ),
    );
  }
}
