import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sale.dart';
import '../services/delivery_analytics_service.dart';

class OrderDetailsModal extends StatefulWidget {
  final Sale order;

  const OrderDetailsModal({
    super.key,
    required this.order,
  });

  @override
  State<OrderDetailsModal> createState() => _OrderDetailsModalState();

  static void show(BuildContext context, Sale order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderDetailsModal(order: order),
    );
  }
}

class _OrderDetailsModalState extends State<OrderDetailsModal> {
  final DeliveryAnalyticsService _deliveryAnalytics = DeliveryAnalyticsService();
  String? _estimatedArrival;
  Map<String, dynamic>? _deliveryStats;
  bool _isLoadingEstimate = true;

  @override
  void initState() {
    super.initState();
    _loadDeliveryEstimate();
  }

  Future<void> _loadDeliveryEstimate() async {
    try {
      final deliveryAddress = _getDeliveryAddress();

      // Get analytics-based delivery estimate
      final estimatedDays = await _deliveryAnalytics.getEstimatedDeliveryDays(deliveryAddress);
      final stats = await _deliveryAnalytics.getAreaDeliveryStats(deliveryAddress);

      final estimatedDate = widget.order.saleDate.add(Duration(days: estimatedDays));

      if (mounted) {
        setState(() {
          _estimatedArrival = _formatDate(estimatedDate);
          _deliveryStats = stats;
          _isLoadingEstimate = false;
        });
      }
    } catch (e) {
      // Fallback to default estimate
      final estimatedDate = widget.order.saleDate.add(const Duration(days: 3));
      if (mounted) {
        setState(() {
          _estimatedArrival = _formatDate(estimatedDate);
          _isLoadingEstimate = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0x66000000), // rgba(0,0,0,0.4) background overlay
      ),
      child: Column(
        children: [
          // Top spacing to push modal down from top
          const SizedBox(height: 128), // Fixed height instead of percentage

          // Modal Container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _buildOrderInfo(),
                    const SizedBox(height: 24),
                    _buildOrderTimeline(),
                    const SizedBox(height: 24),
                    _buildCustomerOrderSection(),
                    const SizedBox(height: 24),
                    _buildItemsOrderedSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Order Detail',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            height: 1.4, // 28px line height
            letterSpacing: -0.2,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const SizedBox(
            width: 24,
            height: 24,
            child: Icon(
              Icons.close,
              size: 20,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderInfo() {
    return Column(
      children: [
        // Parcel ID Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Parcel ID Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parcel ID',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8C8C8C),
                    height: 1.43, // 20px line height
                    letterSpacing: -0.28,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      widget.order.consignmentId != null && widget.order.consignmentId!.isNotEmpty
                        ? '#${widget.order.consignmentId}'
                        : '#${widget.order.id.substring(0, 8).toUpperCase()}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.33, // 24px line height
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _copyToClipboard(
                        widget.order.consignmentId != null && widget.order.consignmentId!.isNotEmpty
                          ? widget.order.consignmentId!
                          : widget.order.id
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.copy,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              ),
            ),

            // Action Buttons
            Row(
              children: [
                _buildActionButton(Icons.local_shipping, () {}),
                const SizedBox(width: 12),
                _buildActionButton(Icons.file_upload, () {}),
              ],
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Status and Details Section
        _buildDetailsSection(),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Icon(
          icon,
          size: 20,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        _buildDetailItem(
          'Delivery Status',
          _getDeliveryStatus(),
          _getDeliveryStatusColor(),
        ),
        _buildUpdatedSection(),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, Color textColor, {Color? backgroundColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF8C8C8C),
            height: 1.43, // 20px line height
            letterSpacing: -0.28,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor ?? const Color(0xFFE6ECFE),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
              height: 1.5, // 18px line height
              letterSpacing: -0.12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdatedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Updated',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF8C8C8C),
            height: 1.43, // 20px line height
            letterSpacing: -0.28,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatDate(widget.order.saleDate),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.43, // 20px line height
                  letterSpacing: -0.14,
                ),
              ),
              Text(
                ' · ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.43,
                ),
              ),
              Text(
                _formatTime(widget.order.saleDate),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.43, // 20px line height
                  letterSpacing: -0.14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerOrderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CUSTOMER & ORDER',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 1.25, // 20px line height
              letterSpacing: -0.16,
            ),
          ),
          const SizedBox(height: 24),
          _buildCustomerProfile(),
          const SizedBox(height: 20),
          _buildActionButtons(),
          const SizedBox(height: 20),
          _buildOrderDetails(),
        ],
      ),
    );
  }

  Widget _buildCustomerProfile() {
    return Row(
      children: [
        // Avatar
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.person,
            color: Colors.grey,
            size: 30,
          ),
        ),
        const SizedBox(width: 12),
        // Customer Info
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.order.customerName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                height: 1.43, // 20px line height
                letterSpacing: -0.28,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.order.customerPhone ?? '${widget.order.customerName.toLowerCase().replaceAll(' ', '.')}@gmail.com',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8C8C8C),
                height: 1.43, // 20px line height
                letterSpacing: -0.14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Call Button
        Expanded(
          child: GestureDetector(
            onTap: () => _makePhoneCall(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF0F0F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.phone,
                    size: 20,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Call',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      height: 1.43, // 20px line height
                      letterSpacing: -0.28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Message Button
        Expanded(
          child: GestureDetector(
            onTap: () => _sendMessage(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF003DF6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.message,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Message',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.43, // 20px line height
                      letterSpacing: -0.28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetails() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOrderDetailItem('Purchase Date', _formatDate(widget.order.saleDate)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOrderDetailItem('Estimated Arrival', _getEstimatedArrival()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInvoiceIdItem(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOrderDetailItem('Delivery Address', _getDeliveryAddress()),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF8C8C8C),
            height: 1.43, // 20px line height
            letterSpacing: -0.28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            height: 1.43, // 20px line height
            letterSpacing: -0.28,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceIdItem() {
    final invoiceId = 'RCN-${widget.order.id.substring(0, 4).toUpperCase()}-${DateTime.now().year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Invoice ID',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF8C8C8C),
            height: 1.43, // 20px line height
            letterSpacing: -0.28,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              invoiceId,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                height: 1.43, // 20px line height
                letterSpacing: -0.28,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _copyToClipboard(invoiceId),
              child: const Icon(
                Icons.copy,
                size: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsOrderedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ITEMS ORDERED',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            height: 1.25, // 20px line height
            letterSpacing: -0.16,
          ),
        ),
        const SizedBox(height: 16),
        _buildItemsTable(),
        const SizedBox(height: 16),
        _buildPaymentSummary(),
      ],
    );
  }

  Widget _buildItemsTable() {
    // Dynamic product data from the actual order
    final products = [
      {
        'name': widget.order.productName,
        'quantity': widget.order.quantity,
        'price': widget.order.unitPrice,
        'total': widget.order.totalAmount,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5F5F5)),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Product Name',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      height: 1.43, // 20px line height
                      letterSpacing: -0.28,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Quantity',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      height: 1.43, // 20px line height
                      letterSpacing: -0.28,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Price',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      height: 1.43, // 20px line height
                      letterSpacing: -0.28,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Total',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      height: 1.43, // 20px line height
                      letterSpacing: -0.28,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table Rows
          ...products.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            final isLast = index == products.length - 1;

            return Container(
              height: 52, // Fixed height as shown in Figma
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: isLast ? const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ) : BorderRadius.zero,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Container(
                          width: 38.222, // Exact size from Figma
                          height: 38.222,
                          decoration: BoxDecoration(
                            color: const Color(0x0D000000), // rgba(0,0,0,0.05)
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.inventory_2,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            product['name'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                              height: 1.5, // 18px line height
                              letterSpacing: -0.12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'x${product['quantity']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        height: 1.5, // 18px line height
                        letterSpacing: -0.12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${_getCurrencySymbol()}${(product['price'] as double).toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        height: 1.5, // 18px line height
                        letterSpacing: -0.12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${_getCurrencySymbol()}${(product['total'] as double).toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        height: 1.5, // 18px line height
                        letterSpacing: -0.12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    final subtotal = widget.order.totalAmount; // Dynamic values from actual order
    final discount = widget.order.discount ?? 0.0;
    final totalPayment = subtotal - discount;

    return Column(
      children: [
        _buildSummaryRow('Subtotal', '${_getCurrencySymbol()}${subtotal.toStringAsFixed(2)}'),
        if (discount > 0) _buildSummaryRow('Discount', '-${_getCurrencySymbol()}${discount.toStringAsFixed(2)}'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Payment',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.5, // 18px line height
                  letterSpacing: -0.12,
                ),
              ),
              Text(
                '${_getCurrencySymbol()}${totalPayment.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.5, // 18px line height
                  letterSpacing: -0.12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 1.5, // 18px line height
              letterSpacing: -0.12,
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.black,
              height: 1.5, // 18px line height
              letterSpacing: -0.12,
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
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Progress',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
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
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            color: step['isCompleted'] || step['isActive']
                                ? const Color(0xFF1E293B)
                                : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step['description'],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (step['timestamp'] != null)
                          Text(
                            step['timestamp'],
                            style: GoogleFonts.plusJakartaSans(
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
          }),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getOrderSteps() {
    final currentStatus = widget.order.status == 'cancelled'
        ? 'cancelled'
        : widget.order.status == 'in_review'
          ? 'pending'
          : (widget.order.courierStatus ?? 'unknown');

    final steps = [
      {
        'title': 'Order Placed',
        'description': 'Order has been received and is being processed',
        'isCompleted': true,
        'isActive': false,
        'timestamp': _formatDateTime(widget.order.saleDate),
      },
      {
        'title': 'Order Confirmed',
        'description': 'Order details have been verified',
        'isCompleted': widget.order.status != 'pending',
        'isActive': widget.order.status == 'pending',
        'timestamp': widget.order.status != 'pending' ? _formatDateTime(widget.order.saleDate) : null,
      },
      {
        'title': 'Sent to Courier',
        'description': 'Order has been dispatched to courier service',
        'isCompleted': widget.order.consignmentId != null && widget.order.consignmentId!.isNotEmpty,
        'isActive': widget.order.status == 'in_review' && (widget.order.consignmentId == null || widget.order.consignmentId!.isEmpty),
        'timestamp': widget.order.consignmentId != null && widget.order.consignmentId!.isNotEmpty
            ? 'Tracking ID: ${widget.order.consignmentId}' : null,
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

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Helper Methods
  String _getDeliveryStatus() {
    switch (widget.order.courierStatus?.toLowerCase()) {
      case 'delivered':
        return 'Delivered';
      case 'in_transit':
        return 'In Transit';
      case 'pending':
        return 'Pending';
      default:
        return 'Shipping';
    }
  }

  Color _getDeliveryStatusColor() {
    switch (widget.order.courierStatus?.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF53C31B);
      case 'in_transit':
        return const Color(0xFFFF8C00);
      case 'pending':
        return const Color(0xFFFF424F);
      default:
        return const Color(0xFF003DF6);
    }
  }

  String _getPaymentStatus() {
    switch (widget.order.paymentStatus?.toLowerCase()) {
      case 'paid':
      case 'completed':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'failed':
      case 'cancelled':
        return 'Failed';
      case 'refunded':
        return 'Refunded';
      default:
        return widget.order.saleType == 'online_cod' ? 'COD Pending' : 'Pending';
    }
  }

  Color _getPaymentStatusColor() {
    switch (widget.order.paymentStatus?.toLowerCase()) {
      case 'paid':
      case 'completed':
        return const Color(0xFF53C31B);
      case 'pending':
        return const Color(0xFF003DF6);
      case 'failed':
      case 'cancelled':
        return const Color(0xFFFF424F);
      case 'refunded':
        return const Color(0xFFFF8C00);
      default:
        return widget.order.saleType == 'online_cod' ? const Color(0xFF003DF6) : const Color(0xFF8C8C8C);
    }
  }

  Color _getPaymentStatusBackgroundColor() {
    switch (widget.order.paymentStatus?.toLowerCase()) {
      case 'paid':
      case 'completed':
        return const Color(0xFFEEF9E8);
      case 'pending':
        return const Color(0xFFE6ECFE);
      case 'failed':
      case 'cancelled':
        return const Color(0xFFFFE6E6);
      case 'refunded':
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFE6ECFE);
    }
  }

  String _getCurrencySymbol() {
    // Return appropriate currency symbol based on app configuration
    // Using Bangladeshi Taka symbol
    return '৳';
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getEstimatedArrival() {
    if (_isLoadingEstimate) {
      return 'Calculating...';
    }

    if (_estimatedArrival != null) {
      final confidence = _deliveryStats?['confidence'] ?? 'low';
      final totalDeliveries = _deliveryStats?['totalDeliveries'] ?? 0;

      String confidenceText = '';
      switch (confidence) {
        case 'high':
          confidenceText = ' (High confidence - $totalDeliveries deliveries)';
          break;
        case 'medium':
          confidenceText = ' (Medium confidence - $totalDeliveries deliveries)';
          break;
        case 'low':
          confidenceText = totalDeliveries > 0
              ? ' (Low confidence - $totalDeliveries deliveries)'
              : ' (Estimated)';
          break;
      }

      return '$_estimatedArrival$confidenceText';
    }

    // Fallback
    final estimatedDate = widget.order.saleDate.add(const Duration(days: 3));
    return '${_formatDate(estimatedDate)} (Default estimate)';
  }

  String _getDeliveryAddress() {
    return widget.order.recipientAddress ??
           widget.order.customerAddress ??
           '${widget.order.customerName}, Delivery Address Not Available';
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> _makePhoneCall() async {
    final phoneNumber = widget.order.customerPhone ?? widget.order.recipientPhone;
    if (phoneNumber == null || phoneNumber.isEmpty) return;

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      // Handle error silently in modal context
    }
  }

  Future<void> _sendMessage() async {
    final phoneNumber = widget.order.customerPhone ?? widget.order.recipientPhone;
    if (phoneNumber == null || phoneNumber.isEmpty) return;

    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    } catch (e) {
      // Handle error silently in modal context
    }
  }
}