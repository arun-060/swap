import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch all products with pagination
  Future<List<Product>> getProducts({
    int page = 1,
    int limit = 10,
    String? category,
  }) async {
    try {
      var query = _supabase
          .from('products')
          .select('*')
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      final response = await query;
      
      return response.map<Product>((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  // Fetch a single product by ID
  Future<Product?> getProductById(String id) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .eq('id', id)
          .single();
      
      return Product.fromJson(response);
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }

  // Search products by name or description
  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);
      
      return response.map<Product>((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .eq('category', category)
          .order('created_at', ascending: false);
      
      return response.map<Product>((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching products by category: $e');
      return [];
    }
  }

  // Get all categories
  Future<List<String>> getCategories() async {
    try {
      final response = await _supabase
          .from('products')
          .select('category')
          .order('category');
      
      final categories = response.map<String>((json) => json['category'] as String).toList();
      return categories.toSet().toList(); // Remove duplicates
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPopularProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, product_prices(*)')
          .eq('is_popular', true)
          .order('created_at', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw 'Failed to load popular products: $e';
    }
  }

  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final response = await _supabase
        .from('products')
        .select('''
          *,
          product_prices (
            *,
            stores (
              name
            )
          )
        ''')
        .eq('barcode', barcode)
        .single();
    return response;
  }

  Future<List<Map<String, dynamic>>> getProductPrices(String productId) async {
    final response = await _supabase
        .from('product_prices')
        .select('''
          *,
          stores (
            name,
            location
          )
        ''')
        .eq('product_id', productId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addProductToFavorites(String userId, String productId) async {
    await _supabase
        .from('favorites')
        .upsert({
          'user_id': userId,
          'product_id': productId,
        });
  }

  Future<void> removeProductFromFavorites(String userId, String productId) async {
    await _supabase
        .from('favorites')
        .delete()
        .match({
          'user_id': userId,
          'product_id': productId,
        });
  }

  Future<List<Map<String, dynamic>>> getFavoriteProducts(String userId) async {
    final response = await _supabase
        .from('favorites')
        .select('''
          products (
            *,
            product_prices (
              *,
              stores (
                name
              )
            )
          )
        ''')
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }
} 