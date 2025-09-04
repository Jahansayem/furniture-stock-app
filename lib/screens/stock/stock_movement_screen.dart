import 'package:flutter/material.dart';
import '../../constants/onesignal_config.dart';
import '../../services/onesignal_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../models/stock.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';

class StockMovementScreen extends StatefulWidget {
  const StockMovementScreen({super.key});

  @override
  State<StockMovementScreen> createState() => _StockMovementScreenState();
}

class _StockMovementScreenState extends State<StockMovementScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedProductId;
  String? _selectedFromLocationId;
  String? _selectedToLocationId;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    await stockProvider.fetchLocations();
    await productProvider.fetchProducts();
    await stockProvider.fetchMovements();
  }

  void _resetForm() {
    setState(() {
      _selectedProductId = null;
      _selectedFromLocationId = null;
      _selectedToLocationId = null;
      _quantityController.clear();
      _notesController.clear();
    });
  }

  // Helper methods for stock movement logic
  Stock? _getStockForLocation(String locationId) {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    if (_selectedProductId == null) return null;
    try {
      return stockProvider.stocks.firstWhere(
        (stock) =>
            stock.productId == _selectedProductId &&
            stock.locationId == locationId,
      );
    } catch (e) {
      return null;
    }
  }

  List<StockLocation> _getAvailableLocations(
      List<StockLocation> allLocations, bool isFromLocation) {
    final stockProvider = Provider.of<StockProvider>(context, listen: false);
    if (_selectedProductId == null) {
      return [];
    }

    // Filter locations based on whether they have stock for the selected product
    final locationsWithStock = stockProvider.stocks
        .where((stock) =>
            stock.productId == _selectedProductId && stock.quantity > 0)
        .map((stock) => stock.locationId)
        .toSet();

    // If it's a 'from' location, only show locations that have stock
    if (isFromLocation) {
      return allLocations
          .where((location) => locationsWithStock.contains(location.id))
          .toList();
    } else {
      // If it's a 'to' location, show all locations except the 'from' location
      return allLocations
          .where((location) => location.id != _selectedFromLocationId)
          .toList();
    }
  }

  String _getAvailableQuantityText() {
    if (_selectedProductId == null || _selectedFromLocationId == null) {
      return "(Available: 0)";
    }
    final stock = _getStockForLocation(_selectedFromLocationId!);
    return "(Available: ${stock?.quantity ?? 0})";
  }

  int _getAvailableQuantity() {
    if (_selectedProductId == null || _selectedFromLocationId == null) {
      return 0;
    }
    final stock = _getStockForLocation(_selectedFromLocationId!);
    return stock?.quantity ?? 0;
  }

  Future<void> _submitMovement() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final stockProvider = Provider.of<StockProvider>(context, listen: false);
      final success = await stockProvider.moveStock(
        productId: _selectedProductId!,
        fromLocationId: _selectedFromLocationId!,
        toLocationId: _selectedToLocationId!,
        quantity: int.parse(_quantityController.text),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (success) {
        await sendOneSignalNotificationToAllUsers(
          appId: OneSignalConfig.appId,
          restApiKey: OneSignalConfig.restApiKey,
          title: 'স্টক সফলভাবে এক জায়গায় থেকে অন্য জায়গায় নেওয়া হয়েছে',
          message:
              'প্রোডাক্ট টি সফলভাবে এক জায়গায় থেকে অন্য জায়গায় নেওয়া হয়েছে',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Stock moved successfully!")),
          );
        }
        _resetForm();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text("Failed to move stock: ${stockProvider.errorMessage}")),
          );
        }
      }
    }
  }

  Future<void> _submitProduction() async {
    // Custom validation for production (only need product and quantity)
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a product first!")),
      );
      return;
    }

    if (_quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter quantity!")),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please enter a valid positive quantity!")),
      );
      return;
    }

    // Find factory location for production
    final stockProvider = Provider.of<StockProvider>(context, listen: false);

    if (stockProvider.locations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No locations available!")),
      );
      return;
    }

    final factoryLocation = stockProvider.locations.firstWhere(
      (loc) => loc.locationType == 'factory',
      orElse: () =>
          stockProvider.locations.first, // Use first location as fallback
    );

    final success = await stockProvider.addProduction(
      productId: _selectedProductId!,
      locationId: factoryLocation.id,
      quantity: quantity,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    if (!mounted) return;

    if (success) {
      await sendOneSignalNotificationToAllUsers(
        appId: OneSignalConfig.appId,
        restApiKey: OneSignalConfig.restApiKey,
        title: 'সফলভাবে প্রোডাক্ট স্টক যুক্ত করা হয়েছে',
        message: 'কারখানায় তৈরি কৃত প্রোডাক্ট সফলভাবে স্টকে যুক্ত করা হয়েছে',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Production added successfully!")),
        );
      }
      _resetForm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Failed to add production: ${stockProvider.errorMessage}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("স্টক ইডিট"),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer2<StockProvider, ProductProvider>(
        builder: (context, stockProvider, productProvider, child) {
          if (stockProvider.isLoading || productProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (stockProvider.errorMessage != null) {
            return Center(
              child: Text("Error: ${stockProvider.errorMessage}"),
            );
          }

          if (productProvider.errorMessage != null) {
            return Center(
              child: Text("Error: ${productProvider.errorMessage}"),
            );
          }

          final products = productProvider.products;
          final locations = stockProvider.locations;

          return RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Offline data indicator
                  if (stockProvider.isShowingOfflineData)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Showing offline data",
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildMovementForm(products, locations),
                  const SizedBox(height: 24),
                  _buildRecentActivity(stockProvider.movements),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMovementForm(
      List<Product> products, List<StockLocation> locations) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'পণ্য সংখ্যা আপডেট করুন',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'প্রোডাক্ট',
              border: OutlineInputBorder(),
            ),
            value: _selectedProductId,
            items: products.map((product) {
              return DropdownMenuItem(
                value: product.id,
                child: Text(product.productName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedProductId = value;
              });
            },
            validator: (value) =>
                value == null ? 'Please select a product' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'From Location',
              border: OutlineInputBorder(),
            ),
            value: _selectedFromLocationId,
            items: _getAvailableLocations(locations, true).map((location) {
              final stock = _getStockForLocation(location.id);
              return DropdownMenuItem(
                value: location.id,
                child: Row(
                  children: [
                    Expanded(child: Text(location.locationName)),
                    Text(' (Stock: ${stock?.quantity ?? 0})'),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedFromLocationId = value;
              });
            },
            validator: (value) =>
                value == null ? 'Please select a source location' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'To Location',
              border: OutlineInputBorder(),
            ),
            value: _selectedToLocationId,
            items: _getAvailableLocations(locations, false).map((location) {
              return DropdownMenuItem(
                value: location.id,
                child: Text(location.locationName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedToLocationId = value;
              });
            },
            validator: (value) =>
                value == null ? 'Please select a destination location' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantityController,
            decoration: InputDecoration(
              labelText: 'পরিমাণ',
              border: OutlineInputBorder(),
              suffixText: _getAvailableQuantityText(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter quantity';
              }
              final quantity = int.tryParse(value);
              if (quantity == null || quantity <= 0) {
                return 'Please enter a valid positive number';
              }
              final availableQuantity = _getAvailableQuantity();
              if (quantity > availableQuantity) {
                return 'Insufficient stock (available: $availableQuantity)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // Instructions Text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'নির্দেশনা',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• স্টক ট্রান্সফার: একটি স্থান থেকে অন্য স্থানে পণ্য বা মালামাল স্থানান্তর করতে স্টক ট্র‍্যান্সফার ব্যাবহার করুন।\n'
                  '• স্টক যোগ করুন : কারখানায় নতুন তৈরি হওয়া পণ্য স্টকে যোগ করুন।',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _submitMovement,
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('স্টক ট্র্যান্সফার'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _submitProduction,
                  icon: const Icon(Icons.factory),
                  label: const Text('স্টক যুক্ত করুন'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(List<StockMovement> movements) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (movements.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No recent stock movements',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: movements.length,
            itemBuilder: (context, index) {
              final movement = movements[index];

              // Get product name instead of ID
              final productProvider =
                  Provider.of<ProductProvider>(context, listen: false);
              final product = productProvider.products.firstWhere(
                (p) => p.id == movement.productId,
                orElse: () => Product(
                  id: movement.productId,
                  productName: 'Unknown Product',
                  productType: '',
                  price: 0.0,
                  lowStockThreshold: 0,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  createdBy: '',
                ),
              );

              // Get location names instead of IDs
              final stockProvider =
                  Provider.of<StockProvider>(context, listen: false);
              String? fromLocationName;
              String? toLocationName;

              if (movement.fromLocationId != null) {
                try {
                  final fromLocation = stockProvider.locations.firstWhere(
                    (l) => l.id == movement.fromLocationId,
                  );
                  fromLocationName = fromLocation.locationName;
                } catch (e) {
                  fromLocationName = movement.fromLocationId;
                }
              }

              if (movement.toLocationId != null) {
                try {
                  final toLocation = stockProvider.locations.firstWhere(
                    (l) => l.id == movement.toLocationId,
                  );
                  toLocationName = toLocation.locationName;
                } catch (e) {
                  toLocationName = movement.toLocationId;
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${movement.movementType.toUpperCase()} - ${product.productName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Quantity: ${movement.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (fromLocationName != null && toLocationName != null)
                        Text(
                          'Moved from $fromLocationName to $toLocationName',
                          style: const TextStyle(fontSize: 14),
                        )
                      else if (toLocationName != null)
                        Text(
                          'Added to $toLocationName',
                          style: const TextStyle(fontSize: 14),
                        )
                      else if (fromLocationName != null)
                        Text(
                          'Removed from $fromLocationName',
                          style: const TextStyle(fontSize: 14),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Date: ${DateFormat("dd/MM/yyyy HH:mm").format(movement.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      if (movement.createdBy != null)
                        Text(
                          'By: ${movement.createdBy}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      if (movement.notes != null && movement.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Notes: ${movement.notes}',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
