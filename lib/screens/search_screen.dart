import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_history_provider.dart';
import '../providers/language_provider.dart';
import '../services/product_service.dart';
import '../models/product.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ProductService _productService = ProductService();
  List<Product> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _productService.searchProducts(query);
      setState(() {
        _searchResults = results.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
        _isLoading = false;
      });
      
      // Add to search history
      if (query.isNotEmpty) {
        Provider.of<SearchHistoryProvider>(context, listen: false).addSearch(query);
      }
    } catch (e) {
      setState(() {
        _error = 'Error searching products: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final searchHistoryProvider = Provider.of<SearchHistoryProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getTranslatedText('search')),
        actions: [
          if (searchHistoryProvider.searchHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                searchHistoryProvider.clearHistory();
              },
              tooltip: languageProvider.getTranslatedText('clear_history'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: languageProvider.getTranslatedText('search_hint'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                _performSearch(value);
              },
            ),
          ),
          
          // Search History Section
          if (searchHistoryProvider.searchHistory.isNotEmpty && _searchResults.isEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      languageProvider.getTranslatedText('search_history'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: searchHistoryProvider.searchHistory.length,
                      itemBuilder: (context, index) {
                        final query = searchHistoryProvider.searchHistory[index];
                        return ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(query),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              searchHistoryProvider.removeSearch(query);
                            },
                          ),
                          onTap: () {
                            _searchController.text = query;
                            _performSearch(query);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          // Search Results
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(child: Text(_error!))
          else if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final product = _searchResults[index];
                  return ListTile(
                    leading: Image.network(
                      product.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image_not_supported);
                      },
                    ),
                    title: Text(product.name),
                    subtitle: Text(
                      '\$${product.minPrice.toStringAsFixed(2)}${product.maxPrice > product.minPrice ? ' - \$${product.maxPrice.toStringAsFixed(2)}' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      // Navigate to product detail
                      Navigator.pushNamed(
                        context,
                        '/product',
                        arguments: product.id,
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
} 