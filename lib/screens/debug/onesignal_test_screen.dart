import 'package:flutter/material.dart';
import '../../services/onesignal_service.dart';

class OneSignalTestScreen extends StatefulWidget {
  const OneSignalTestScreen({super.key});

  @override
  State<OneSignalTestScreen> createState() => _OneSignalTestScreenState();
}

class _OneSignalTestScreenState extends State<OneSignalTestScreen> {
  Map<String, dynamic>? _debugResult;
  bool _isLoading = false;

  Future<void> _testOneSignalStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isInitialized = OneSignalService.isInitialized;
      final playerId = OneSignalService.playerId;

      setState(() {
        _debugResult = {
          'isInitialized': isInitialized,
          'hasPlayerId': playerId != null,
          'playerId': playerId,
          'message': isInitialized
              ? 'OneSignal is initialized successfully'
              : 'OneSignal is not initialized',
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugResult = {
          'error': e.toString(),
          'isInitialized': false,
          'hasPlayerId': false,
          'playerId': null,
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _testSendNotification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await OneSignalService.sendNotificationToAll(
        title: '🧪 OneSignal Test',
        message: 'This is a test notification from OneSignal!',
        data: {
          'type': 'test',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      setState(() {
        _debugResult = {
          'notificationSent': success,
          'message': success
              ? 'Test notification sent successfully!'
              : 'Failed to send test notification',
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugResult = {
          'error': e.toString(),
          'notificationSent': false,
          'message': 'Error sending notification',
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _testUserTags() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await OneSignalService.setUserTags({
        'test_tag': 'true',
        'user_type': 'test_user',
        'app_version': '1.0.0',
      });

      setState(() {
        _debugResult = {
          'tagsSet': true,
          'message': 'User tags set successfully!',
          'tags': {
            'test_tag': 'true',
            'user_type': 'test_user',
            'app_version': '1.0.0',
          },
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugResult = {
          'error': e.toString(),
          'tagsSet': false,
          'message': 'Error setting user tags',
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeOneSignal() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await OneSignalService.initialize();

      setState(() {
        _debugResult = {
          'initialized': true,
          'message': 'OneSignal initialized successfully!',
          'isInitialized': OneSignalService.isInitialized,
          'playerId': OneSignalService.playerId,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugResult = {
          'error': e.toString(),
          'initialized': false,
          'message': 'Failed to initialize OneSignal',
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPlayerId() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final playerId = await OneSignalService.refreshPlayerId();

      setState(() {
        _debugResult = {
          'refreshed': true,
          'message': playerId != null
              ? 'Player ID refreshed successfully!'
              : 'Player ID still not available',
          'isInitialized': OneSignalService.isInitialized,
          'hasPlayerId': playerId != null,
          'playerId': playerId,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugResult = {
          'error': e.toString(),
          'refreshed': false,
          'message': 'Failed to refresh Player ID',
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OneSignal Test'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _initializeOneSignal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Initialize OneSignal'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testOneSignalStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Check OneSignal Status'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testSendNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send Test Notification'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testUserTags,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Test User Tags'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _refreshPlayerId,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('🔄 Refresh Player ID'),
            ),
            const SizedBox(height: 24),
            if (_debugResult != null) ...[
              _buildStatusCard(),
              const SizedBox(height: 16),
              _buildDetailsCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final result = _debugResult!;
    final error = result['error'] as String?;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (error != null) {
      statusColor = Colors.red;
      statusText = 'Error: $error';
      statusIcon = Icons.error;
    } else if (result.containsKey('notificationSent')) {
      final success = result['notificationSent'] as bool? ?? false;
      statusColor = success ? Colors.green : Colors.red;
      statusText = result['message'] ?? 'Unknown status';
      statusIcon = success ? Icons.check_circle : Icons.error;
    } else if (result.containsKey('tagsSet')) {
      final success = result['tagsSet'] as bool? ?? false;
      statusColor = success ? Colors.green : Colors.red;
      statusText = result['message'] ?? 'Unknown status';
      statusIcon = success ? Icons.check_circle : Icons.error;
    } else if (result.containsKey('initialized')) {
      final success = result['initialized'] as bool? ?? false;
      statusColor = success ? Colors.green : Colors.red;
      statusText = result['message'] ?? 'Unknown status';
      statusIcon = success ? Icons.check_circle : Icons.error;
    } else if (result.containsKey('refreshed')) {
      final success = result['refreshed'] as bool? ?? false;
      final hasPlayerId = result['hasPlayerId'] as bool? ?? false;
      statusColor = success && hasPlayerId
          ? Colors.green
          : (success ? Colors.orange : Colors.red);
      statusText = result['message'] ?? 'Unknown status';
      statusIcon = success && hasPlayerId
          ? Icons.check_circle
          : (success ? Icons.warning : Icons.error);
    } else {
      final isInitialized = result['isInitialized'] as bool? ?? false;
      statusColor = isInitialized ? Colors.green : Colors.orange;
      statusText = result['message'] ?? 'Unknown status';
      statusIcon = isInitialized ? Icons.check_circle : Icons.warning;
    }

    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OneSignal Status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(color: statusColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    final result = _debugResult!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (result.containsKey('isInitialized')) ...[
              _buildDetailRow('OneSignal Initialized', result['isInitialized']),
              _buildDetailRow('Has Player ID', result['hasPlayerId']),
            ],
            if (result.containsKey('notificationSent')) ...[
              _buildDetailRow('Notification Sent', result['notificationSent']),
            ],
            if (result.containsKey('tagsSet')) ...[
              _buildDetailRow('Tags Set', result['tagsSet']),
              if (result['tags'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Tags:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                ...(result['tags'] as Map<String, dynamic>)
                    .entries
                    .map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('  ${entry.key}: ${entry.value}'),
                  );
                }).toList(),
              ],
            ],
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
            if (result['error'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  result['error'].toString(),
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
