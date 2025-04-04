import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/language_provider.dart';
import '../services/product_service.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  Product? _product;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final productId = ModalRoute.of(context)!.settings.arguments as String;
      final productData = await _productService.getProductById(productId);
      
      if (productData != null) {
        setState(() {
          _product = Product.fromJson(productData as Map<String, dynamic>);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Product not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getTranslatedText('product_details')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _product == null
                  ? Center(child: Text(languageProvider.getTranslatedText('product_not_found')))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: _product!.imageUrl,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.error),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Product Name
                          Text(
                            _product!.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Price Range
                          Text(
                            '\$${_product!.minPrice.toStringAsFixed(2)}${_product!.maxPrice > _product!.minPrice ? ' - \$${_product!.maxPrice.toStringAsFixed(2)}' : ''}',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Description
                          Text(
                            _product!.description,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          
                          // Store Prices
                          const Text(
                            'Available at:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _product!.prices.length,
                            itemBuilder: (context, index) {
                              final price = _product!.prices[index];
                              return Card(
                                child: ListTile(
                                  title: Text(price.size),
                                  subtitle: Text('Size: ${price.size}'),
                                  trailing: Text(
                                    '\$${price.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_product!.prices.isNotEmpty) {
                                      cart.addItem(
                                        _product!.id,
                                        _product!.name,
                                        _product!.prices[0].price,
                                        _product!.imageUrl,
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(languageProvider.getTranslatedText('added_to_cart')),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(languageProvider.getTranslatedText('add_to_cart')),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Implement buy now functionality
                                    if (_product!.prices.isNotEmpty) {
                                      cart.addItem(
                                        _product!.id,
                                        _product!.name,
                                        _product!.prices[0].price,
                                        _product!.imageUrl,
                                      );
                                      Navigator.pushNamed(context, '/cart');
                                    }
                                  },
                                  child: Text(languageProvider.getTranslatedText('buy_now')),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Share Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Share.share(
                                  'Check out ${_product!.name} - Available from \$${_product!.minPrice.toStringAsFixed(2)}',
                                );
                              },
                              icon: const Icon(Icons.share),
                              label: Text(languageProvider.getTranslatedText('share')),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
} 