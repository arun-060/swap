import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/product_service.dart';
import '../models/product.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  List<Product> _popularProducts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPopularProducts();
  }

  Future<void> _loadPopularProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final products = await _productService.getPopularProducts();
      setState(() {
        _popularProducts = products.map((json) => Product.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getTranslatedText('home')),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.pushNamed(context, '/scanner');
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPopularProducts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!),
                        ElevatedButton(
                          onPressed: _loadPopularProducts,
                          child: Text(
                              languageProvider.getTranslatedText('try_again')),
                        ),
                      ],
                    ),
                  )
                : _popularProducts.isEmpty
                    ? Center(
                        child: Text(
                            languageProvider.getTranslatedText('no_products')),
                      )
                    : ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              languageProvider
                                  .getTranslatedText('popular_products'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _popularProducts.length,
                            itemBuilder: (context, index) {
                              final product = _popularProducts[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/product',
                                    arguments: product.id,
                                  );
                                },
                                child: Card(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: Image.network(
                                          product.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(Icons.error);
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            if (product.prices.isNotEmpty)
                                              Text(
                                                '\$${product.minPrice.toStringAsFixed(2)}${product.maxPrice > product.minPrice ? ' - \$${product.maxPrice.toStringAsFixed(2)}' : ''}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall,
                                              ),
                                          ],
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
    );
  }
} 