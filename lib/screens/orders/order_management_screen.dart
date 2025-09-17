import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../providers/sales_provider.dart';
import '../../models/sale.dart';
import '../../services/sms_service.dart';
import '../../widgets/order_details_modal.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final Map<String, DateTime> _smsSentTimes = {};
  String _selectedStatus = 'all';
  final SmsService _smsService = SmsService();
  
  final Map<String, String> _statusLabels = {
    'all': 'All Orders',
    'pending': 'Ready to Send',
    'delivered': 'Delivered',
    'partial_delivered': 'Partial Delivered',
    'cancelled': 'Cancelled',
    'returned': 'Returned',
    'hold': 'On Hold',
    'in_review': 'In Review',
    'unknown': 'Unknown',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().fetchSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF), // AppTheme.lightBlue
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.list_alt, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Order Management'),
          ],
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: () {
              context.go('/sales/online-cod');
            },
            icon: const Icon(Icons.add),
            tooltip: 'Add New Order',
          ),
          IconButton(
            onPressed: () {
              context.read<SalesProvider>().fetchSales();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Orders',
          ),
        ],
      ),
      body: Consumer<SalesProvider>(
        builder: (context, salesProvider, _) {
          if (salesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (salesProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${salesProvider.errorMessage}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      salesProvider.fetchSales();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Get all online COD orders
          final allOrders = salesProvider.sales
              .where((sale) => sale.saleType == 'online_cod')
              .toList();

          // Filter orders by status
          final filteredOrders = _selectedStatus == 'all'
              ? allOrders
              : allOrders.where((order) {
                  // For pending status, check if order hasn't been sent to courier yet (in_review)
                  if (_selectedStatus == 'pending') {
                    return order.status == 'in_review' && (order.consignmentId == null || order.consignmentId!.isEmpty);
                  }
                  // For cancelled status, check order status directly
                  if (_selectedStatus == 'cancelled') {
                    return order.status == 'cancelled';
                  }
                  // For other statuses, check courier status from API
                  return order.courierStatus == _selectedStatus;
                }).toList();

          return Column(
            children: [
              // Compact Status Filter Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        items: _statusLabels.entries.map((entry) {
                          final status = entry.key;
                          final label = entry.value;
                          final count = status == 'all' 
                              ? allOrders.length
                              : (status == 'pending'
                                  ? allOrders.where((o) => o.status == 'in_review' && (o.consignmentId == null || o.consignmentId!.isEmpty)).length
                                  : (status == 'cancelled'
                                      ? allOrders.where((o) => o.status == 'cancelled').length
                                      : allOrders.where((o) => o.courierStatus == status).length));
                          
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text('$label ($count)', style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedStatus = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Orders List
              Expanded(
                child: filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No ${_statusLabels[_selectedStatus]?.toLowerCase()} orders found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return _buildOrderCard(context, order, salesProvider);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Sale order, SalesProvider salesProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => OrderDetailsModal.show(context, order),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            order.customerPhone ?? 'No phone',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          if (order.customerPhone != null && order.customerPhone!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _makePhoneCall(order.customerPhone!),
                              child: Icon(
                                Icons.phone,
                                color: Colors.green[600],
                                size: 18,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(order),
              ],
            ),

            const SizedBox(height: 12),

            // Product Info
            Row(
              children: [
                Icon(Icons.inventory, color: Colors.blue[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  '${order.quantity}x ${order.productName}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Amount Info
            Row(
              children: [
                Icon(Icons.attach_money, color: Colors.green[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  'COD: ৳${order.codAmount?.toStringAsFixed(2) ?? order.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: Colors.red[600], size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.recipientAddress ?? order.customerAddress ?? 'No address',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            if (order.consignmentId != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.orange[600], size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'Parcel ID: ${order.consignmentId}',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            if (order.consignmentId != null) {
                              await Clipboard.setData(ClipboardData(text: order.consignmentId!));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Parcel ID copied: ${order.consignmentId}'),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange[300]!),
                            ),
                            child: Icon(
                              Icons.copy,
                              size: 14,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // All Action Buttons in One Row - Edit, Warning SMS, Send to Steadfast, Cancel
            if (order.status == 'in_review') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  // 1. Edit Order Button - Only allow editing if not yet sent to courier
                  Expanded(
                    child: OutlinedButton(
                      onPressed: (salesProvider.isLoading || 
                                 (order.consignmentId != null && 
                                  order.consignmentId!.isNotEmpty && 
                                  order.consignmentId != 'PENDING_OFFLINE')) ? null : () async {
                        final success = await _showEditOrderDialog(context, order, salesProvider);
                        if (success == true && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: (order.consignmentId != null && 
                                         order.consignmentId!.isNotEmpty && 
                                         order.consignmentId != 'PENDING_OFFLINE') 
                                       ? Colors.grey 
                                       : Colors.blue,
                        side: BorderSide(color: (order.consignmentId != null && 
                                                order.consignmentId!.isNotEmpty && 
                                                order.consignmentId != 'PENDING_OFFLINE') 
                                              ? Colors.grey[300]! 
                                              : Colors.blue[300]!),
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon((order.consignmentId != null && 
                                order.consignmentId!.isNotEmpty && 
                                order.consignmentId != 'PENDING_OFFLINE') 
                               ? Icons.lock 
                               : Icons.edit, 
                               size: 14),
                          const SizedBox(height: 2),
                          Text((order.consignmentId != null && 
                                order.consignmentId!.isNotEmpty && 
                                order.consignmentId != 'PENDING_OFFLINE') 
                               ? 'Locked' 
                               : 'Edit', 
                               style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  
                  // 2. Warning SMS Button - Only if phone number exists and order not yet sent to courier
                  if (order.customerPhone != null && 
                      order.customerPhone!.isNotEmpty && 
                      (order.consignmentId == null || 
                       order.consignmentId!.isEmpty || 
                       order.consignmentId == 'PENDING_OFFLINE')) ...[
                    Expanded(
                      child: FutureBuilder<Map<String, dynamic>>(
                        key: ValueKey('${order.customerPhone}_${_smsSentTimes[order.customerPhone]?.millisecondsSinceEpoch ?? 0}'),
                        future: salesProvider.getWarningSMSButtonState(order.customerPhone!),
                        builder: (context, snapshot) {
                          final buttonState = snapshot.data ?? {
                            'canSend': true, 
                            'buttonText': 'Warning SMS', 
                            'isEnabled': true,
                            'hoursRemaining': 0,
                            'minutesRemaining': 0
                          };
                          final canSend = buttonState['canSend'] as bool? ?? true;
                          final buttonText = buttonState['buttonText'] as String? ?? 'Warning SMS';
                          final isEnabled = buttonState['isEnabled'] as bool? ?? true;
                          final hoursRemaining = (buttonState['hoursRemaining'] as int?) ?? 0;
                          final minutesRemaining = (buttonState['minutesRemaining'] as int?) ?? 0;
                          
                          return ElevatedButton(
                            onPressed: (salesProvider.isLoading || !isEnabled) ? null : () async {
                              final confirmed = await _showWarningSMSConfirmationDialog(context, order);
                              if (confirmed == true && mounted) {
                                await _sendWarningSMS(context, order, salesProvider);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canSend ? Colors.red[600] : Colors.grey[400],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(canSend ? Icons.warning : Icons.check_circle, size: 14),
                                const SizedBox(height: 2),
                                Text(
                                  canSend ? 'Warning' : 'Sent',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                if (!canSend && (hoursRemaining > 0 || minutesRemaining > 0))
                                  Text(
                                    '${hoursRemaining}h ${minutesRemaining}m',
                                    style: const TextStyle(fontSize: 8),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  
                  // 3. Send to Steadfast Button - Only show if not yet sent to courier
                  if (order.consignmentId == null || order.consignmentId!.isEmpty || order.consignmentId == 'PENDING_OFFLINE') ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: salesProvider.isLoading ? null : () async {
                          if (!mounted) return;
                          final messenger = ScaffoldMessenger.of(context);
                          final success = await salesProvider.sendOrderToCourier(order.id);
                          if (mounted) {
                            if (success) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Order sent to Steadfast courier successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(salesProvider.errorMessage ?? 'Failed to send order'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.send, size: 14),
                            const SizedBox(height: 2),
                            const Text('Send', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ] else ...[
                    // 3. Already Sent - Show status instead
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          border: Border.all(color: Colors.blue[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 14, color: Colors.blue[600]),
                            const SizedBox(height: 2),
                            Text('Sent', style: TextStyle(fontSize: 10, color: Colors.blue[700])),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  
                  // 4. Cancel Order Button - Only show if not yet sent to courier
                  if (order.consignmentId == null || order.consignmentId!.isEmpty || order.consignmentId == 'PENDING_OFFLINE') ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: salesProvider.isLoading ? null : () async {
                          final cancelReason = await _showCancelReasonDialog(context, order);
                          if (cancelReason != null && cancelReason.isNotEmpty && mounted) {
                            final messenger = ScaffoldMessenger.of(context);
                            final success = await salesProvider.cancelOrder(order.id, cancelReason);
                            if (mounted) {
                              if (success) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Order cancelled successfully and stock restored!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(salesProvider.errorMessage ?? 'Failed to cancel order'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red[300]!),
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cancel_outlined, size: 14),
                            const SizedBox(height: 2),
                            const Text('Cancel', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // 4. Can't Cancel - Already sent to courier
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.block, size: 14, color: Colors.grey[500]),
                            const SizedBox(height: 2),
                            Text('Locked', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ] else if (order.consignmentId != null && 
                       order.consignmentId!.isNotEmpty && 
                       order.consignmentId != 'PENDING_OFFLINE') ...[
              // Show dispatched status for orders sent to courier
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping, color: Colors.green[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Dispatched to Courier',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'This order has been sent to Steadfast courier service',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Check Status Button - Separate row for mobile
            if (order.consignmentId != null && 
                order.consignmentId != 'PENDING_OFFLINE') ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: salesProvider.isLoading ? null : () async {
                    if (!mounted) return;
                    final messenger = ScaffoldMessenger.of(context);
                    final success = await salesProvider.updateCourierStatus(
                      saleId: order.id,
                      consignmentId: order.consignmentId,
                    );
                    if (mounted) {
                      if (success) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Status updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        final errorMessage = salesProvider.errorMessage ?? 'Failed to update status';
                        messenger.showSnackBar(
                          SnackBar(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Status update failed', 
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(errorMessage, style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.info, size: 16),
                                    const SizedBox(width: 4),
                                    const Text('Try: Settings > Debug > Steadfast Test', 
                                      style: TextStyle(fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 14),
                      const SizedBox(width: 4),
                      const Text('Check Status', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(Sale order) {
    String statusText;
    Color backgroundColor;
    Color textColor;

    // Use exact Steadfast API status values or order status
    final currentStatus = order.status == 'cancelled' 
        ? 'cancelled'
        : order.status == 'in_review'
          ? 'in_review'
          : (order.courierStatus ?? 
             (order.status == 'pending' ? 'pending' : 'unknown'));

    switch (currentStatus) {
      case 'in_review':
        statusText = 'In Review';
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case 'pending':
        statusText = 'Pending';
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case 'cancelled':
        statusText = 'Cancelled';
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      case 'delivered':
        statusText = 'Delivered';
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 'partial_delivered':
        statusText = 'Partial Delivered';
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case 'returned':
        statusText = 'Returned';
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        break;
      case 'hold':
        statusText = 'On Hold';
        backgroundColor = Colors.amber[100]!;
        textColor = Colors.amber[800]!;
        break;
      case 'in_review':
        statusText = 'In Review';
        backgroundColor = Colors.purple[100]!;
        textColor = Colors.purple[800]!;
        break;
      case 'unknown':
      default:
        statusText = 'Unknown';
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<String?> _showCancelReasonDialog(BuildContext context, Sale order) async {
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
                'Cancel order for ${order.customerName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${order.quantity}x ${order.productName}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Text(
                'This will:\n• Cancel the order permanently\n• Restore stock\n• Send notifications',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
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

  Future<bool?> _showEditOrderDialog(BuildContext context, Sale order, SalesProvider salesProvider) async {
    final TextEditingController customerNameController = TextEditingController(text: order.customerName);
    final TextEditingController customerPhoneController = TextEditingController(text: order.customerPhone ?? '');
    final TextEditingController customerAddressController = TextEditingController(text: order.customerAddress ?? '');
    final TextEditingController recipientNameController = TextEditingController(text: order.recipientName ?? order.customerName);
    final TextEditingController recipientPhoneController = TextEditingController(text: order.recipientPhone ?? order.customerPhone ?? '');
    final TextEditingController recipientAddressController = TextEditingController(text: order.recipientAddress ?? order.customerAddress ?? '');
    final TextEditingController codAmountController = TextEditingController(text: order.codAmount?.toStringAsFixed(2) ?? order.totalAmount.toStringAsFixed(2));
    final TextEditingController courierNotesController = TextEditingController(text: order.courierNotes ?? '');
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    
    String deliveryType = order.deliveryType ?? 'home_delivery';
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.blue, size: 24),
            const SizedBox(width: 8),
            const Text('Edit Order'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order for ${order.productName} (${order.quantity} units)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Customer Details Section
                  const Text(
                    'Customer Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: customerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Customer name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: customerPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Phone',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: customerAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Address',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Delivery Details Section
                  const Text(
                    'Delivery Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: recipientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Recipient Name',
                      border: OutlineInputBorder(),
                      isDense: true,
                      hintText: 'Person who will receive delivery',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Recipient name is required';
                      }
                      if (value.length > 100) {
                        return 'Name must be less than 100 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: recipientPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Recipient Phone (Required)',
                      border: OutlineInputBorder(),
                      isDense: true,
                      hintText: 'Exactly 11 digits for courier service',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Phone number is required for delivery';
                      }
                      if (value.length != 11 || !RegExp(r'^\d{11}$').hasMatch(value)) {
                        return 'Please enter exactly 11 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: recipientAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Address (Required)',
                      border: OutlineInputBorder(),
                      isDense: true,
                      hintText: 'Full address for courier delivery',
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Delivery address is required';
                      }
                      if (value.length > 250) {
                        return 'Address must be less than 250 characters';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Delivery Type Selection
                  const Text(
                    'Delivery Type',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  StatefulBuilder(
                    builder: (context, setState) => Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Point Delivery'),
                          subtitle: const Text('Collection Point'),
                          value: 'point_delivery',
                          groupValue: deliveryType,
                          dense: true,
                          onChanged: (value) {
                            setState(() {
                              deliveryType = value!;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Home Delivery'),
                          subtitle: const Text('Door to Door'),
                          value: 'home_delivery',
                          groupValue: deliveryType,
                          dense: true,
                          onChanged: (value) {
                            setState(() {
                              deliveryType = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Payment & Notes Section
                  const Text(
                    'Payment & Notes',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: codAmountController,
                    decoration: const InputDecoration(
                      labelText: 'COD Amount',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixText: '৳ ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'COD amount is required';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount < 0) {
                        return 'Enter valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: courierNotesController,
                    decoration: const InputDecoration(
                      labelText: 'Special Instructions (Optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                      hintText: 'Any special delivery instructions',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Call update method
                final success = await salesProvider.updatePendingOrder(
                  orderId: order.id,
                  customerName: customerNameController.text.trim(),
                  customerPhone: customerPhoneController.text.trim().isEmpty 
                      ? null : customerPhoneController.text.trim(),
                  customerAddress: customerAddressController.text.trim().isEmpty 
                      ? null : customerAddressController.text.trim(),
                  recipientName: recipientNameController.text.trim(),
                  recipientPhone: recipientPhoneController.text.trim(),
                  recipientAddress: recipientAddressController.text.trim(),
                  deliveryType: deliveryType,
                  codAmount: double.parse(codAmountController.text.trim()),
                  courierNotes: courierNotesController.text.trim().isEmpty 
                      ? null : courierNotesController.text.trim(),
                );
                
                if (context.mounted) {
                  Navigator.of(context).pop(success);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update Order'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showWarningSMSConfirmationDialog(BuildContext context, Sale order) async {
    final salesProvider = context.read<SalesProvider>();
    
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => FutureBuilder<Map<String, dynamic>>(
        future: salesProvider.getWarningSMSButtonState(order.customerPhone!),
        builder: (context, snapshot) {
          final buttonState = snapshot.data ?? {
            'canSend': true,
            'hoursRemaining': 0,
            'minutesRemaining': 0
          };
          final canSend = buttonState['canSend'] as bool? ?? true;
          final hoursRemaining = (buttonState['hoursRemaining'] as int?) ?? 0;
          final minutesRemaining = (buttonState['minutesRemaining'] as int?) ?? 0;
          
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 24),
                SizedBox(width: 8),
                Text('Send Warning SMS'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send warning SMS to ${order.customerName}?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Phone: ${order.customerPhone}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                
                // Rate limit warning
                if (!canSend) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.red[600], size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              'SMS Rate Limit',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Warning SMS was already sent recently. Next SMS can be sent in ${hoursRemaining}h ${minutesRemaining}m.',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    border: Border.all(color: Colors.orange[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'SMS Message:\n\nআধুনিক ফার্নিচার:\nহ্যালো [CustomerName], আপনার সোফা অর্ডারটি কুরিয়ারে বুকিং এর জন্য প্রস্তুত ! আমরা কনফার্মেশনের জন্য কল দিয়েছিলাম, কিন্তু সম্ভবত আপনি ব্যস্ত ছিলেন। অনুগ্রহ করে আমাদের কল করে অর্ডারটি নিশ্চিত করুন,অন্যথায় অর্ডারটি হোল্ডে থাকবে।\nধন্যবাদ। যোগাযোগ করুন: 01798139179, 01707346634',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  canSend 
                    ? 'This SMS will be sent immediately.'
                    : 'Cannot send SMS due to 16-hour rate limit.',
                  style: TextStyle(
                    color: canSend ? Colors.red[600] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: canSend ? () => Navigator.of(context).pop(true) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSend ? Colors.red : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: Text(canSend ? 'Send SMS' : 'Cannot Send'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sendWarningSMS(BuildContext context, Sale order, SalesProvider salesProvider) async {
    try {
      final messenger = ScaffoldMessenger.of(context);
      
      // Show loading indicator
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Text('পাঠানো হচ্ছে...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
      
      final smsSuccess = await _smsService.sendBengaliOrderCancellationSMS(
        customerName: order.customerName,
        customerPhone: order.customerPhone!,
      );
      
      // Remove loading and show result
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        if (smsSuccess) {
          final now = DateTime.now();
          final timeString = _formatTime12Hour(now);
          
          messenger.showSnackBar(
            SnackBar(
              content: Text('✅ Warning SMS sent to ${order.customerPhone} at $timeString'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          // Record SMS send time for this phone number to trigger refresh
          _smsSentTimes[order.customerPhone!] = DateTime.now();
          
          // Trigger a rebuild to update button state
          setState(() {});
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to send SMS. Please try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error sending SMS: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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

  String _formatTime12Hour(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '$displayHour:$minute $period';
  }
}