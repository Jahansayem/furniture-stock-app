import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../providers/sales_provider.dart';
import '../../models/sale.dart';
import '../../services/sms_service.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  final Map<String, DateTime> _smsSentTimes = {};
  String _selectedStatus = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final SmsService _smsService = SmsService();

  final Map<String, String> _statusLabels = {
    'all': 'All Orders',
    'pending': 'Pending',
    'delivered': 'Delivered',
    'partial_delivered': 'Partial Delivered',
    'cancelled': 'Cancelled',
    'returned': 'Returned',
    'hold': 'On Hold',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().fetchSales();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Orders List',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              context.read<SalesProvider>().fetchSales();
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
          IconButton(
            onPressed: () => _showFilterBottomSheet(context),
            icon: const Icon(Icons.filter_list, color: Colors.white),
          ),
        ],
      ),
      body: Consumer<SalesProvider>(
        builder: (context, salesProvider, _) {
          if (salesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (salesProvider.errorMessage != null) {
            return _buildErrorState(salesProvider);
          }

          final allOrders = salesProvider.sales
              .where((sale) => sale.saleType == 'online_cod')
              .toList();

          final filteredOrders = _filterOrders(allOrders);

          return Column(
            children: [
              // Search Bar
              Container(
                margin: const EdgeInsets.all(16),
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
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search orders by customer name or phone...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              ),

              // Status Filter Chips
              Container(
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _statusLabels.length,
                  itemBuilder: (context, index) {
                    final status = _statusLabels.keys.elementAt(index);
                    final label = _statusLabels[status]!;
                    final isSelected = _selectedStatus == status;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = status;
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFF3B82F6),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF3B82F6)
                              : Colors.grey[300]!,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Orders Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${filteredOrders.length} orders found',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Orders List
              Expanded(
                child: filteredOrders.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return _buildOrderCard(order);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Sale> _filterOrders(List<Sale> orders) {
    var filtered = orders.where((order) {
      // Filter by status
      if (_selectedStatus != 'all') {
        if (_selectedStatus == 'pending') {
          if (!(order.status == 'in_review' &&
                (order.consignmentId == null || order.consignmentId!.isEmpty))) {
            return false;
          }
        } else if (_selectedStatus == 'cancelled') {
          if (order.status != 'cancelled') {
            return false;
          }
        } else {
          if (order.courierStatus != _selectedStatus) {
            return false;
          }
        }
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final matchesName = order.customerName.toLowerCase().contains(_searchQuery);
        final matchesPhone = (order.customerPhone ?? '').toLowerCase().contains(_searchQuery);
        if (!matchesName && !matchesPhone) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort by sale date (newest first)
    filtered.sort((a, b) => b.saleDate.compareTo(a.saleDate));

    return filtered;
  }

  Widget _buildOrderCard(Sale order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getStatusColor(order).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(order),
                  color: _getStatusColor(order),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Customer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (order.customerPhone != null && order.customerPhone!.isNotEmpty)
                      Text(
                        order.customerPhone!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
            GestureDetector(
              onTap: () => _copyToClipboard(order.consignmentId!),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 16,
                      color: const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tracking: ${order.consignmentId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.copy,
                      size: 14,
                      color: const Color(0xFFD97706),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Action Buttons - Updated with comprehensive functionality
          const SizedBox(height: 12),
          if (order.status == 'in_review') ...[
            _buildInReviewActions(order),
          ] else if (order.consignmentId != null &&
                     order.consignmentId!.isNotEmpty &&
                     order.consignmentId != 'PENDING_OFFLINE') ...[
            _buildDispatchedActions(order),
          ] else ...[
            _buildDefaultActions(order),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            'No orders found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Orders will appear here once created',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(SalesProvider salesProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              salesProvider.errorMessage ?? 'Unknown error occurred',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              salesProvider.fetchSales();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_list),
                const SizedBox(width: 8),
                const Text(
                  'Filter Orders',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statusLabels.entries.map((entry) {
                final status = entry.key;
                final label = entry.value;
                final isSelected = _selectedStatus == status;

                return FilterChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = status;
                    });
                    Navigator.pop(context);
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: const Color(0xFF3B82F6),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(Sale order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Customer', order.customerName),
              if (order.customerPhone != null)
                _buildDetailRow('Phone', order.customerPhone!),
              _buildDetailRow('Product', '${order.quantity}x ${order.productName}'),
              _buildDetailRow('Amount', '৳${(order.codAmount ?? order.totalAmount).toStringAsFixed(2)}'),
              _buildDetailRow('Status', _getStatusText(order)),
              if (order.consignmentId != null)
                _buildDetailRow('Tracking ID', order.consignmentId!),
              if (order.recipientAddress != null)
                _buildDetailRow('Address', order.recipientAddress!),
              _buildDetailRow('Order Date',
                '${order.saleDate.day}/${order.saleDate.month}/${order.saleDate.year}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tracking ID copied: $text'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildInReviewActions(Sale order) {
    final salesProvider = context.read<SalesProvider>();

    return Row(
      children: [
        // Edit Order Button
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

        // Warning SMS Button
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

        // Send to Steadfast Button
        if (order.consignmentId == null || order.consignmentId!.isEmpty || order.consignmentId == 'PENDING_OFFLINE')
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
          )
        else
          // Already Sent - Show status instead
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

        // Cancel Order Button
        if (order.consignmentId == null || order.consignmentId!.isEmpty || order.consignmentId == 'PENDING_OFFLINE')
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
          )
        else
          // Can't Cancel - Already sent to courier
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

        // Phone Call Button
        if (order.customerPhone != null && order.customerPhone!.isNotEmpty) ...[
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => _makePhoneCall(order.customerPhone!),
            icon: const Icon(Icons.phone, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
              foregroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDispatchedActions(Sale order) {
    final salesProvider = context.read<SalesProvider>();

    return Column(
      children: [
        // Show dispatched status
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

        // Check Status Button
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
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
            if (order.customerPhone != null && order.customerPhone!.isNotEmpty) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _makePhoneCall(order.customerPhone!),
                icon: const Icon(Icons.phone, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                  foregroundColor: const Color(0xFF10B981),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDefaultActions(Sale order) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.go('/orders2/details/${order.id}'),
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('View Details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3B82F6),
              side: const BorderSide(color: Color(0xFF3B82F6)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (order.customerPhone != null && order.customerPhone!.isNotEmpty)
          IconButton(
            onPressed: () => _makePhoneCall(order.customerPhone!),
            icon: const Icon(Icons.phone, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
              foregroundColor: const Color(0xFF10B981),
            ),
          ),
      ],
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

  Color _getStatusColor(Sale order) {
    final status = order.status == 'cancelled'
        ? 'cancelled'
        : order.status == 'in_review'
          ? 'pending'
          : (order.courierStatus ?? 'unknown');

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

  IconData _getStatusIcon(Sale order) {
    final status = order.status == 'cancelled'
        ? 'cancelled'
        : order.status == 'in_review'
          ? 'pending'
          : (order.courierStatus ?? 'unknown');

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

  String _getStatusText(Sale order) {
    final status = order.status == 'cancelled'
        ? 'cancelled'
        : order.status == 'in_review'
          ? 'pending'
          : (order.courierStatus ?? 'unknown');

    switch (status) {
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
      case 'delivered':
        return 'Delivered';
      case 'partial_delivered':
        return 'Partial Delivered';
      case 'returned':
        return 'Returned';
      case 'hold':
        return 'On Hold';
      default:
        return 'Unknown';
    }
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

  String _formatTime12Hour(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '$displayHour:$minute $period';
  }
}