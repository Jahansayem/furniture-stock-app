import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _codAmountController = TextEditingController();
  final _specialInstructionsController = TextEditingController();

  String? _selectedProductId;
  String? _selectedLocationId;
  String _deliveryType = 'home_delivery';
  double _totalAmount = 0.0;
  
  // Track created order for Send to Steadfast
  String? _createdOrderId;
  bool _showSendToCourier = false;

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
    _customerAddressController.dispose();
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
      try {
        final unitPrice = double.parse(_unitPriceController.text);
        final quantity = int.parse(_quantityController.text);
        _totalAmount = unitPrice * quantity;
        _codAmountController.text = _totalAmount.toStringAsFixed(2);
        setState(() {});
      } catch (e) {
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
          content: Text('Please select product and location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final salesProvider = context.read<SalesProvider>();
    final success = await salesProvider.createSale(
      productId: _selectedProductId!,
      locationId: _selectedLocationId!,
      quantity: int.parse(_quantityController.text),
      unitPrice: double.parse(_unitPriceController.text),
      saleType: 'online_cod',
      customerName: _customerNameController.text,
      customerPhone: _customerPhoneController.text,
      customerAddress: _customerAddressController.text,
      notes: _specialInstructionsController.text.isEmpty ? null : _specialInstructionsController.text,
      deliveryType: _deliveryType,
      recipientName: _customerNameController.text,
      recipientPhone: _customerPhoneController.text,
      recipientAddress: _customerAddressController.text,
      codAmount: double.parse(_codAmountController.text),
      courierNotes: _specialInstructionsController.text.isEmpty ? null : _specialInstructionsController.text,
    );

    if (!mounted) return;

    if (success) {
      final quantity = int.parse(_quantityController.text);
      final unitPrice = double.parse(_unitPriceController.text);
      final totalAmount = quantity * unitPrice;
      final customerName = _customerNameController.text;
      final product = context
          .read<ProductProvider>()
          .products
          .firstWhere((p) => p.id == _selectedProductId);
      final productName = product.productName;

      await sendOneSignalNotificationToAllUsers(
        appId: OneSignalConfig.appId,
        restApiKey: OneSignalConfig.restApiKey,
        title: '🚚 নতুন অনলাইন COD অর্ডার',
        message: '$quantity units of $productName ordered by $customerName for ৳${totalAmount.toStringAsFixed(2)} (COD)',
      );

      final stockProvider = context.read<StockProvider>();
      await stockProvider.fetchStocks();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Online COD order created successfully! Status: Pending courier pickup'),
          backgroundColor: Colors.green,
        ),
      );

      _clearForm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(salesProvider.errorMessage ?? 'Failed to create COD order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearForm() {
    _formKey.currentState!.reset();
    _customerNameController.clear();
    _customerPhoneController.clear();
    _customerAddressController.clear();
    _quantityController.clear();
    _unitPriceController.clear();
    _codAmountController.clear();
    _specialInstructionsController.clear();
    setState(() {
      _selectedProductId = null;
      _selectedLocationId = null;
      _deliveryType = 'home_delivery';
      _totalAmount = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shopping_cart, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Online COD Order'),
          ],
        ),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
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
                    'Error: ${productProvider.errorMessage}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      productProvider.fetchProducts();
                      stockProvider.fetchStocks();
                      stockProvider.fetchLocations();
                    },
                    child: const Text('Retry'),
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
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Header Card
                Card(
                  color: Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange[600],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.local_shipping,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cash on Delivery Order',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Create orders for courier delivery with payment on delivery',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Product Selection Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.inventory_2, color: Colors.blue[600]),
                            const SizedBox(width: 8),
                            const Text(
                              'Product Selection',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Select Product',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.shopping_bag),
                          ),
                          value: _selectedProductId,
                          items: productProvider.products.map((product) {
                            return DropdownMenuItem(
                              value: product.id,
                              child: Text('${product.productName} - ৳${product.price}'),
                            );
                          }).toList(),
                          onChanged: _onProductChanged,
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a product';
                            }
                            return null;
                          },
                        ),
                        if (_selectedProductId != null) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Select Stock Location',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            value: _selectedLocationId,
                            items: availableStocks.map((stock) {
                              final location = stockProvider.locations
                                  .firstWhere((loc) => loc.id == stock.locationId);
                              return DropdownMenuItem(
                                value: stock.locationId,
                                child: Text('${location.locationName} (${stock.quantity} available)'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedLocationId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a location';
                              }
                              return null;
                            },
                          ),
                        ],
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
                                onChanged: (_) => _calculateTotal(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter quantity';
                                  }
                                  final quantity = int.tryParse(value);
                                  if (quantity == null || quantity <= 0) {
                                    return 'Invalid quantity';
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
                              child: TextFormField(
                                controller: _unitPriceController,
                                decoration: const InputDecoration(
                                  labelText: 'Unit Price',
                                  border: OutlineInputBorder(),
                                  prefixText: '৳ ',
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => _calculateTotal(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter price';
                                  }
                                  final price = double.tryParse(value);
                                  if (price == null || price <= 0) {
                                    return 'Invalid price';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Customer & Delivery Details Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: Colors.green[600]),
                            const SizedBox(width: 8),
                            const Text(
                              'Customer & Delivery Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _customerNameController,
                          decoration: const InputDecoration(
                            labelText: 'Customer Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                            hintText: 'Full name for delivery',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Customer name is required';
                            }
                            if (value.length > 100) {
                              return 'Name too long (max 100 characters)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _customerPhoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                            hintText: '01XXXXXXXXX (11 digits)',
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _customerAddressController,
                          decoration: const InputDecoration(
                            labelText: 'Delivery Address',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                            hintText: 'Complete address for courier delivery',
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Delivery address is required';
                            }
                            if (value.length > 250) {
                              return 'Address too long (max 250 characters)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Delivery Type Selection
                        const Text(
                          'Delivery Type',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              RadioListTile<String>(
                                title: Row(
                                  children: [
                                    Icon(Icons.home, size: 20, color: Colors.blue[600]),
                                    const SizedBox(width: 8),
                                    const Text('Home Delivery'),
                                  ],
                                ),
                                subtitle: const Text('Door-to-door delivery'),
                                value: 'home_delivery',
                                groupValue: _deliveryType,
                                onChanged: (value) {
                                  setState(() {
                                    _deliveryType = value!;
                                  });
                                },
                              ),
                              const Divider(height: 1),
                              RadioListTile<String>(
                                title: Row(
                                  children: [
                                    Icon(Icons.location_city, size: 20, color: Colors.orange[600]),
                                    const SizedBox(width: 8),
                                    const Text('Point Delivery'),
                                  ],
                                ),
                                subtitle: const Text('Collection point pickup'),
                                value: 'point_delivery',
                                groupValue: _deliveryType,
                                onChanged: (value) {
                                  setState(() {
                                    _deliveryType = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _specialInstructionsController,
                          decoration: const InputDecoration(
                            labelText: 'Special Instructions (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                            hintText: 'Any special delivery instructions',
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Payment Summary Card
                Card(
                  color: Colors.amber[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.payment, color: Colors.amber[700]),
                            const SizedBox(width: 8),
                            const Text(
                              'Payment Summary',
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
                                controller: _codAmountController,
                                decoration: const InputDecoration(
                                  labelText: 'COD Amount',
                                  border: OutlineInputBorder(),
                                  prefixText: '৳ ',
                                  prefixIcon: Icon(Icons.money),
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
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                _calculateTotal();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Amount calculated from total'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.calculate, size: 18),
                              label: const Text('Auto'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[600],
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        
                        if (_totalAmount > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[700],
                                  ),
                                ),
                                Text(
                                  '৳ ${_totalAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            border: Border.all(color: Colors.blue[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This order will be submitted to Steadfast courier service for COD delivery.',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: salesProvider.isLoading ? null : _submitOrder,
                    icon: salesProvider.isLoading
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
                      salesProvider.isLoading ? 'Creating Order...' : 'Create COD Order',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}