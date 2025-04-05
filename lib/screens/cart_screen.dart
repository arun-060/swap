import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../providers/cart_provider.dart';
import '../providers/language_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;
  String? _selectedPaymentMethod;
  String? _deliveryAddress;
  String? _fixedAddress;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final supabaseClient = supabase.Supabase.instance.client;
      final userId = supabaseClient.auth.currentUser?.id;
      
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to proceed')),
        );
        return;
      }

      final response = await supabaseClient
          .from('user_profiles')
          .select('fixed_address, delivery_address')
          .eq('user_id', userId)
          .single();

      setState(() {
        _fixedAddress = response['fixed_address'];
        _deliveryAddress = response['delivery_address'];
      });
    } catch (e) {
      print('Error loading addresses: $e');
    }
  }

  Future<void> _proceedToPayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    if (_deliveryAddress == null && _fixedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set up your delivery address')),
      );
      Navigator.pushNamed(context, '/location');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabaseClient = supabase.Supabase.instance.client;
      final userId = supabaseClient.auth.currentUser?.id;
      
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to proceed')),
        );
        return;
      }

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final items = cartProvider.items;
      final total = cartProvider.totalAmount;

      // Create order
      final orderResponse = await supabaseClient
          .from('orders')
          .insert({
            'user_id': userId,
            'total_amount': total,
            'payment_method': _selectedPaymentMethod,
            'delivery_address': _deliveryAddress ?? _fixedAddress,
            'status': 'pending',
          })
          .select()
          .single();

      // Add order items
      for (final item in items) {
        await supabaseClient
            .from('order_items')
            .insert({
              'order_id': orderResponse['id'],
              'product_id': item.id,
              'quantity': item.quantity,
              'price': item.price,
            });
      }

      // Clear cart
      cartProvider.clearCart();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/order-confirmation',
          arguments: orderResponse['id'],
          (route) => false,
        );
      }
    } catch (e) {
      print('Error processing payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error processing payment')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final items = cartProvider.items;
    final total = cartProvider.totalAmount;

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getTranslatedText('cart')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        languageProvider.getTranslatedText('empty_cart'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child:
                            Text(languageProvider.getTranslatedText('continue_shopping')),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(item.name),
                              subtitle: Text('₹${item.price.toStringAsFixed(2)}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      if (item.quantity > 1) {
                                        cartProvider.decrementQuantity(item.id);
                                      } else {
                                        cartProvider.removeFromCart(item.id);
                                      }
                                    },
                                  ),
                                  Text(item.quantity.toString()),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => cartProvider.incrementQuantity(item.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (items.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹${total.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedPaymentMethod,
                              decoration: const InputDecoration(
                                labelText: 'Payment Method',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'cash',
                                  child: Text('Cash on Delivery'),
                                ),
                                DropdownMenuItem(
                                  value: 'upi',
                                  child: Text('UPI'),
                                ),
                                DropdownMenuItem(
                                  value: 'card',
                                  child: Text('Credit/Debit Card'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedPaymentMethod = value);
                              },
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _proceedToPayment,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                ),
                                child: const Text('Proceed to Pay'),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
} 