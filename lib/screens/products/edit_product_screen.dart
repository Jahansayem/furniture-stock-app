import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../utils/app_theme.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lowStockThresholdController = TextEditingController();

  String _selectedProductType = 'chair';
  final List<String> _productTypes = [
    'chair',
    'table',
    'sofa',
    'bed',
    'cabinet',
    'shelf',
    'desk',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _productNameController.text = widget.product.productName;
    _selectedProductType = widget.product.productType;
    _descriptionController.text = widget.product.description ?? '';
    _lowStockThresholdController.text =
        widget.product.lowStockThreshold.toString();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _descriptionController.dispose();
    _lowStockThresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text('Edit Product'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/products');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Product',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Update product information',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Product Name
                Text(
                  'Product Name',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _productNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter product name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.inventory_2),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a product name';
                    }
                    if (value.trim().length < 2) {
                      return 'Product name must be at least 2 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Product Type
                Text(
                  'Product Type',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedProductType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: _productTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type[0].toUpperCase() + type.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProductType = value!;
                    });
                  },
                ),

                const SizedBox(height: 20),

                // Description
                Text(
                  'Description (Optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Enter product description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 20),

                // Low Stock Threshold
                Text(
                  'Low Stock Threshold',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _lowStockThresholdController,
                  decoration: InputDecoration(
                    hintText: 'Enter threshold number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.warning),
                    suffixText: 'units',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a threshold value';
                    }
                    final threshold = int.tryParse(value);
                    if (threshold == null || threshold < 0) {
                      return 'Please enter a valid number (0 or greater)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/products');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Consumer<ProductProvider>(
                        builder: (context, productProvider, child) {
                          return ElevatedButton(
                            onPressed: productProvider.isLoading
                                ? null
                                : () => _updateProduct(productProvider),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: productProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text('Update Product'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateProduct(ProductProvider productProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final updatedProduct = widget.product.copyWith(
      productName: _productNameController.text.trim(),
      productType: _selectedProductType,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      lowStockThreshold: int.parse(_lowStockThresholdController.text),
    );

    final success = await productProvider.updateProduct(updatedProduct);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/products');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(productProvider.errorMessage ?? 'Failed to update product'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
