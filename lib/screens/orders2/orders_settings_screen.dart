import 'package:flutter/material.dart';

class OrdersSettingsScreen extends StatefulWidget {
  const OrdersSettingsScreen({super.key});

  @override
  State<OrdersSettingsScreen> createState() => _OrdersSettingsScreenState();
}

class _OrdersSettingsScreenState extends State<OrdersSettingsScreen> {
  bool _enableNotifications = true;
  bool _enableSMSAlerts = true;
  bool _autoAssignCourier = false;
  bool _enableOrderTracking = true;
  String _defaultCourierService = 'steadfast';
  int _pendingOrderLimit = 100;
  String _orderNumberFormat = 'ORD-{YYYY}-{MM}-{DD}-{###}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Order Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save, color: Colors.white),
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Settings Section
            _buildSectionCard(
              title: 'General Settings',
              icon: Icons.settings,
              children: [
                _buildSwitchTile(
                  title: 'Enable Notifications',
                  subtitle: 'Receive push notifications for new orders',
                  value: _enableNotifications,
                  onChanged: (value) {
                    setState(() {
                      _enableNotifications = value;
                    });
                  },
                ),
                const Divider(),
                _buildSwitchTile(
                  title: 'SMS Alerts',
                  subtitle: 'Send SMS notifications to customers',
                  value: _enableSMSAlerts,
                  onChanged: (value) {
                    setState(() {
                      _enableSMSAlerts = value;
                    });
                  },
                ),
                const Divider(),
                _buildSwitchTile(
                  title: 'Auto-assign Courier',
                  subtitle: 'Automatically assign courier for new orders',
                  value: _autoAssignCourier,
                  onChanged: (value) {
                    setState(() {
                      _autoAssignCourier = value;
                    });
                  },
                ),
                const Divider(),
                _buildSwitchTile(
                  title: 'Order Tracking',
                  subtitle: 'Enable real-time order tracking',
                  value: _enableOrderTracking,
                  onChanged: (value) {
                    setState(() {
                      _enableOrderTracking = value;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Courier Settings Section
            _buildSectionCard(
              title: 'Courier Settings',
              icon: Icons.local_shipping,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Default Courier Service',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Primary courier service for orders'),
                  trailing: DropdownButton<String>(
                    value: _defaultCourierService,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 'steadfast',
                        child: Text('Steadfast'),
                      ),
                      DropdownMenuItem(
                        value: 'pathao',
                        child: Text('Pathao'),
                      ),
                      DropdownMenuItem(
                        value: 'redx',
                        child: Text('RedX'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _defaultCourierService = value;
                        });
                      }
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Pending Order Limit',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Maximum pending orders before warning'),
                  trailing: SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: _pendingOrderLimit.toString(),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.all(8),
                      ),
                      onChanged: (value) {
                        final limit = int.tryParse(value);
                        if (limit != null) {
                          setState(() {
                            _pendingOrderLimit = limit;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Order Format Section
            _buildSectionCard(
              title: 'Order Format',
              icon: Icons.format_list_numbered,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Order Number Format',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pattern for generating order numbers'),
                      const SizedBox(height: 4),
                      Text(
                        'Preview: ${_generateOrderPreview()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: _showOrderFormatDialog,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Business Rules Section
            _buildSectionCard(
              title: 'Business Rules',
              icon: Icons.business,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.schedule, color: Colors.orange[600]),
                  title: const Text('Order Processing Time'),
                  subtitle: const Text('Average: 2-4 hours during business hours'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.local_shipping, color: Colors.blue[600]),
                  title: const Text('Delivery Areas'),
                  subtitle: const Text('Dhaka, Chattogram, Sylhet, Rangpur'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.payment, color: Colors.green[600]),
                  title: const Text('Payment Methods'),
                  subtitle: const Text('Cash on Delivery (COD)'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Data Management Section
            _buildSectionCard(
              title: 'Data Management',
              icon: Icons.storage,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.download, color: Colors.blue[600]),
                  title: const Text('Export Orders'),
                  subtitle: const Text('Download order data as CSV/Excel'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _exportOrders,
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.backup, color: Colors.green[600]),
                  title: const Text('Backup Data'),
                  subtitle: const Text('Create backup of order database'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _backupData,
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_sweep, color: Colors.red[600]),
                  title: const Text('Clear Old Orders'),
                  subtitle: const Text('Remove orders older than 1 year'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showClearOldOrdersDialog,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // System Information Section
            _buildSectionCard(
              title: 'System Information',
              icon: Icons.info,
              children: [
                _buildInfoRow('Version', '2.1.0'),
                const Divider(),
                _buildInfoRow('Last Sync', '2 minutes ago'),
                const Divider(),
                _buildInfoRow('Database Size', '45.2 MB'),
                const Divider(),
                _buildInfoRow('Total Orders', '1,247'),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF3B82F6)),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF3B82F6),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  String _generateOrderPreview() {
    final now = DateTime.now();
    return _orderNumberFormat
        .replaceAll('{YYYY}', now.year.toString())
        .replaceAll('{MM}', now.month.toString().padLeft(2, '0'))
        .replaceAll('{DD}', now.day.toString().padLeft(2, '0'))
        .replaceAll('{###}', '001');
  }

  void _showOrderFormatDialog() {
    final controller = TextEditingController(text: _orderNumberFormat);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Number Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Available placeholders:'),
            const SizedBox(height: 8),
            const Text('• {YYYY} - Year (2024)'),
            const Text('• {MM} - Month (01-12)'),
            const Text('• {DD} - Day (01-31)'),
            const Text('• {###} - Sequential number'),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Format Pattern',
                border: OutlineInputBorder(),
                hintText: 'ORD-{YYYY}-{MM}-{DD}-{###}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _orderNumberFormat = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showClearOldOrdersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Old Orders'),
        content: const Text(
          'This will permanently delete orders older than 1 year. This action cannot be undone.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearOldOrders();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _exportOrders() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting orders... Check downloads folder'),
        backgroundColor: Color(0xFF3B82F6),
      ),
    );
  }

  void _backupData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Creating backup... This may take a few minutes'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _clearOldOrders() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Clearing old orders... 23 orders deleted'),
        backgroundColor: Color(0xFFEF4444),
      ),
    );
  }
}