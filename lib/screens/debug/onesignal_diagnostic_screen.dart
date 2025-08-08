import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/onesignal_service.dart';
import '../../config/supabase_config.dart';

class OneSignalDiagnosticScreen extends StatefulWidget {
  const OneSignalDiagnosticScreen({super.key});

  @override
  State<OneSignalDiagnosticScreen> createState() =>
      _OneSignalDiagnosticScreenState();
}

class _OneSignalDiagnosticScreenState extends State<OneSignalDiagnosticScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? _diagnosticResult;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostic();
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = <String, dynamic>{};

      // Check OneSignal initialization
      result['isInitialized'] = OneSignalService.isInitialized;
      result['playerId'] = OneSignalService.playerId;
      result['hasPlayerId'] = OneSignalService.playerId != null;

      // Check database connection
      try {
        final user = _supabase.auth.currentUser;
        result['hasUser'] = user != null;
        result['userId'] = user?.id;

        if (user != null) {
          // Check if user profile exists
          final profileResponse = await _supabase
              .from(SupabaseConfig.profilesTable)
              .select('id, full_name, onesignal_player_id')
              .eq('id', user.id)
              .maybeSingle();

          result['hasProfile'] = profileResponse != null;
          result['profilePlayerId'] = profileResponse?['onesignal_player_id'];
          result['profileName'] = profileResponse?['full_name'];
        }

        result['databaseConnected'] = true;
      } catch (e) {
        result['databaseConnected'] = false;
        result['databaseError'] = e.toString();
      }

      // Check all users with OneSignal player IDs
      try {
        final allUsersResponse = await _supabase
            .from(SupabaseConfig.profilesTable)
            .select('id, full_name, onesignal_player_id')
            .not('onesignal_player_id', 'is', null);

        result['totalUsersWithPlayerIds'] = allUsersResponse.length;
        result['userDetails'] = allUsersResponse;
      } catch (e) {
        result['totalUsersWithPlayerIds'] = 0;
        result['userQueryError'] = e.toString();
      }

      setState(() {
        _diagnosticResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _diagnosticResult = {
          'error': e.toString(),
          'isInitialized': false,
          'hasUser': false,
          'databaseConnected': false,
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTestNotification() async {
    if (_diagnosticResult == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await OneSignalService.sendNotificationToAll(
        title: '🔍 Diagnostic Test',
        message: 'This is a diagnostic test notification from OneSignal!',
        data: {
          'type': 'diagnostic_test',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      final updatedResult = Map<String, dynamic>.from(_diagnosticResult!);
      updatedResult['testNotificationSent'] = success;
      updatedResult['testNotificationTime'] = DateTime.now().toIso8601String();

      setState(() {
        _diagnosticResult = updatedResult;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Test notification sent successfully!'
              : 'Failed to send test notification'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      final updatedResult = Map<String, dynamic>.from(_diagnosticResult!);
      updatedResult['testNotificationError'] = e.toString();

      setState(() {
        _diagnosticResult = updatedResult;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending test notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OneSignal Diagnostic'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDiagnostic,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _diagnosticResult == null
              ? const Center(child: Text('Running diagnostic...'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildOverallStatusCard(),
                      const SizedBox(height: 16),
                      _buildOneSignalStatusCard(),
                      const SizedBox(height: 16),
                      _buildDatabaseStatusCard(),
                      const SizedBox(height: 16),
                      _buildUsersStatusCard(),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _sendTestNotification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('🧪 Send Test Notification'),
                      ),
                      if (_diagnosticResult!
                          .containsKey('testNotificationSent')) ...[
                        const SizedBox(height: 16),
                        _buildTestNotificationCard(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildOverallStatusCard() {
    final result = _diagnosticResult!;
    final isInitialized = result['isInitialized'] as bool? ?? false;
    final hasUser = result['hasUser'] as bool? ?? false;
    final databaseConnected = result['databaseConnected'] as bool? ?? false;

    final overallHealthy = isInitialized && hasUser && databaseConnected;

    return Card(
      color: overallHealthy
          ? Colors.green.withOpacity(0.1)
          : Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              overallHealthy ? Icons.check_circle : Icons.error,
              color: overallHealthy ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    overallHealthy
                        ? 'OneSignal system is healthy'
                        : 'Issues detected with OneSignal system',
                    style: TextStyle(
                      color: overallHealthy ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOneSignalStatusCard() {
    final result = _diagnosticResult!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OneSignal Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Initialized', result['isInitialized']),
            _buildDetailRow('Has Player ID', result['hasPlayerId']),
            if (result['playerId'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Player ID (first 20 chars):',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  result['playerId'].toString().substring(0, 20),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDatabaseStatusCard() {
    final result = _diagnosticResult!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Database Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Database Connected', result['databaseConnected']),
            _buildDetailRow('Has User', result['hasUser']),
            _buildDetailRow('Has Profile', result['hasProfile']),
            if (result['profileName'] != null) ...[
              const SizedBox(height: 8),
              Text('Profile Name: ${result['profileName']}'),
            ],
            if (result['profilePlayerId'] != null) ...[
              const SizedBox(height: 4),
              Text(
                  'Profile Player ID: ${result['profilePlayerId'].toString().substring(0, 20)}...'),
            ],
            if (result['databaseError'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Error: ${result['databaseError']}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsersStatusCard() {
    final result = _diagnosticResult!;
    final totalUsers = result['totalUsersWithPlayerIds'] as int? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Users with OneSignal',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text('Total users with Player IDs: $totalUsers'),
            if (result['userDetails'] != null &&
                result['userDetails'].isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'User Details:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...(result['userDetails'] as List).take(5).map((user) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• ${user['full_name'] ?? 'Unknown'} (${user['onesignal_player_id']?.toString().substring(0, 15)}...)',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
              if ((result['userDetails'] as List).length > 5) ...[
                Text(
                  '... and ${(result['userDetails'] as List).length - 5} more',
                  style: const TextStyle(
                      fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTestNotificationCard() {
    final result = _diagnosticResult!;
    final success = result['testNotificationSent'] as bool? ?? false;

    return Card(
      color:
          success ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Test Notification',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              success
                  ? 'Test notification sent successfully!'
                  : 'Failed to send test notification',
              style: TextStyle(
                color: success ? Colors.green : Colors.red,
              ),
            ),
            if (result['testNotificationTime'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Sent at: ${result['testNotificationTime']}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
            if (result['testNotificationError'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Error: ${result['testNotificationError']}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Icon(
            value == true ? Icons.check : Icons.close,
            color: value == true ? Colors.green : Colors.red,
            size: 16,
          ),
        ],
      ),
    );
  }
}
