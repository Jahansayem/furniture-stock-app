import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sale.dart';

class OrderDetailsModal extends StatelessWidget {
  final Sale order;

  const OrderDetailsModal({
    super.key,
    required this.order,
  });

  static void show(BuildContext context, Sale order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderDetailsModal(order: order),
    );
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
        // Order ID Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Order ID Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order ID',
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
                  '#${order.id.substring(0, 8).toUpperCase()}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.33, // 24px line height
                  ),
                ),
              ],
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
        _buildDetailItem(
          'Payment Status',
          _getPaymentStatus(),
          _getPaymentStatusColor(),
          backgroundColor: _getPaymentStatusBackgroundColor(),
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
                _formatDate(order.saleDate),
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
                _formatTime(order.saleDate),
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
              order.customerName,
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
              order.customerPhone ?? '${order.customerName.toLowerCase().replaceAll(' ', '.')}@gmail.com',
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
              child: _buildOrderDetailItem('Purchase Date', _formatDate(order.saleDate)),
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
    final invoiceId = 'RCN-${order.id.substring(0, 4).toUpperCase()}-${DateTime.now().year}';

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
        'name': order.productName,
        'quantity': order.quantity,
        'price': order.unitPrice,
        'total': order.totalAmount,
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
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    final subtotal = order.totalAmount; // Dynamic values from actual order
    final discount = order.discount ?? 0.0;
    final taxAmount = (subtotal - discount) * 0.10; // 10% tax calculation
    final totalPayment = subtotal - discount + taxAmount;

    return Column(
      children: [
        _buildSummaryRow('Subtotal', '${_getCurrencySymbol()}${subtotal.toStringAsFixed(2)}'),
        if (discount > 0) _buildSummaryRow('Discount', '-${_getCurrencySymbol()}${discount.toStringAsFixed(2)}'),
        _buildSummaryRow('Tax Amount', '${_getCurrencySymbol()}${taxAmount.toStringAsFixed(2)}'),
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

  // Helper Methods
  String _getDeliveryStatus() {
    switch (order.courierStatus?.toLowerCase()) {
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
    switch (order.courierStatus?.toLowerCase()) {
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
    switch (order.paymentStatus?.toLowerCase()) {
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
        return order.saleType == 'online_cod' ? 'COD Pending' : 'Pending';
    }
  }

  Color _getPaymentStatusColor() {
    switch (order.paymentStatus?.toLowerCase()) {
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
        return order.saleType == 'online_cod' ? const Color(0xFF003DF6) : const Color(0xFF8C8C8C);
    }
  }

  Color _getPaymentStatusBackgroundColor() {
    switch (order.paymentStatus?.toLowerCase()) {
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
    // For now, defaulting to $ but can be made configurable
    return '\$';
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
    final estimatedDate = order.saleDate.add(const Duration(days: 2));
    return _formatDate(estimatedDate);
  }

  String _getDeliveryAddress() {
    return order.recipientAddress ??
           order.customerAddress ??
           '${order.customerName}, Delivery Address Not Available';
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> _makePhoneCall() async {
    final phoneNumber = order.customerPhone ?? order.recipientPhone;
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
    final phoneNumber = order.customerPhone ?? order.recipientPhone;
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