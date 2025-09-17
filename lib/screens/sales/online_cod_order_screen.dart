import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/onesignal_config.dart';
import '../../services/onesignal_service.dart';
import '../../providers/product_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/stock_provider.dart';

class OnlineCodOrderScreen extends StatefulWidget {
  const OnlineCodOrderScreen({super.key});

  @override
  State<OnlineCodOrderScreen> createState() => _OnlineCodOrderScreenState();
}

class _OnlineCodOrderScreenState extends State<OnlineCodOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal Details Controllers
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();

  // Order Details Controllers
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _codAmountController = TextEditingController();
  final _specialInstructionsController = TextEditingController();

  String? _selectedProductId;
  String? _selectedLocationId;
  String _deliveryType = 'home_delivery';
  String _orderStatus = 'pending';
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      context.read<StockProvider>().fetchStocks();
      context.read<StockProvider>().fetchLocations();
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _customerAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _codAmountController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  void _onProductChanged(String? productId) {
    setState(() {
      _selectedProductId = productId;
      _selectedLocationId = null;
      _unitPriceController.clear();
      _codAmountController.clear();
      _totalAmount = 0.0;
    });

    if (productId != null) {
      final product = context
          .read<ProductProvider>()
          .products
          .firstWhere((p) => p.id == productId);
      _unitPriceController.text = product.price.toString();
      _calculateTotal();
    }
  }

  void _calculateTotal() {
    if (_unitPriceController.text.isNotEmpty &&
        _quantityController.text.isNotEmpty) {
      final unitPrice = double.tryParse(_unitPriceController.text);
      final quantity = int.tryParse(_quantityController.text);

      if (unitPrice != null && quantity != null && unitPrice > 0 && quantity > 0) {
        _totalAmount = unitPrice * quantity;
        _codAmountController.text = _totalAmount.toStringAsFixed(2);
        setState(() {});
      } else {
        _totalAmount = 0.0;
        _codAmountController.clear();
        setState(() {});
      }
    }
  }

  void _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null || _selectedLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('অনুগ্রহ করে পণ্য এবং অবস্থান নির্বাচন করুন'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text);
    final unitPrice = double.tryParse(_unitPriceController.text);

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অবৈধ পরিমাণ প্রবেশ করা হয়েছে'), backgroundColor: Colors.red),
      );
      return;
    }

    if (unitPrice == null || unitPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অবৈধ একক দাম প্রবেশ করা হয়েছে'), backgroundColor: Colors.red),
      );
      return;
    }

    final salesProvider = context.read<SalesProvider>();
    final success = await salesProvider.createSale(
      productId: _selectedProductId!,
      locationId: _selectedLocationId!,
      quantity: quantity,
      unitPrice: unitPrice,
      saleType: 'online_cod',
      customerName: _customerNameController.text,
      customerPhone: _customerPhoneController.text,
      customerAddress: _customerAddressController.text,
      notes: _specialInstructionsController.text.isEmpty ? null : _specialInstructionsController.text,
      deliveryType: _deliveryType,
      recipientName: _customerNameController.text,
      recipientPhone: _customerPhoneController.text,
      recipientAddress: _customerAddressController.text,
      codAmount: double.tryParse(_codAmountController.text) ?? 0.0,
      courierNotes: _specialInstructionsController.text.isEmpty ? null : _specialInstructionsController.text,
    );

    if (!mounted) return;

    if (success) {
      final quantity = int.tryParse(_quantityController.text) ?? 0;
      final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
      final totalAmount = quantity * unitPrice;
      final customerName = _customerNameController.text;
      final customerPhone = _customerPhoneController.text;
      final product = context
          .read<ProductProvider>()
          .products
          .firstWhere((p) => p.id == _selectedProductId);
      final productName = product.productName;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎉 অর্ডার সফলভাবে তৈরি হয়েছে!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      _clearForm();

      if (mounted) {
        try {
          context.go('/orders');
        } catch (e) {
          print('Navigation failed: $e');
        }
      }

      sendOneSignalNotificationToAllUsers(
        appId: OneSignalConfig.appId,
        restApiKey: OneSignalConfig.restApiKey,
        title: '🚚 নতুন অনলাইন COD অর্ডার',
        message: '$quantity units of $productName ordered by $customerName for ৳${totalAmount.toStringAsFixed(2)} (COD)',
      );

      final stockProvider = context.read<StockProvider>();
      stockProvider.fetchStocks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(salesProvider.errorMessage ?? 'অর্ডার তৈরি করতে ব্যর্থ'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearForm() {
    _formKey.currentState!.reset();
    _customerNameController.clear();
    _customerPhoneController.clear();
    _customerEmailController.clear();
    _customerAddressController.clear();
    _cityController.clear();
    _stateController.clear();
    _zipCodeController.clear();
    _quantityController.clear();
    _unitPriceController.clear();
    _codAmountController.clear();
    _specialInstructionsController.clear();
    setState(() {
      _selectedProductId = null;
      _selectedLocationId = null;
      _deliveryType = 'home_delivery';
      _orderStatus = 'pending';
      _totalAmount = 0.0;
    });
  }

  void _cancelForm() {
    context.go('/orders');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer3<ProductProvider, StockProvider, SalesProvider>(
        builder: (context, productProvider, stockProvider, salesProvider, _) {
          if (productProvider.isLoading || stockProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (productProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'ত্রুটি: ${productProvider.errorMessage}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Tiro Bangla'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      productProvider.fetchProducts();
                      stockProvider.fetchStocks();
                      stockProvider.fetchLocations();
                    },
                    child: const Text('পুনরায় চেষ্টা করুন', style: TextStyle(fontFamily: 'Tiro Bangla')),
                  ),
                ],
              ),
            );
          }

          final availableStocks = stockProvider.stocks
              .where((stock) =>
                  _selectedProductId == null ||
                  stock.productId == _selectedProductId)
              .where((stock) => stock.quantity > 0)
              .toList();

          return Form(
            key: _formKey,
            child: Column(
              children: [
                // Navigation Bar
                Container(
                  height: 96,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2763FF),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Logo
                          Row(
                            children: [
                              const Text(
                                'ফার্নিট্র্যাক',
                                style: TextStyle(
                                  fontFamily: 'Tiro Bangla',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Color(0xFF2763FF),
                                  size: 12,
                                ),
                              ),
                            ],
                          ),
                          // Menu Icon
                          IconButton(
                            onPressed: () => context.go('/'),
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Header Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'নতুন অর্ডার যোগ করুন',
                        style: TextStyle(
                          fontFamily: 'Tiro Bangla',
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF03050A),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'অর্ডার',
                            style: TextStyle(
                              fontFamily: 'Tiro Bangla',
                              fontSize: 14,
                              color: Color(0xFF03050A),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Color(0xFF03050A),
                          ),
                          const SizedBox(width: 2),
                          const Text(
                            'নতুন অর্ডার যোগ করুন',
                            style: TextStyle(
                              fontFamily: 'Tiro Bangla',
                              fontSize: 14,
                              color: Color(0xFF7B7B7B),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Form Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Personal Details Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer Information',
                            style: TextStyle(
                              fontFamily: 'Tiro Bangla',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF03050A),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Name Field
                          _buildInputField(
                            label: 'নাম',
                            controller: _customerNameController,
                            placeholder: 'কাস্টমারের নাম',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'গ্রাহকের নাম প্রয়োজন';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Phone Number Field
                          _buildInputField(
                            label: 'ফোন নম্বর',
                            controller: _customerPhoneController,
                            placeholder: '',
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'ফোন নম্বর প্রয়োজন';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Address Field (3 rows)
                          _buildInputField(
                            label: 'Address',
                            controller: _customerAddressController,
                            placeholder: '',
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'ঠিকানা প্রয়োজন';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Order Details Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'অর্ডারের বিবরণ',
                            style: TextStyle(
                              fontFamily: 'Tiro Bangla',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF03050A),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Item Selection Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildProductDropdownField(
                                  label: 'পণ্য',
                                  value: _selectedProductId,
                                  placeholder: 'পণ্য সিলেক্ট করুন',
                                  products: productProvider.products,
                                  onChanged: _onProductChanged,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2763FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),

                          if (_selectedProductId != null) ...[
                            const SizedBox(height: 16),
                            _buildLocationDropdownField(
                              label: 'অবস্থান',
                              value: _selectedLocationId,
                              placeholder: 'অবস্থান নির্বাচন করুন',
                              availableStocks: availableStocks,
                              stockProvider: stockProvider,
                              onChanged: (value) {
                                setState(() {
                                  _selectedLocationId = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    label: 'পরিমাণ',
                                    controller: _quantityController,
                                    placeholder: '১',
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    onChanged: (_) => _calculateTotal(),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'পরিমাণ প্রবেশ করুন';
                                      }
                                      final quantity = int.tryParse(value);
                                      if (quantity == null || quantity <= 0) {
                                        return 'অবৈধ পরিমাণ';
                                      }
                                      if (_selectedLocationId != null) {
                                        final stock = availableStocks.firstWhere(
                                            (s) => s.locationId == _selectedLocationId);
                                        if (quantity > stock.quantity) {
                                          return 'Max: ${stock.quantity}';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildInputField(
                                    label: 'একক দাম',
                                    controller: _unitPriceController,
                                    placeholder: '৳ ০.০০',
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                                    ],
                                    onChanged: (_) => _calculateTotal(),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'দাম প্রবেশ করুন';
                                      }
                                      final price = double.tryParse(value);
                                      if (price == null || price <= 0) {
                                        return 'অবৈধ দাম';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Delivery Details Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Delivery Details',
                            style: TextStyle(
                              fontFamily: 'Tiro Bangla',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF03050A),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Delivery Type Selection
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Delivery Type',
                                style: TextStyle(
                                  fontFamily: 'Tiro Bangla',
                                  fontSize: 14,
                                  color: Color(0xFFA1A1A1),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFDFDFDF)),
                                ),
                                child: Column(
                                  children: [
                                    _buildDeliveryTypeOption(
                                      value: 'home_delivery',
                                      groupValue: _deliveryType,
                                      title: 'Home Delivery',
                                      subtitle: 'Door-to-door delivery',
                                      icon: Icons.home,
                                      onChanged: (value) {
                                        setState(() {
                                          _deliveryType = value!;
                                        });
                                      },
                                      isFirst: true,
                                    ),
                                    const Divider(height: 1, color: Color(0xFFDFDFDF)),
                                    _buildDeliveryTypeOption(
                                      value: 'point_delivery',
                                      groupValue: _deliveryType,
                                      title: 'Point Delivery',
                                      subtitle: 'Collection point pickup',
                                      icon: Icons.location_city,
                                      onChanged: (value) {
                                        setState(() {
                                          _deliveryType = value!;
                                        });
                                      },
                                      isFirst: false,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                        ],
                      ),

                      const SizedBox(height: 24),

                      // Payment Summary Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'পেমেন্ট সারাংশ',
                            style: TextStyle(
                              fontFamily: 'Tiro Bangla',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF03050A),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // COD Amount Field with Auto Calculate Button
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  label: 'COD পরিমাণ',
                                  controller: _codAmountController,
                                  placeholder: '৳ ০.০০',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'COD পরিমাণ প্রয়োজন';
                                    }
                                    final amount = double.tryParse(value);
                                    if (amount == null || amount < 0) {
                                      return 'সঠিক পরিমাণ প্রবেশ করুন';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2763FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    _calculateTotal();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('মোট থেকে পরিমাণ গণনা করা হয়েছে'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.calculate,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Total Amount Display
                          if (_totalAmount > 0) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF2763FF).withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'মোট পরিমাণ:',
                                    style: TextStyle(
                                      fontFamily: 'Tiro Bangla',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2763FF),
                                    ),
                                  ),
                                  Text(
                                    '৳ ${_totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontFamily: 'Open Sans',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2763FF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                        ],
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0xFFEDEDED), width: 1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Cancel Button
                            OutlinedButton(
                              onPressed: _cancelForm,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFEDEDED)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: const Text(
                                'বাতিল',
                                style: TextStyle(
                                  fontFamily: 'Tiro Bangla',
                                  fontSize: 16,
                                  color: Color(0xFF03050A),
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Add Button
                            ElevatedButton(
                              onPressed: salesProvider.isLoading ? null : _submitOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2763FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: salesProvider.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'যোগ করুন',
                                      style: TextStyle(
                                        fontFamily: 'Tiro Bangla',
                                        fontSize: 16,
                                        color: Colors.white,
                                        height: 1.5,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? placeholder,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Tiro Bangla',
            fontSize: 14,
            color: Color(0xFFA1A1A1),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDFDFDF)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            onChanged: onChanged,
            maxLines: maxLines ?? 1,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 16,
                color: Color(0xFF03050A),
                height: 1.5,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 16,
              color: Color(0xFF03050A),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    String? value,
    String? placeholder,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Tiro Bangla',
            fontSize: 14,
            color: Color(0xFFA1A1A1),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDFDFDF)),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 16,
                color: Color(0xFF03050A),
                height: 1.5,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF03050A),
              size: 24,
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 16,
                    color: Color(0xFF03050A),
                    height: 1.5,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildProductDropdownField({
    required String label,
    String? value,
    String? placeholder,
    required List products,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Tiro Bangla',
            fontSize: 14,
            color: Color(0xFFA1A1A1),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDFDFDF)),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 16,
                color: Color(0xFF03050A),
                height: 1.5,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF03050A),
              size: 24,
            ),
            items: products.map((product) {
              return DropdownMenuItem<String>(
                value: product.id,
                child: Text(
                  '${product.productName} - ৳${product.price}',
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 16,
                    color: Color(0xFF03050A),
                    height: 1.5,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            validator: (value) {
              if (value == null) {
                return 'অনুগ্রহ করে একটি পণ্য নির্বাচন করুন';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationDropdownField({
    required String label,
    String? value,
    String? placeholder,
    required List availableStocks,
    required stockProvider,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Tiro Bangla',
            fontSize: 14,
            color: Color(0xFFA1A1A1),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDFDFDF)),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 16,
                color: Color(0xFF03050A),
                height: 1.5,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF03050A),
              size: 24,
            ),
            items: availableStocks.map((stock) {
              final location = stockProvider.locations
                  .firstWhere((loc) => loc.id == stock.locationId);
              return DropdownMenuItem<String>(
                value: stock.locationId,
                child: Text(
                  '${location.locationName} (${stock.quantity} available)',
                  style: const TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 16,
                    color: Color(0xFF03050A),
                    height: 1.5,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            validator: (value) {
              if (value == null) {
                return 'অনুগ্রহ করে একটি অবস্থান নির্বাচন করুন';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRadioButton({
    required String value,
    required String groupValue,
    required String label,
    required void Function(String?) onChanged,
  }) {
    final isSelected = value == groupValue;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF2763FF) : const Color(0xFFC8C8C8),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2763FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => onChanged(value),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 16,
              color: Color(0xFF03050A),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryTypeOption({
    required String value,
    required String groupValue,
    required String title,
    required String subtitle,
    required IconData icon,
    required void Function(String?) onChanged,
    required bool isFirst,
  }) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: !isFirst ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF2763FF) : const Color(0xFFC8C8C8),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2763FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              size: 20,
              color: const Color(0xFF2763FF),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF03050A),
                      height: 1.5,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 14,
                      color: Color(0xFF7B7B7B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}