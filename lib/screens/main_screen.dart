import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/cart_provider.dart';
import '../providers/language_provider.dart';
import '../models/cart_item.dart';
import 'product_detail_screen.dart';
import 'category_products_screen.dart';
import '../widgets/product_card.dart';
import '../widgets/loading_indicator.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategory;
  int _currentIndex = 0;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _loadCategories();
    _loadProducts();
  }

  Future<void> _checkAuthState() async {
    final supabaseClient = supabase.Supabase.instance.client;
    final user = supabaseClient.auth.currentUser;
    setState(() {
      _isAuthenticated = user != null;
    });

    // Listen to auth state changes
    supabaseClient.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      setState(() {
        _isAuthenticated = session != null;
      });
    });
  }

  Future<void> _loadCategories() async {
    try {
      final supabaseClient = supabase.Supabase.instance.client;
      
      // Debug: Print all tables
      print('Checking database connection...');
      
      final categoriesResponse = await supabaseClient
          .from('categories')
          .select('*');
      print('Categories response: $categoriesResponse');
      
      final productsResponse = await supabaseClient
          .from('products')
          .select('*');
      print('Products response: $productsResponse');
      
      final response = await supabaseClient
          .from('categories')
          .select('id, name')
          .order('name');
      
      setState(() {
        _categories = List<Map<String, dynamic>>.from(response);
      });
      print('Loaded categories: $_categories');
    } catch (e, stackTrace) {
      print('Error loading categories: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadProducts() async {
    try {
      setState(() => _isLoading = true);
      
      final supabaseClient = supabase.Supabase.instance.client;
      print('Loading products...');
      
      var query = supabaseClient
          .from('products')
          .select('''
            id,
            name,
            description,
            image_url,
            original_price,
            category_id,
            barcode,
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
          ''');

      if (_selectedCategory != null) {
        query = query.eq('category_id', _selectedCategory as Object);
      }

      if (_searchController.text.isNotEmpty) {
        query = query.or('name.ilike.%${_searchController.text}%,description.ilike.%${_searchController.text}%,barcode.eq.${_searchController.text}');
      }

      final response = await query.order('name');
      print('Products response: $response');
      
      if (mounted) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error loading products: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _shareProduct(Map<String, dynamic> product) async {
    final referralCode = await _getReferralCode();
    final message = '''
Check out this amazing product on SWAP!

${product['name']}
Price: ₹${product['original_price']}
${product['description']}

Use my referral code: $referralCode to get 100 coins!
Download SWAP now: https://yourapp.com/download
''';
    
    // Share to all available platforms
    await Share.share(
      message,
      subject: 'Check out this product on SWAP!',
      sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
    );
  }

  Future<String> _getReferralCode() async {
    try {
      final supabaseClient = supabase.Supabase.instance.client;
      final user = supabaseClient.auth.currentUser;
      if (user != null) {
        final response = await supabaseClient
            .from('user_profiles')
            .select('referral_code')
            .eq('user_id', user.id)
            .single();
        return response['referral_code'] ?? '';
      }
    } catch (e) {
      debugPrint('Error getting referral code: $e');
    }
    return '';
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final storePrices = List<Map<String, dynamic>>.from(product['store_products'] ?? []);
    final lowestPrice = storePrices.isEmpty
        ? product['original_price']
        : storePrices
            .map((sp) => sp['price'] as num)
            .reduce((a, b) => a < b ? a : b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/product',
            arguments: {'id': product['id']},
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: product['image_url'] ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(
                            Icons.error_outline,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${lowestPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          if (!_isAuthenticated) {
                            Navigator.pushNamed(context, '/login');
                            return;
                          }
                          final cartProvider = Provider.of<CartProvider>(context, listen: false);
                          cartProvider.addToCart(CartItem(
                            id: product['id'],
                            name: product['name'],
                            imageUrl: product['image_url'],
                            price: lowestPrice.toDouble(),
                            quantity: 1,
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product['name']} added to cart'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            const Text(
              'SWAP',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF8C00),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const SwapLoadingIndicator(size: 80)
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFF8C00).withOpacity(0.1),
              const Color(0xFFFFB347).withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: languageProvider.getTranslatedText('search_products'),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) => _loadProducts(),
                ),
              ),

              // Categories
              if (_categories.isNotEmpty)
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(languageProvider.getTranslatedText('all')),
                            selected: _selectedCategory == null,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = null;
                              });
                              _loadProducts();
                            },
                          ),
                        );
                      }

                      final category = _categories[index - 1];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category['name']),
                          selected: _selectedCategory == category['id'],
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? category['id'] : null;
                            });
                            _loadProducts();
                          },
                        ),
                      );
                    },
                  ),
                ),

              // Products Grid
              Expanded(
                child: _products.isEmpty
                    ? Center(
                        child: Text(
                          languageProvider.getTranslatedText('no_products_found'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) => _buildProductCard(_products[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              Navigator.pushNamed(context, '/scanner');
              break;
            case 2:
              Navigator.pushNamed(context, '/cart');
              break;
            case 3:
              Navigator.pushNamed(context, '/rewards');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: Icon(
              Icons.home,
              color: Theme.of(context).primaryColor,
            ),
            label: languageProvider.getTranslatedText('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.qr_code_scanner_outlined),
            activeIcon: Icon(
              Icons.qr_code_scanner,
              color: Theme.of(context).primaryColor,
            ),
            label: languageProvider.getTranslatedText('scan'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(
              Icons.shopping_cart,
              color: Theme.of(context).primaryColor,
            ),
            label: languageProvider.getTranslatedText('cart'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.card_giftcard_outlined),
            activeIcon: Icon(
              Icons.card_giftcard,
              color: Theme.of(context).primaryColor,
            ),
            label: languageProvider.getTranslatedText('rewards'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 