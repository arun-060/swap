import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../providers/language_provider.dart';

class GroceryProductsScreen extends StatefulWidget {
  const GroceryProductsScreen({super.key});

  @override
  State<GroceryProductsScreen> createState() => _GroceryProductsScreenState();
}

class _GroceryProductsScreenState extends State<GroceryProductsScreen> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  bool isLoading = true;
  String searchQuery = '';
  String sortBy = 'name';
  String selectedCategory = 'all';

  final List<String> categories = [
    'all',
    'fruits',
    'vegetables',
    'dairy',
    'bread',
    'meat',
    'pantry',
    'snacks',
    'beverages',
    'frozen',
    'condiments'
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final supabaseClient = supabase.Supabase.instance.client;

      final response = await supabaseClient
          .from('products')
          .select()
          .eq('category_id', '550e8400-e29b-41d4-a716-446655440005')
          .order('name');

      if (mounted) {
        setState(() {
          products = List<Map<String, dynamic>>.from(response);
          filteredProducts = products;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading products: $e')),
        );
      }
    }
  }

  void _filterProducts() {
    setState(() {
      filteredProducts = products.where((product) {
        final matchesSearch = product['name']
            .toString()
            .toLowerCase()
            .contains(searchQuery.toLowerCase());
        final matchesCategory = selectedCategory == 'all' ||
            product['name'].toString().toLowerCase().contains(selectedCategory);
        return matchesSearch && matchesCategory;
      }).toList();

      switch (sortBy) {
        case 'name':
          filteredProducts.sort((a, b) => a['name'].compareTo(b['name']));
          break;
        case 'price_low':
          filteredProducts.sort((a, b) => (a['original_price'] as num)
              .compareTo(b['original_price'] as num));
          break;
        case 'price_high':
          filteredProducts.sort((a, b) => (b['original_price'] as num)
              .compareTo(a['original_price'] as num));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getTranslatedText('groceries')),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: languageProvider.getTranslatedText('search_products'),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                      _filterProducts();
                    });
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        value: sortBy,
                        items: [
                          DropdownMenuItem(
                            value: 'name',
                            child: Text(
                                languageProvider.getTranslatedText('sort_by_name')),
                          ),
                          DropdownMenuItem(
                            value: 'price_low',
                            child: Text(languageProvider
                                .getTranslatedText('sort_by_price_low')),
                          ),
                          DropdownMenuItem(
                            value: 'price_high',
                            child: Text(languageProvider
                                .getTranslatedText('sort_by_price_high')),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            sortBy = value!;
                            _filterProducts();
                          });
                        },
                      ),
                      const SizedBox(width: 16),
                      ...categories.map((category) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(category.toUpperCase()),
                              selected: selectedCategory == category,
                              onSelected: (selected) {
                                setState(() {
                                  selectedCategory = selected ? category : 'all';
                                  _filterProducts();
                                });
                              },
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Products Grid
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/product',
                                arguments: product['id'],
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Image.network(
                                    product['image_url'] ?? '',
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(Icons.error_outline),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${product['original_price']}',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                  ),
          ),
        ],
      ),
    );
  }
} 