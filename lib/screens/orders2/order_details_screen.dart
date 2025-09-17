import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../providers/sales_provider.dart';
import '../../models/sale.dart';
import '../../services/sms_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final SmsService _smsService = SmsService();
  Sale? order;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderDetails();
    });
  }

  void _loadOrderDetails() {
    final salesProvider = context.read<SalesProvider>();
    final foundOrder = salesProvider.sales.firstWhere(
      (sale) => sale.id == widget.orderId,
      orElse: () => throw Exception('Order not found'),
    );
    setState(() {
      order = foundOrder;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          order != null ? 'Order #${order!.id.substring(0, 8)}' : 'Order Details',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (order != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) => _handleMenuAction(value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 20),
                      SizedBox(width: 8),
                      Text('Share Order'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'print',
                  child: Row(
                    children: [
                      Icon(Icons.print, size: 20),
                      SizedBox(width: 8),
                      Text('Print Order'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'copy_id',
                  child: Row(
                    children: [
                      Icon(Icons.copy, size: 20),
                      SizedBox(width: 8),
                      Text('Copy Order ID'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: order == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Status Header
                  _buildOrderStatusHeader(),
                  const SizedBox(height: 24),

                  // Order Progress Timeline
                  _buildOrderTimeline(),
                  const SizedBox(height: 24),

                  // Order Information Card
                  _buildOrderInformationCard(),
                  const SizedBox(height: 16),

                  // Customer Details Card
                  _buildCustomerDetailsCard(),
                  const SizedBox(height: 16),

                  // Delivery Information Card
                  _buildDeliveryInformationCard(),
                  const SizedBox(height: 16),

                  // Product Details Card
                  _buildProductDetailsCard(),
                  const SizedBox(height: 16),

                  // Payment Information Card
                  _buildPaymentInformationCard(),
                  const SizedBox(height: 16),

                  // Order Notes Card (if any)
                  if (order!.courierNotes != null && order!.courierNotes!.isNotEmpty)
                    _buildOrderNotesCard(),

                  const SizedBox(height: 16),

                  // Action Buttons
                  _buildActionButtons(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getStatusColor().withOpacity(0.1), _getStatusColor().withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor().withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getStatusIcon(),
              color: _getStatusColor(),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusDisplayText(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (order!.consignmentId != null && order!.consignmentId!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Text(
                'Tracking: ${order!.consignmentId!.substring(0, 8)}...',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderTimeline() {
    final steps = _getOrderSteps();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == steps.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: step['isCompleted']
                            ? const Color(0xFF10B981)
                            : step['isActive']
                                ? const Color(0xFF3B82F6)
                                : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        step['isCompleted']
                            ? Icons.check
                            : step['isActive']
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                        color: step['isCompleted'] || step['isActive']
                            ? Colors.white
                            : Colors.grey[600],
                        size: 18,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: step['isCompleted']
                            ? const Color(0xFF10B981)
                            : Colors.grey[300],
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: step['isCompleted'] || step['isActive']
                                ? const Color(0xFF1E293B)
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (step['timestamp'] != null)
                          Text(
                            step['timestamp'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOrderInformationCard() {
    return _buildInfoCard(
      title: 'Order Information',
      icon: Icons.receipt_long,
      children: [
        _buildInfoRow('Order ID', order!.id),
        _buildInfoRow('Order Date', _formatDate(order!.saleDate)),
        _buildInfoRow('Order Type', 'Online COD'),
        _buildInfoRow('Status', _getStatusDisplayText()),
        if (order!.consignmentId != null && order!.consignmentId!.isNotEmpty)
          _buildInfoRow('Tracking ID', order!.consignmentId!, copyable: true),
        _buildInfoRow('Payment Method', 'Cash on Delivery'),
      ],
    );
  }

  Widget _buildCustomerDetailsCard() {
    return _buildInfoCard(
      title: 'Customer Details',
      icon: Icons.person,
      children: [
        _buildInfoRow('Customer Name', order!.customerName),
        if (order!.customerPhone != null && order!.customerPhone!.isNotEmpty)
          _buildInfoRow('Phone Number', order!.customerPhone!,
            action: IconButton(
              onPressed: () => _makePhoneCall(order!.customerPhone!),
              icon: const Icon(Icons.phone, size: 18, color: Color(0xFF10B981)),
              tooltip: 'Call Customer',
            ),
          ),
        if (order!.customerAddress != null && order!.customerAddress!.isNotEmpty)
          _buildInfoRow('Customer Address', order!.customerAddress!),
      ],
    );
  }

  Widget _buildDeliveryInformationCard() {
    return _buildInfoCard(
      title: 'Delivery Information',
      icon: Icons.local_shipping,
      children: [
        if (order!.recipientName != null)
          _buildInfoRow('Recipient Name', order!.recipientName!),
        if (order!.recipientPhone != null && order!.recipientPhone!.isNotEmpty)
          _buildInfoRow('Recipient Phone', order!.recipientPhone!,
            action: IconButton(
              onPressed: () => _makePhoneCall(order!.recipientPhone!),
              icon: const Icon(Icons.phone, size: 18, color: Color(0xFF10B981)),
              tooltip: 'Call Recipient',
            ),
          ),
        if (order!.recipientAddress != null && order!.recipientAddress!.isNotEmpty)
          _buildInfoRow('Delivery Address', order!.recipientAddress!),
        _buildInfoRow('Delivery Type', order!.deliveryType == 'home_delivery' ? 'Home Delivery' : 'Point Delivery'),
      ],
    );
  }

  Widget _buildProductDetailsCard() {
    return _buildInfoCard(
      title: 'Product Details',
      icon: Icons.inventory_2,
      children: [
        _buildInfoRow('Product Name', order!.productName),
        _buildInfoRow('Quantity', '${order!.quantity} units'),
        _buildInfoRow('Unit Price', '৳${order!.unitPrice.toStringAsFixed(2)}'),
        _buildInfoRow('Subtotal', '৳${(order!.quantity * order!.unitPrice).toStringAsFixed(2)}'),
        if (order!.discount != null && order!.discount! > 0)
          _buildInfoRow('Discount', '৳${order!.discount!.toStringAsFixed(2)}'),
        _buildInfoRow('Total Amount', '৳${order!.totalAmount.toStringAsFixed(2)}',
          highlight: true),
      ],
    );
  }

  Widget _buildPaymentInformationCard() {
    return _buildInfoCard(
      title: 'Payment Information',
      icon: Icons.payment,
      children: [
        _buildInfoRow('Payment Method', 'Cash on Delivery'),
        _buildInfoRow('COD Amount', '৳${(order!.codAmount ?? order!.totalAmount).toStringAsFixed(2)}',
          highlight: true),
        _buildInfoRow('Payment Status', order!.paymentStatus ?? 'Pending'),
        if (order!.paymentDate != null)
          _buildInfoRow('Payment Date', _formatDate(order!.paymentDate!)),
      ],
    );
  }

  Widget _buildOrderNotesCard() {
    return _buildInfoCard(
      title: 'Order Notes',
      icon: Icons.note,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            order!.courierNotes!,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
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

  Widget _buildInfoRow(String label, String value, {bool highlight = false, bool copyable = false, Widget? action}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: Color(0xFF64748B))),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                      color: highlight ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                      fontSize: highlight ? 16 : 14,
                    ),
                  ),
                ),
                if (copyable)
                  IconButton(
                    onPressed: () => _copyToClipboard(value),
                    icon: const Icon(Icons.copy, size: 16, color: Color(0xFF64748B)),
                    tooltip: 'Copy to clipboard',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                if (action != null) action,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final salesProvider = context.read<SalesProvider>();

    return Column(
      children: [
        if (order!.status == 'in_review') ...[
          // Edit Order Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (order!.consignmentId != null && order!.consignmentId!.isNotEmpty && order!.consignmentId != 'PENDING_OFFLINE')
                  ? null
                  : () => _showEditOrderDialog(),
              icon: Icon(
                (order!.consignmentId != null && order!.consignmentId!.isNotEmpty && order!.consignmentId != 'PENDING_OFFLINE')
                    ? Icons.lock
                    : Icons.edit,
              ),
              label: Text(
                (order!.consignmentId != null && order!.consignmentId!.isNotEmpty && order!.consignmentId != 'PENDING_OFFLINE')
                    ? 'Order Locked'
                    : 'Edit Order',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons Row
          Row(
            children: [
              // Warning SMS Button
              if (order!.customerPhone != null && order!.customerPhone!.isNotEmpty)
                Expanded(
                  child: Consumer<SalesProvider>(
                    builder: (context, provider, _) => FutureBuilder<Map<String, dynamic>>(
                      future: provider.getWarningSMSButtonState(order!.customerPhone!),
                      builder: (context, snapshot) {
                        final buttonState = snapshot.data ?? {'canSend': true};
                        final canSend = buttonState['canSend'] as bool? ?? true;

                        return ElevatedButton.icon(
                          onPressed: canSend ? () => _sendWarningSMS() : null,
                          icon: Icon(canSend ? Icons.warning : Icons.check_circle),
                          label: Text(canSend ? 'Warning SMS' : 'SMS Sent'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canSend ? Colors.orange : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              if (order!.customerPhone != null && order!.customerPhone!.isNotEmpty) const SizedBox(width: 12),

              // Send to Courier Button
              if (order!.consignmentId == null || order!.consignmentId!.isEmpty || order!.consignmentId == 'PENDING_OFFLINE')
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendToCourier(),
                    icon: const Icon(Icons.local_shipping),
                    label: const Text('Send to Courier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Cancel Order Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _cancelOrder(),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Order'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ] else if (order!.consignmentId != null && order!.consignmentId!.isNotEmpty) ...[
          // Check Status Button for dispatched orders
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _updateCourierStatus(),
              icon: const Icon(Icons.refresh),
              label: const Text('Update Order Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Helper Methods
  Color _getStatusColor() {
    final status = order!.status == 'cancelled'
        ? 'cancelled'
        : order!.status == 'in_review'
          ? 'pending'
          : (order!.courierStatus ?? 'unknown');

    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'delivered':
        return const Color(0xFF10B981);
      case 'partial_delivered':
        return const Color(0xFF3B82F6);
      case 'returned':
        return const Color(0xFF6B7280);
      case 'hold':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  IconData _getStatusIcon() {
    final status = order!.status == 'cancelled'
        ? 'cancelled'
        : order!.status == 'in_review'
          ? 'pending'
          : (order!.courierStatus ?? 'unknown');

    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      case 'delivered':
        return Icons.check_circle;
      case 'partial_delivered':
        return Icons.local_shipping;
      case 'returned':
        return Icons.keyboard_return;
      case 'hold':
        return Icons.pause_circle;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusDisplayText() {
    final status = order!.status == 'cancelled'
        ? 'cancelled'
        : order!.status == 'in_review'
          ? 'pending'
          : (order!.courierStatus ?? 'unknown');

    switch (status) {
      case 'pending':
        return 'Order Pending';
      case 'cancelled':
        return 'Order Cancelled';
      case 'delivered':
        return 'Order Delivered';
      case 'partial_delivered':
        return 'Partially Delivered';
      case 'returned':
        return 'Order Returned';
      case 'hold':
        return 'Order on Hold';
      default:
        return 'Status Unknown';
    }
  }

  String _getStatusDescription() {
    final status = order!.status == 'cancelled'
        ? 'cancelled'
        : order!.status == 'in_review'
          ? 'pending'
          : (order!.courierStatus ?? 'unknown');

    switch (status) {
      case 'pending':
        return 'Order is ready to be sent to courier service';
      case 'cancelled':
        return 'This order has been cancelled';
      case 'delivered':
        return 'Order has been successfully delivered';
      case 'partial_delivered':
        return 'Order has been partially delivered';
      case 'returned':
        return 'Order has been returned by customer';
      case 'hold':
        return 'Order is currently on hold';
      default:
        return 'Order status is being updated';
    }
  }

  List<Map<String, dynamic>> _getOrderSteps() {
    final currentStatus = order!.status == 'cancelled'
        ? 'cancelled'
        : order!.status == 'in_review'
          ? 'pending'
          : (order!.courierStatus ?? 'unknown');

    final steps = [
      {
        'title': 'Order Placed',
        'description': 'Order has been received and is being processed',
        'isCompleted': true,
        'isActive': false,
        'timestamp': _formatDateTime(order!.saleDate),
      },
      {
        'title': 'Order Confirmed',
        'description': 'Order details have been verified',
        'isCompleted': order!.status != 'pending',
        'isActive': order!.status == 'pending',
        'timestamp': order!.status != 'pending' ? _formatDateTime(order!.saleDate) : null,
      },
      {
        'title': 'Sent to Courier',
        'description': 'Order has been dispatched to courier service',
        'isCompleted': order!.consignmentId != null && order!.consignmentId!.isNotEmpty,
        'isActive': order!.status == 'in_review' && (order!.consignmentId == null || order!.consignmentId!.isEmpty),
        'timestamp': order!.consignmentId != null && order!.consignmentId!.isNotEmpty
            ? 'Tracking ID: ${order!.consignmentId}' : null,
      },
      {
        'title': 'Out for Delivery',
        'description': 'Order is out for delivery',
        'isCompleted': ['delivered', 'partial_delivered'].contains(currentStatus),
        'isActive': ['hold', 'returned'].contains(currentStatus),
        'timestamp': null,
      },
      {
        'title': 'Delivered',
        'description': 'Order has been delivered successfully',
        'isCompleted': currentStatus == 'delivered',
        'isActive': currentStatus == 'partial_delivered',
        'timestamp': currentStatus == 'delivered' ? 'Order completed' : null,
      },
    ];

    if (currentStatus == 'cancelled') {
      return [
        steps[0],
        {
          'title': 'Order Cancelled',
          'description': 'Order has been cancelled',
          'isCompleted': true,
          'isActive': false,
          'timestamp': 'Cancelled',
        },
      ];
    }

    return steps;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Action Methods
  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        _shareOrder();
        break;
      case 'print':
        _printOrder();
        break;
      case 'copy_id':
        _copyToClipboard(order!.id);
        break;
    }
  }

  void _shareOrder() {
    // Implementation for sharing order details
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order details copied to clipboard'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _printOrder() {
    // Implementation for printing order
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Print functionality coming soon'),
        backgroundColor: Color(0xFF3B82F6),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $text'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch phone dialer'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching phone dialer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditOrderDialog() {
    // This would open the edit order dialog similar to the one in orders_list_screen.dart
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit order functionality - redirecting to edit screen'),
        backgroundColor: Color(0xFF3B82F6),
      ),
    );
  }

  void _sendWarningSMS() async {
    try {
      final messenger = ScaffoldMessenger.of(context);

      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Sending SMS...'),
            ],
          ),
          backgroundColor: Color(0xFF3B82F6),
        ),
      );

      final success = await _smsService.sendBengaliOrderCancellationSMS(
        customerName: order!.customerName,
        customerPhone: order!.customerPhone!,
      );

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(success ? '✅ Warning SMS sent successfully' : '❌ Failed to send SMS'),
            backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending SMS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendToCourier() async {
    try {
      final salesProvider = context.read<SalesProvider>();
      final messenger = ScaffoldMessenger.of(context);

      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Sending to courier...'),
            ],
          ),
          backgroundColor: Color(0xFF3B82F6),
        ),
      );

      final success = await salesProvider.sendOrderToCourier(order!.id);

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(success ? '✅ Order sent to courier successfully' : '❌ Failed to send order'),
            backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
          ),
        );

        if (success) {
          _loadOrderDetails(); // Refresh order details
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending to courier: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelOrder() async {
    final reason = await _showCancelReasonDialog();
    if (reason != null && reason.isNotEmpty) {
      try {
        final salesProvider = context.read<SalesProvider>();
        final messenger = ScaffoldMessenger.of(context);

        final success = await salesProvider.cancelOrder(order!.id, reason);

        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(success ? '✅ Order cancelled successfully' : '❌ Failed to cancel order'),
              backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
            ),
          );

          if (success) {
            _loadOrderDetails(); // Refresh order details
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling order: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _updateCourierStatus() async {
    try {
      final salesProvider = context.read<SalesProvider>();
      final messenger = ScaffoldMessenger.of(context);

      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Updating status...'),
            ],
          ),
          backgroundColor: Color(0xFF3B82F6),
        ),
      );

      final success = await salesProvider.updateCourierStatus(
        saleId: order!.id,
        consignmentId: order!.consignmentId,
      );

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(success ? '✅ Status updated successfully' : '❌ Failed to update status'),
            backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
          ),
        );

        if (success) {
          _loadOrderDetails(); // Refresh order details
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showCancelReasonDialog() async {
    final TextEditingController reasonController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Cancel Order'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cancel order for ${order!.customerName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${order!.quantity}x ${order!.productName}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cancel Reason *',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter reason for cancellation...',
                  contentPadding: EdgeInsets.all(12),
                ),
                maxLines: 3,
                maxLength: 200,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Cancel reason is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Reason must be at least 3 characters';
                  }
                  return null;
                },
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(reasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }
}