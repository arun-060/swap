import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../providers/language_provider.dart';
import '../services/product_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../widgets/loading_indicator.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  Map<String, dynamic>? product;
  List<Map<String, dynamic>> storeProducts = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    try {
      setState(() => isLoading = true);
      
      final supabaseClient = supabase.Supabase.instance.client;
      final response = await supabaseClient
          .from('products')
          .select('''
            *,
            categories (
              id,
              name
            ),
            store_products (
              id,
              price,
              is_available,
              shops (
                id,
                name,
                address,
                rating
              )
            )
          ''')
          .eq('id', widget.productId)
          .single();

      if (mounted) {
        setState(() {
          product = response;
          storeProducts = List<Map<String, dynamic>>.from(response['store_products'] ?? []);
          isLoading = false;
          errorMessage = null;
        });
      }
    } catch (e) {
      print('Error loading product details: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Product not found';
        });
      }
    }
  }

  Future<void> _shareProduct() async {
    if (product == null) return;

    try {
      final supabaseClient = supabase.Supabase.instance.client;
      final user = supabaseClient.auth.currentUser;
      String referralCode = '';

      if (user != null) {
        final response = await supabaseClient
            .from('user_profiles')
            .select('referral_code')
            .eq('user_id', user.id)
            .single();
        referralCode = response['referral_code'] ?? '';
      }

      final message = '''
Check out this amazing product on SWAP!

${product!['name']}
Price: ₹${product!['original_price']}
${product!['description']}

${referralCode.isNotEmpty ? 'Use my referral code: $referralCode to get 100 coins!\n' : ''}
Download SWAP now: https://yourapp.com/download
''';
      
      // Share to all available platforms
      await Share.share(
        message,
        subject: 'Check out this product on SWAP!',
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error sharing product')),
        );
      }
    }
  }

  Future<void> _addToCart() async {
    if (product == null) return;

    try {
      // Get the user's fixed location
      final supabaseClient = supabase.Supabase.instance.client;
      final userId = supabaseClient.auth.currentUser?.id;
      
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to add items to cart')),
        );
        return;
      }

      final locationResponse = await supabaseClient
          .from('user_profiles')
          .select('fixed_address, delivery_address')
          .eq('user_id', userId)
          .single();

      final fixedAddress = locationResponse['fixed_address'];
      final deliveryAddress = locationResponse['delivery_address'];

      if (fixedAddress == null && deliveryAddress == null) {
        // Navigate to location screen if no address is set
        Navigator.pushNamed(context, '/location');
        return;
      }

      // Calculate lowest price from available stores
      final lowestPrice = storeProducts.isEmpty
          ? product!['original_price']
          : storeProducts
              .map((sp) => sp['price'] as num)
              .reduce((a, b) => a < b ? a : b);

      // Add to cart
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.addToCart(CartItem(
        id: product!['id'],
        name: product!['name'],
        imageUrl: product!['image_url'],
        price: lowestPrice.toDouble(),
        quantity: 1,
      ));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product!['name']} added to cart'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adding item to cart')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product?['name'] ?? 'Product Details'),
        actions: [
          if (product != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareProduct,
            ),
        ],
      ),
      body: isLoading
          ? const SwapLoadingIndicator(size: 80)
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product!['image_url'] != null)
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: CachedNetworkImage(
                            imageUrl: product!['image_url'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(Icons.error_outline),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product!['name'] ?? '',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${product!['original_price'].toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (product!['description'] != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                product!['description'],
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                            const SizedBox(height: 24),
                            Text(
                              'Available at Stores',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            if (storeProducts.isEmpty)
                              const Text('Not available in any stores')
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: storeProducts.length,
                                itemBuilder: (context, index) {
                                  final storeProduct = storeProducts[index];
                                  final shop = storeProduct['shops'];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      title: Text(shop['name']),
                                      subtitle: Text(shop['address']),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${storeProduct['price'].toStringAsFixed(2)}',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: Theme.of(context).primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          if (storeProduct['is_available'] == true)
                                            const Text(
                                              'In Stock',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 12,
                                              ),
                                            )
                                          else
                                            const Text(
                                              'Out of Stock',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lowest Price',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '₹${storeProducts.isEmpty ? product!['original_price'].toStringAsFixed(2) : storeProducts.map((sp) => sp['price'] as num).reduce((a, b) => a < b ? a : b).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Add to Cart'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 