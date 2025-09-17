import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/sms_service.dart';

class SmsTestScreen extends StatefulWidget {
  const SmsTestScreen({super.key});

  @override
  State<SmsTestScreen> createState() => _SmsTestScreenState();
}

class _SmsTestScreenState extends State<SmsTestScreen> {
  final SmsService _smsService = SmsService();
  final _formKey = GlobalKey<FormState>();
  
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _orderIdController = TextEditingController();
  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _amountController = TextEditingController();
  final _trackingCodeController = TextEditingController();
  
  bool _isLoading = false;
  String? _lastResult;
  int _selectedTestType = 0;

  @override
  void initState() {
    super.initState();
    // Pre-fill with test data
    _phoneController.text = '01700000000';
    _customerNameController.text = 'Test Customer';
    _orderIdController.text = 'ORD12345';
    _productNameController.text = 'Test Product';
    _quantityController.text = '2';
    _amountController.text = '1500.00';
    _trackingCodeController.text = 'TRK98765';
    _messageController.text = 'This is a test SMS message from FurniTrack.';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    _customerNameController.dispose();
    _orderIdController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    _amountController.dispose();
    _trackingCodeController.dispose();
    super.dispose();
  }

  Future<void> _sendTestSMS() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      bool success = false;
      String testType = '';

      switch (_selectedTestType) {
        case 0: // Order Confirmation
          testType = 'Order Confirmation';
          success = await _smsService.sendOrderConfirmationSMS(
            customerName: _customerNameController.text,
            customerPhone: _phoneController.text,
            orderId: _orderIdController.text,
            productName: _productNameController.text,
            quantity: int.parse(_quantityController.text),
            amount: double.parse(_amountController.text),
          );
          break;
        case 1: // Courier Dispatch
          testType = 'Courier Dispatch';
          success = await _smsService.sendCourierDispatchSMS(
            customerName: _customerNameController.text,
            customerPhone: _phoneController.text,
            orderId: _orderIdController.text,
            trackingCode: _trackingCodeController.text,
          );
          break;
        case 2: // Custom Message
          testType = 'Custom Message';
          success = await _smsService.sendCustomSMS(
            phoneNumber: _phoneController.text,
            message: _messageController.text,
          );
          break;
      }

      setState(() {
        _lastResult = success 
            ? '✅ $testType SMS sent successfully!'
            : '❌ Failed to send $testType SMS';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_lastResult!),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _lastResult = '❌ Error: ${e.toString()}';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testServiceConnectivity() async {
    setState(() {
      _isLoading = true;
      _lastResult = null;
    });

    try {
      final isServiceActive = await _smsService.testSMSService();
      final serviceStatus = _smsService.getServiceStatus();
      
      setState(() {
        _lastResult = '''
🔍 SMS Service Test Results:
${isServiceActive ? '✅' : '❌'} Service Connectivity: ${isServiceActive ? 'OK' : 'Failed'}
${serviceStatus['service_active'] ? '✅' : '❌'} Service Active: ${serviceStatus['service_active']}
${serviceStatus['is_online'] ? '✅' : '❌'} Online Status: ${serviceStatus['is_online']}
🔑 API Key: ${serviceStatus['api_key_configured'] ? 'Configured' : 'Missing'}
📱 Sender ID: ${serviceStatus['sender_id']}
🌐 Base URL: ${serviceStatus['base_url']}
''';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isServiceActive ? 'Service test passed!' : 'Service test failed!'),
            backgroundColor: isServiceActive ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _lastResult = '❌ Service test error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.sms, color: Colors.white),
            const SizedBox(width: 8),
            const Text('SMS Service Test'),
          ],
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _testServiceConnectivity,
            icon: const Icon(Icons.wifi_find),
            tooltip: 'Test Service',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Service Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        const Text(
                          'SMS Service Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'BulkSMSBD API Integration\nSender ID: FurniTrack\nAPI Status: Ready',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _testServiceConnectivity,
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.speed, size: 18),
                        label: const Text('Test Service Connectivity'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Type Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings, color: Colors.orange[600]),
                        const SizedBox(width: 8),
                        const Text(
                          'SMS Test Type',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        RadioListTile<int>(
                          title: const Text('Order Confirmation SMS'),
                          subtitle: const Text('Test order creation notification'),
                          value: 0,
                          groupValue: _selectedTestType,
                          onChanged: (value) {
                            setState(() {
                              _selectedTestType = value!;
                            });
                          },
                        ),
                        RadioListTile<int>(
                          title: const Text('Courier Dispatch SMS'),
                          subtitle: const Text('Test courier shipment notification'),
                          value: 1,
                          groupValue: _selectedTestType,
                          onChanged: (value) {
                            setState(() {
                              _selectedTestType = value!;
                            });
                          },
                        ),
                        RadioListTile<int>(
                          title: const Text('Custom Message'),
                          subtitle: const Text('Test custom SMS content'),
                          value: 2,
                          groupValue: _selectedTestType,
                          onChanged: (value) {
                            setState(() {
                              _selectedTestType = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Phone Number Field
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.phone, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        const Text(
                          'Recipient Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                        hintText: '01XXXXXXXXX',
                        helperText: 'Enter 11-digit BD phone number',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Phone number is required';
                        }
                        if (value.length != 11 || !RegExp(r'^\d{11}$').hasMatch(value)) {
                          return 'Enter exactly 11 digits';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Dynamic Fields based on test type
            if (_selectedTestType == 0 || _selectedTestType == 1) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt, color: Colors.purple[600]),
                          const SizedBox(width: 8),
                          const Text(
                            'Order Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _customerNameController,
                              decoration: const InputDecoration(
                                labelText: 'Customer Name',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _orderIdController,
                              decoration: const InputDecoration(
                                labelText: 'Order ID',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.receipt_long),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_selectedTestType == 0) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _productNameController,
                          decoration: const InputDecoration(
                            labelText: 'Product Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _quantityController,
                                decoration: const InputDecoration(
                                  labelText: 'Quantity',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.numbers),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Invalid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _amountController,
                                decoration: const InputDecoration(
                                  labelText: 'Amount (৳)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Invalid amount';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_selectedTestType == 1) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _trackingCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Tracking Code',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.local_shipping),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            if (_selectedTestType == 2) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.message, color: Colors.teal[600]),
                          const SizedBox(width: 8),
                          const Text(
                            'Custom Message',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'SMS Message',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.message),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        maxLength: 160,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Message is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Send SMS Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendTestSMS,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 20),
                label: Text(
                  _isLoading ? 'Sending...' : 'Send Test SMS',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Results Card
            if (_lastResult != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _lastResult!.startsWith('✅') ? Icons.check_circle : Icons.error,
                            color: _lastResult!.startsWith('✅') ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Test Results',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _lastResult!.startsWith('✅') 
                              ? Colors.green[50] 
                              : Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _lastResult!.startsWith('✅') 
                                ? Colors.green[300]! 
                                : Colors.red[300]!,
                          ),
                        ),
                        child: Text(
                          _lastResult!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: _lastResult!.startsWith('✅') 
                                ? Colors.green[800] 
                                : Colors.red[800],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _lastResult!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Results copied to clipboard'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Copy Results'),
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _lastResult = null;
                                });
                              },
                              icon: const Icon(Icons.clear, size: 16),
                              label: const Text('Clear'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Help Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        const Text(
                          'Testing Guidelines',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Use your own phone number for testing\n'
                      '• Order Confirmation: Tests new order SMS template\n'
                      '• Courier Dispatch: Tests delivery notification template\n'
                      '• Custom Message: Tests raw SMS sending capability\n'
                      '• Check SMS delivery on your phone\n'
                      '• Service test verifies API connectivity',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 13,
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
  }
}