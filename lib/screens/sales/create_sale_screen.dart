import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/onesignal_config.dart';
import '../../services/onesignal_service.dart';
import 'package:provider/provider.dart';

import '../../providers/product_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/stock_provider.dart';

class CreateSaleScreen extends StatefulWidget {
  const CreateSaleScreen({super.key});

  @override
  State<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends State<CreateSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _notesController = TextEditingController();
  
  // COD field
  final _codAmountController = TextEditingController();

  String? _selectedProductId;
  String? _selectedLocationId;
  String _saleType = 'offline'; // 'online_cod' or 'offline'
  String _deliveryType = 'home_delivery'; // 'point_delivery' or 'home_delivery'

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
    _notesController.dispose();
    // COD controller
    _codAmountController.dispose();
    super.dispose();
  }

  void _onProductChanged(String? productId) {
    setState(() {
      _selectedProductId = productId;
      _selectedLocationId = null; // Reset location when product changes
      _unitPriceController.clear();
    });

    if (productId != null) {
      final product = context
          .read<ProductProvider>()
          .products
          .firstWhere((p) => p.id == productId);
      _unitPriceController.text = product.price.toString();
      _updateCodAmount();
    }
  }

  void _updateCodAmount() {
    if (_saleType == 'online_cod' && 
        _unitPriceController.text.isNotEmpty && 
        _quantityController.text.isNotEmpty) {
      try {
        final unitPrice = double.parse(_unitPriceController.text);
        final quantity = int.parse(_quantityController.text);
        final totalAmount = unitPrice * quantity;
        _codAmountController.text = totalAmount.toStringAsFixed(2);
      } catch (e) {
        // Invalid input, keep COD amount empty
      }
    }
  }

  void _onSaleTypeChanged(String? value) {
    setState(() {
      _saleType = value!;
      if (_saleType == 'online_cod') {
        // Auto-update COD amount
        _updateCodAmount();
      }
    });
  }

  void _submitSale() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null || _selectedLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select product and location')),
      );
      return;
    }

    final salesProvider = context.read<SalesProvider>();
    final success = await salesProvider.createSale(
      productId: _selectedProductId!,
      locationId: _selectedLocationId!,
      quantity: int.parse(_quantityController.text),
      unitPrice: double.parse(_unitPriceController.text),
      saleType: _saleType,
      customerName: _customerNameController.text,
      customerPhone: _customerPhoneController.text.isEmpty
          ? null
          : _customerPhoneController.text,
      customerAddress: _customerAddressController.text.isEmpty
          ? null
          : _customerAddressController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      // Courier fields (only used for online_cod) - use customer details as recipient
      deliveryType: _saleType == 'online_cod' ? _deliveryType : null,
      recipientName: _saleType == 'online_cod' ? _customerNameController.text : null,
      recipientPhone: _saleType == 'online_cod' ? _customerPhoneController.text : null,
      recipientAddress: _saleType == 'online_cod' ? _customerAddressController.text : null,
      codAmount: _saleType == 'online_cod' && _codAmountController.text.isNotEmpty
          ? double.parse(_codAmountController.text) : null,
      courierNotes: _saleType == 'online_cod' && _notesController.text.isNotEmpty
          ? _notesController.text : null,
    );

    if (!mounted) return;

    if (success) {
      // Get the necessary data for the notification
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
        title: '💰 নতুন বিক্রয় সংরক্ষণ করা হয়েছে',
        message:
            '$quantity units of $productName sold to $customerName for ৳${totalAmount.toStringAsFixed(2)}',
      );

      // Refresh stock data
      final stockProvider = context.read<StockProvider>();
      await stockProvider.fetchStocks();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sale created successfully! Redirecting to orders...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Clear form
      _formKey.currentState!.reset();
      _customerNameController.clear();
      _customerPhoneController.clear();
      _customerAddressController.clear();
      _quantityController.clear();
      _unitPriceController.clear();
      _notesController.clear();
      // Clear courier fields
      _codAmountController.clear();
      setState(() {
        _selectedProductId = null;
        _selectedLocationId = null;
        _saleType = 'offline';
        _deliveryType = 'home_delivery';
      });

      // Redirect to order management screen after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/orders');
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(salesProvider.errorMessage ?? 'Failed to create sale'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Sale'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer3<ProductProvider, StockProvider, SalesProvider>(
        builder: (context, productProvider, stockProvider, salesProvider, _) {
          if (productProvider.isLoading || stockProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (productProvider.errorMessage != null) {
            return Center(
              child: Text('Error: ${productProvider.errorMessage}'),
            );
          }

          final availableStocks = stockProvider.stocks
              .where((stock) =>
                  _selectedProductId == null ||
                  stock.productId == _selectedProductId)
              .where((stock) => stock.quantity > 0)
              .toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Sale Type Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sale Type',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Offline Sale'),
                                  value: 'offline',
                                  groupValue: _saleType,
                                  onChanged: _onSaleTypeChanged,
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Online COD'),
                                  value: 'online_cod',
                                  groupValue: _saleType,
                                  onChanged: _onSaleTypeChanged,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Product Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Product Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Select Product',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedProductId,
                            items: productProvider.products.map((product) {
                              return DropdownMenuItem(
                                value: product.id,
                                child: Text(
                                    '${product.productName} - ৳${product.price}'),
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
                          const SizedBox(height: 16),
                          if (_selectedProductId != null) ...[
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Select Location',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedLocationId,
                              items: availableStocks.map((stock) {
                                final location = stockProvider.locations
                                    .firstWhere(
                                        (loc) => loc.id == stock.locationId);
                                return DropdownMenuItem(
                                  value: stock.locationId,
                                  child: Text(
                                      '${location.locationName} (Available: ${stock.quantity})'),
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
                            const SizedBox(height: 16),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _quantityController,
                                  decoration: const InputDecoration(
                                    labelText: 'Quantity',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => _updateCodAmount(),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter quantity';
                                    }
                                    final quantity = int.tryParse(value);
                                    if (quantity == null || quantity <= 0) {
                                      return 'Please enter valid quantity';
                                    }
                                    if (_selectedLocationId != null) {
                                      final stock = availableStocks.firstWhere(
                                          (s) =>
                                              s.locationId ==
                                              _selectedLocationId);
                                      if (quantity > stock.quantity) {
                                        return 'Not enough stock (Available: ${stock.quantity})';
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
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter unit price';
                                    }
                                    final price = double.tryParse(value);
                                    if (price == null || price <= 0) {
                                      return 'Please enter valid price';
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

                  // Customer Details (merged with courier details for online COD)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _saleType == 'online_cod' ? 'Customer & Delivery Details' : 'Customer Details',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _customerNameController,
                            decoration: InputDecoration(
                              labelText: _saleType == 'online_cod' ? 'Customer/Recipient Name' : 'Customer Name',
                              border: const OutlineInputBorder(),
                              hintText: _saleType == 'online_cod' ? 'Person who will receive the delivery' : null,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter customer name';
                              }
                              if (_saleType == 'online_cod' && value.length > 100) {
                                return 'Name must be less than 100 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _customerPhoneController,
                            decoration: InputDecoration(
                              labelText: _saleType == 'online_cod' ? 'Phone Number (Required for delivery)' : 'Customer Phone (Optional)',
                              border: const OutlineInputBorder(),
                              hintText: _saleType == 'online_cod' ? 'Exactly 11 digits for courier service' : null,
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (_saleType == 'online_cod') {
                                if (value == null || value.isEmpty) {
                                  return 'Phone number is required for online COD';
                                }
                                if (value.length != 11 || !RegExp(r'^\d{11}$').hasMatch(value)) {
                                  return 'Please enter exactly 11 digits';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _customerAddressController,
                            decoration: InputDecoration(
                              labelText: _saleType == 'online_cod' ? 'Delivery Address (Required)' : 'Customer Address (Optional)',
                              border: const OutlineInputBorder(),
                              hintText: _saleType == 'online_cod' ? 'Full address for courier delivery' : null,
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (_saleType == 'online_cod') {
                                if (value == null || value.isEmpty) {
                                  return 'Delivery address is required for online COD';
                                }
                                if (value.length > 250) {
                                  return 'Address must be less than 250 characters';
                                }
                              }
                              return null;
                            },
                          ),
                          
                          // Delivery Type Selection (only for Online COD)
                          if (_saleType == 'online_cod') ...[
                            const SizedBox(height: 20),
                            const Text(
                              'Delivery Type',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Point Delivery'),
                                    subtitle: const Text('Collection Point'),
                                    value: 'point_delivery',
                                    groupValue: _deliveryType,
                                    onChanged: (value) {
                                      setState(() {
                                        _deliveryType = value!;
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Home Delivery'),
                                    subtitle: const Text('Door to Door'),
                                    value: 'home_delivery',
                                    groupValue: _deliveryType,
                                    onChanged: (value) {
                                      setState(() {
                                        _deliveryType = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              labelText: _saleType == 'online_cod' ? 'Special Instructions (Optional)' : 'Notes (Optional)',
                              border: const OutlineInputBorder(),
                              hintText: _saleType == 'online_cod' ? 'Any special delivery instructions' : null,
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // COD Amount (only for Online COD)
                  if (_saleType == 'online_cod') ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // COD Amount
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _codAmountController,
                                    decoration: const InputDecoration(
                                      labelText: 'COD Amount',
                                      border: OutlineInputBorder(),
                                      prefixText: '৳ ',
                                      hintText: 'Auto-calculated from total',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (_saleType == 'online_cod') {
                                        if (value == null || value.isEmpty) {
                                          return 'COD amount is required';
                                        }
                                        final amount = double.tryParse(value);
                                        if (amount == null || amount < 0) {
                                          return 'Enter valid amount';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _updateCodAmount();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('COD amount updated from total'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Auto'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[600],
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Info card
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                border: Border.all(color: Colors.blue[200]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, 
                                       color: Colors.blue[700], size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'This order will be automatically submitted to Steadfast courier service.',
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontSize: 12,
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
                  ],

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: salesProvider.isLoading ? null : _submitSale,
                      // onPressed: () async {
                      //   bool success = await sendTestNotification();
                      //   final message = success
                      //       ? 'Notification sent!'
                      //       : 'Failed to send notification';
                      //   ScaffoldMessenger.of(context).showSnackBar(
                      //     SnackBar(content: Text(message)),
                      //   );
                      // },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: salesProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Create Sale',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
