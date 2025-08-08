import 'package:flutter/material.dart';
import 'package:furniture_stock_app/constants/onesignal_config.dart';
import 'package:furniture_stock_app/services/onesignal_service.dart';
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

  String? _selectedProductId;
  String? _selectedLocationId;
  String _saleType = 'offline'; // 'online_cod' or 'offline'

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
    }
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
          content: Text('Sale created successfully!'),
          backgroundColor: Colors.green,
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
      setState(() {
        _selectedProductId = null;
        _selectedLocationId = null;
        _saleType = 'offline';
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
                                  onChanged: (value) {
                                    setState(() {
                                      _saleType = value!;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Online COD'),
                                  value: 'online_cod',
                                  groupValue: _saleType,
                                  onChanged: (value) {
                                    setState(() {
                                      _saleType = value!;
                                    });
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

                  // Customer Details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _customerNameController,
                            decoration: const InputDecoration(
                              labelText: 'Customer Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter customer name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _customerPhoneController,
                            decoration: const InputDecoration(
                              labelText: 'Customer Phone (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          if (_saleType == 'online_cod') ...[
                            TextFormField(
                              controller: _customerAddressController,
                              decoration: const InputDecoration(
                                labelText: 'Delivery Address',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (_saleType == 'online_cod' &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please enter delivery address for COD orders';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Notes (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

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
