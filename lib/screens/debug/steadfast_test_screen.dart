import 'package:flutter/material.dart';
import '../../services/steadfast_service.dart';
import '../../services/connectivity_service.dart';

class SteadfastTestScreen extends StatefulWidget {
  const SteadfastTestScreen({super.key});

  @override
  State<SteadfastTestScreen> createState() => _SteadfastTestScreenState();
}

class _SteadfastTestScreenState extends State<SteadfastTestScreen> {
  final SteadFastService _steadfastService = SteadFastService();
  final ConnectivityService _connectivity = ConnectivityService();
  
  bool _isLoading = false;
  String _testResult = 'No test run yet';
  Color _resultColor = Colors.grey;

  Future<void> _testAPIConnectivity() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing API connectivity...';
      _resultColor = Colors.blue;
    });

    try {
      final isConnected = await _steadfastService.testAPIConnectivity();
      
      setState(() {
        if (isConnected) {
          _testResult = '✅ API connectivity test passed!\n\nThe Steadfast API is working correctly with your credentials.';
          _resultColor = Colors.green;
        } else {
          _testResult = '❌ API connectivity test failed!\n\nPlease check:\n• API credentials\n• Network connection\n• Steadfast service status';
          _resultColor = Colors.red;
        }
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ API test error:\n\n$e';
        _resultColor = Colors.red;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testStatusCheck() async {
    // Show input dialog for consignment ID
    final consignmentId = await _showConsignmentInputDialog();
    if (consignmentId == null || consignmentId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _testResult = 'Testing status check for consignment ID: $consignmentId...';
      _resultColor = Colors.blue;
    });

    try {
      final statusResponse = await _steadfastService.checkStatus(
        consignmentId: consignmentId,
      );

      setState(() {
        if (statusResponse != null && statusResponse.success) {
          _testResult = '✅ Status check successful!\n\nConsignment ID: $consignmentId\nStatus: ${statusResponse.status}\nMessage: ${statusResponse.message}';
          _resultColor = Colors.green;
        } else {
          _testResult = '❌ Status check failed!\n\nConsignment ID: $consignmentId\nMessage: ${statusResponse?.message ?? 'Unknown error'}\n\nNote: Make sure the consignment ID exists and is valid.';
          _resultColor = Colors.orange;
        }
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Status check error:\n\nConsignment ID: $consignmentId\nError: $e';
        _resultColor = Colors.red;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _showConsignmentInputDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Consignment ID'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Consignment ID',
            hintText: 'e.g., 1424107',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Test'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Steadfast API Test'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _connectivity.isOnline ? Icons.wifi : Icons.wifi_off,
                      color: _connectivity.isOnline ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _connectivity.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: _connectivity.isOnline ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API Tests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // API Connectivity Test
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _testAPIConnectivity,
                        icon: const Icon(Icons.network_check),
                        label: const Text('Test API Connectivity'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Status Check Test  
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _testStatusCheck,
                        icon: const Icon(Icons.search),
                        label: const Text('Test Status Check'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Results
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Results',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(),
                        )
                      else
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _resultColor.withOpacity(0.1),
                              border: Border.all(color: _resultColor.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                _testResult,
                                style: TextStyle(
                                  color: _resultColor,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}