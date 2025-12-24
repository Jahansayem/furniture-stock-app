import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../providers/sales_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../models/sale.dart';
import '../../models/stock.dart';
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
  final ScrollController _scrollController = ScrollController();
  double? _savedScrollPosition;

  // Bulk send functionality
  bool _isSelectionMode = false;
  final Set<String> _selectedOrderIds = {};

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
    _scrollController.dispose();
    super.dispose();
  }

  void _saveScrollPosition() {
    if (_scrollController.hasClients) {
      _savedScrollPosition = _scrollController.offset;
    }
  }

  void _restoreScrollPosition() {
    if (_savedScrollPosition != null && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && mounted) {
          _scrollController.jumpTo(_savedScrollPosition!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: _isSelectionMode
            ? Text(
                '${_selectedOrderIds.length} selected',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              )
            : const Text(
                'Orders List',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedOrderIds.clear();
                  });
                },
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              onPressed: _selectAllPendingOrders,
              icon: const Icon(Icons.select_all, color: Colors.white),
              tooltip: 'Select All Pending',
            ),
          ] else ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _isSelectionMode = true;
                });
              },
              icon: const Icon(Icons.checklist, color: Colors.white),
              tooltip: 'Bulk Send Mode',
            ),
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
                        controller: _scrollController,
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
      floatingActionButton: _isSelectionMode && _selectedOrderIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showBulkSendConfirmation,
              backgroundColor: const Color(0xFF10B981),
              icon: const Icon(Icons.send),
              label: Text('Send ${_selectedOrderIds.length} Orders'),
            )
          : null,
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

    return filtered;
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
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
            'Orders will appear here once created',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Sale order) {
    final statusColor = _getStatusColor(order);
    final statusIcon = _getStatusIcon(order);
    final statusText = _getStatusText(order);
    final isSelected = _selectedOrderIds.contains(order.id);
    final canBeSelected = order.consignmentId == null || order.consignmentId!.isEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _isSelectionMode
            ? () {
                if (canBeSelected) {
                  setState(() {
                    if (isSelected) {
                      _selectedOrderIds.remove(order.id);
                    } else {
                      _selectedOrderIds.add(order.id);
                    }
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('This order is already sent to courier'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            : () {
                // Navigate to order details in normal mode
                context.go('/orders2/details/${order.id}');
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: _isSelectionMode && isSelected
                ? Border.all(color: const Color(0xFF10B981), width: 3)
                : null,
            color: _isSelectionMode && !canBeSelected
                ? Colors.grey.withOpacity(0.1)
                : null,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSelectionMode)
                Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: canBeSelected
                          ? (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedOrderIds.add(order.id);
                                } else {
                                  _selectedOrderIds.remove(order.id);
                                }
                              });
                            }
                          : null,
                      activeColor: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        canBeSelected ? 'Select to send' : 'Already sent',
                        style: TextStyle(
                          fontSize: 12,
                          color: canBeSelected ? Colors.grey[600] : Colors.grey[400],
                          fontStyle: canBeSelected ? FontStyle.normal : FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (order.customerPhone != null)
              Text(
                order.customerPhone!,
                style: TextStyle(color: Colors.grey[600]),
              ),
            const SizedBox(height: 4),
            Text(
              '${order.quantity}x ${order.productName}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              '৳${(order.codAmount ?? order.totalAmount).toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF10B981),
              ),
            ),
            if (order.consignmentId != null && order.consignmentId!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Tracking: ${order.consignmentId}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _copyToClipboard(order.consignmentId!),
                      icon: const Icon(Icons.copy, size: 14),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            if (order.status == 'in_review' &&
                (order.consignmentId == null || order.consignmentId!.isEmpty || order.consignmentId == 'PENDING_OFFLINE'))
              _buildInReviewActions(order)
            else if (order.consignmentId != null && order.consignmentId!.isNotEmpty && order.consignmentId != 'PENDING_OFFLINE')
              _buildDispatchedActions(order)
            else
              _buildDefaultActions(order),
          ],
        ),
      ),
    ),
    );
  }

  void _selectAllPendingOrders() {
    final salesProvider = context.read<SalesProvider>();
    setState(() {
      _selectedOrderIds.clear();
      for (final sale in salesProvider.sales) {
        if (sale.consignmentId == null || sale.consignmentId!.isEmpty) {
          _selectedOrderIds.add(sale.id);
        }
      }
    });
  }

  void _showBulkSendConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.send, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Bulk Send to Courier'),
          ],
        ),
        content: Text(
          'Send ${_selectedOrderIds.length} orders to Steadfast courier?\n\n'
          'This will create courier consignments for all selected orders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.send),
            label: const Text('Send Orders'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _performBulkSend();
    }
  }

  void _performBulkSend() async {
    final salesProvider = context.read<SalesProvider>();
    final messenger = ScaffoldMessenger.of(context);

    // Show loading
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text('Sending ${_selectedOrderIds.length} orders to courier...'),
          ],
        ),
        backgroundColor: const Color(0xFF3B82F6),
        duration: const Duration(minutes: 2),
      ),
    );

    // Perform bulk send
    final result = await salesProvider.sendBulkToCourier(
      saleIds: _selectedOrderIds.toList(),
    );

    if (mounted) {
      // Hide loading
      messenger.clearSnackBars();

      // Show result
      messenger.showSnackBar(
        SnackBar(
          content: Text(result['message'] as String),
          backgroundColor: result['success'] == true
              ? const Color(0xFF10B981)
              : Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );

      // Exit selection mode
      setState(() {
        _isSelectionMode = false;
        _selectedOrderIds.clear();
      });

      // Show detailed results if there were failures
      if (result['failureCount'] != null && result['failureCount'] > 0) {
        _showBulkSendResults(result);
      }
    }
  }

  void _showBulkSendResults(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Send Results'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ Success: ${result['successCount']} orders'),
              const SizedBox(height: 8),
              Text('❌ Failed: ${result['failureCount']} orders'),
              const SizedBox(height: 16),
              if (result['results'] != null) ...[
                const Text(
                  'Failed Orders:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...((result['results'] as List).where((r) => r.status == 'error').map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• ${r.invoice}: ${r.message ?? "Unknown error"}'),
                  ),
                )),
              ],
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
              _saveScrollPosition();
              final success = await _showEditOrderBottomSheet(context, order, salesProvider);
              _restoreScrollPosition();
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
                      _saveScrollPosition();
                      await _sendWarningSMS(context, order, salesProvider);
                      _restoreScrollPosition();
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
                _saveScrollPosition();
                final messenger = ScaffoldMessenger.of(context);
                final success = await salesProvider.sendOrderToCourier(order.id);
                _restoreScrollPosition();
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
                  _saveScrollPosition();
                  final messenger = ScaffoldMessenger.of(context);
                  final success = await salesProvider.cancelOrder(order.id, cancelReason);
                  _restoreScrollPosition();
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
                  _saveScrollPosition();
                  final messenger = ScaffoldMessenger.of(context);
                  final success = await salesProvider.updateCourierStatus(
                    saleId: order.id,
                    consignmentId: order.consignmentId,
                  );
                  _restoreScrollPosition();
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

  Future<bool?> _showEditOrderBottomSheet(BuildContext context, Sale order, SalesProvider salesProvider) async {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditOrderBottomSheet(
        order: order,
        salesProvider: salesProvider,
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

// Mobile-responsive bottom sheet for editing orders
class _EditOrderBottomSheet extends StatefulWidget {
  final Sale order;
  final SalesProvider salesProvider;

  const _EditOrderBottomSheet({
    required this.order,
    required this.salesProvider,
  });

  @override
  State<_EditOrderBottomSheet> createState() => _EditOrderBottomSheetState();
}

class _EditOrderBottomSheetState extends State<_EditOrderBottomSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Product fields
  late String _selectedProductId;
  late String _selectedProductName;
  late double _unitPrice;
  late TextEditingController _quantityController;

  // Customer fields
  late TextEditingController _customerNameController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _customerAddressController;

  // Delivery fields
  late TextEditingController _recipientNameController;
  late TextEditingController _recipientPhoneController;
  late TextEditingController _recipientAddressController;
  late String _deliveryType;

  // Payment fields
  late TextEditingController _codAmountController;
  late TextEditingController _courierNotesController;

  bool _isLoading = false;
  int _availableStock = 0;

  @override
  void initState() {
    super.initState();
    final order = widget.order;

    // Initialize product fields
    _selectedProductId = order.productId;
    _selectedProductName = order.productName ?? '';
    _unitPrice = order.unitPrice;
    _quantityController = TextEditingController(text: order.quantity.toString());

    // Initialize customer fields
    _customerNameController = TextEditingController(text: order.customerName);
    _customerPhoneController = TextEditingController(text: order.customerPhone ?? '');
    _customerAddressController = TextEditingController(text: order.customerAddress ?? '');

    // Initialize delivery fields
    _recipientNameController = TextEditingController(text: order.recipientName ?? order.customerName);
    _recipientPhoneController = TextEditingController(text: order.recipientPhone ?? order.customerPhone ?? '');
    _recipientAddressController = TextEditingController(text: order.recipientAddress ?? order.customerAddress ?? '');
    _deliveryType = order.deliveryType ?? 'home_delivery';

    // Initialize payment fields
    _codAmountController = TextEditingController(
      text: order.codAmount?.toStringAsFixed(0) ?? order.totalAmount.toStringAsFixed(0),
    );
    _courierNotesController = TextEditingController(text: order.courierNotes ?? '');

    // Load available stock
    _loadAvailableStock();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _recipientAddressController.dispose();
    _codAmountController.dispose();
    _courierNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableStock() async {
    final stockProvider = context.read<StockProvider>();
    final stock = stockProvider.stocks.firstWhere(
      (s) => s.productId == _selectedProductId && s.locationId == widget.order.locationId,
      orElse: () => Stock(
        id: '',
        productId: '',
        locationId: '',
        quantity: 0,
        updatedAt: DateTime.now(),
      ),
    );

    // If same product as original, add back original quantity
    final adjustedStock = (_selectedProductId == widget.order.productId)
        ? stock.quantity + widget.order.quantity
        : stock.quantity;

    setState(() {
      _availableStock = adjustedStock;
    });
  }

  void _onProductChanged(String? productId) {
    if (productId == null) return;

    final productProvider = context.read<ProductProvider>();
    final product = productProvider.products.firstWhere((p) => p.id == productId);

    setState(() {
      _selectedProductId = productId;
      _selectedProductName = product.productName;
      _unitPrice = product.price;
    });

    _loadAvailableStock();
  }

  double get _totalAmount {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    return quantity * _unitPrice;
  }

  int get _currentQuantity {
    return int.tryParse(_quantityController.text) ?? 0;
  }

  bool get _hasStockError {
    return _currentQuantity > _availableStock;
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_hasStockError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient stock. Available: $_availableStock'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await widget.salesProvider.updatePendingOrder(
      orderId: widget.order.id,
      customerName: _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim().isEmpty
          ? null : _customerPhoneController.text.trim(),
      customerAddress: _customerAddressController.text.trim().isEmpty
          ? null : _customerAddressController.text.trim(),
      recipientName: _recipientNameController.text.trim(),
      recipientPhone: _recipientPhoneController.text.trim(),
      recipientAddress: _recipientAddressController.text.trim(),
      deliveryType: _deliveryType,
      codAmount: double.parse(_codAmountController.text.trim()),
      courierNotes: _courierNotesController.text.trim().isEmpty
          ? null : _courierNotesController.text.trim(),
      // Product change fields
      newProductId: _selectedProductId != widget.order.productId ? _selectedProductId : null,
      newProductName: _selectedProductId != widget.order.productId ? _selectedProductName : null,
      newQuantity: _currentQuantity != widget.order.quantity ? _currentQuantity : null,
      newUnitPrice: _unitPrice != widget.order.unitPrice ? _unitPrice : null,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.of(context).pop(success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle and Header
          _buildHeader(),

          // Form Content
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: bottomPadding + 16,
                ),
                children: [
                  // Product Section
                  _buildSectionHeader('Product Details', Icons.inventory_2),
                  _buildProductSection(),
                  const SizedBox(height: 20),

                  // Customer Section
                  _buildSectionHeader('Customer Details', Icons.person),
                  _buildCustomerSection(),
                  const SizedBox(height: 20),

                  // Delivery Section
                  _buildSectionHeader('Delivery Details', Icons.local_shipping),
                  _buildDeliverySection(),
                  const SizedBox(height: 20),

                  // Payment Section
                  _buildSectionHeader('Payment', Icons.payments),
                  _buildPaymentSection(),
                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // Title row
          Row(
            children: [
              const Icon(Icons.edit, color: Color(0xFF3B82F6), size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Edit Order',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 8),
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
    );
  }

  Widget _buildProductSection() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Dropdown
            DropdownButtonFormField<String>(
              value: _selectedProductId,
              decoration: const InputDecoration(
                labelText: 'Select Product',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              isExpanded: true,
              items: productProvider.products.map((product) {
                return DropdownMenuItem(
                  value: product.id,
                  child: Text(
                    '${product.productName} - ৳${product.price.toStringAsFixed(0)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _onProductChanged,
              validator: (value) => value == null ? 'Please select a product' : null,
            ),
            const SizedBox(height: 12),

            // Quantity and Unit Price Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      errorText: _hasStockError ? 'Exceeds stock' : null,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      final qty = int.tryParse(value ?? '');
                      if (qty == null || qty < 1) {
                        return 'Enter valid quantity';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _unitPrice.toStringAsFixed(0),
                    decoration: const InputDecoration(
                      labelText: 'Unit Price',
                      border: OutlineInputBorder(),
                      prefixText: '৳ ',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _unitPrice = double.tryParse(value) ?? _unitPrice;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Stock and Total Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _hasStockError ? Icons.warning : Icons.check_circle,
                      size: 16,
                      color: _hasStockError ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Available: $_availableStock units',
                      style: TextStyle(
                        fontSize: 13,
                        color: _hasStockError ? Colors.red : Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Total: ৳${_totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      children: [
        TextFormField(
          controller: _customerNameController,
          decoration: const InputDecoration(
            labelText: 'Customer Name',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
          controller: _customerPhoneController,
          decoration: const InputDecoration(
            labelText: 'Customer Phone',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _customerAddressController,
          decoration: const InputDecoration(
            labelText: 'Customer Address',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildDeliverySection() {
    return Column(
      children: [
        TextFormField(
          controller: _recipientNameController,
          decoration: const InputDecoration(
            labelText: 'Recipient Name',
            border: OutlineInputBorder(),
            hintText: 'Person who will receive delivery',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Recipient name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _recipientPhoneController,
          decoration: const InputDecoration(
            labelText: 'Recipient Phone (Required)',
            border: OutlineInputBorder(),
            hintText: 'Exactly 11 digits',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Phone is required';
            }
            if (value.length != 11 || !RegExp(r'^\d{11}$').hasMatch(value)) {
              return 'Enter exactly 11 digits';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _recipientAddressController,
          decoration: const InputDecoration(
            labelText: 'Delivery Address (Required)',
            border: OutlineInputBorder(),
            hintText: 'Full address for courier',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Address is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        // Delivery Type
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Point', style: TextStyle(fontSize: 14)),
                value: 'point_delivery',
                groupValue: _deliveryType,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) => setState(() => _deliveryType = value!),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Home', style: TextStyle(fontSize: 14)),
                value: 'home_delivery',
                groupValue: _deliveryType,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) => setState(() => _deliveryType = value!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      children: [
        TextFormField(
          controller: _codAmountController,
          decoration: const InputDecoration(
            labelText: 'COD Amount',
            border: OutlineInputBorder(),
            prefixText: '৳ ',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'COD amount is required';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Enter valid amount';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _courierNotesController,
          decoration: const InputDecoration(
            labelText: 'Special Instructions (Optional)',
            border: OutlineInputBorder(),
            hintText: 'Delivery instructions',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFF64748B)),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Update Order',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}