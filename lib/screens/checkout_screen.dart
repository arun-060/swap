import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/loading_indicator.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _orderId;
  String? _paymentId;
  
  late Razorpay _razorpay;
  double _totalAmount = 0;
  List<Map<String, dynamic>> _cartItems = [];
  Map<String, dynamic>? _userProfile;
  
  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    
    _loadUserProfile();
    _loadCartItems();
  }
  
  @override
  void dispose() {
    _razorpay.clear();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user != null) {
        final response = await supabase
            .from('user_profiles')
            .select('*')
            .eq('user_id', user.id)
            .single();
            
        setState(() {
          _userProfile = response;
          _nameController.text = response['full_name'] ?? '';
          _phoneController.text = response['phone_number'] ?? '';
          _addressController.text = response['address'] ?? '';
        });
            }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }
  
  void _loadCartItems() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final items = cartProvider.items;
    
    setState(() {
      _cartItems = items.map((item) => {
        'id': item.id,
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'image_url': item.imageUrl,
      }).toList();
      
      _totalAmount = items.fold(0, (sum, item) => sum + (item.price * item.quantity));
      _isLoading = false;
    });
  }
  
  void _startPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final supabase = Supabase.instance.client;
        final user = supabase.auth.currentUser;
        if (user == null) {
          throw Exception('User not authenticated');
        }

        // Save or update user profile
        await supabase
            .from('user_profiles')
            .upsert({
              'user_id': user.id,
              'full_name': _nameController.text.trim(),
              'phone_number': _phoneController.text.trim(),
              'address': _addressController.text.trim(),
              'updated_at': DateTime.now().toIso8601String(),
            });

        // Create order in database
        final orderData = {
          'user_id': user.id,
          'total_amount': _totalAmount,
          'status': 'pending',
          'shipping_address': _addressController.text.trim(),
          'phone': _phoneController.text.trim(),
          'name': _nameController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
        };

        final orderResponse = await supabase
            .from('orders')
            .insert(orderData)
            .select()
            .single();

        final orderId = orderResponse['id'] as String;
        setState(() {
          _orderId = orderId;
        });

        // Create order items
        for (var item in _cartItems) {
          await supabase.from('order_items').insert({
            'order_id': orderId,
            'product_id': item['id'],
            'quantity': item['quantity'],
            'price': item['price'],
          });
        }

        // Initialize Razorpay payment
        var options = {
          'key': 'YOUR_RAZORPAY_KEY',
          'amount': (_totalAmount * 100).toInt(), // Amount in paise
          'name': 'SWAP',
          'description': 'Order #$orderId',
          'prefill': {
            'contact': _phoneController.text.trim(),
            'name': _nameController.text.trim(),
            if (user.email != null) 'email': user.email as String,
          },
          'theme': {
            'color': '#FF8C00',
          },
        };

        setState(() {
          _isLoading = false;
          _isProcessing = true;
        });

        _razorpay.open(options);
      } catch (e) {
        setState(() {
          _isLoading = false;
          _isProcessing = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }
  
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final supabase = Supabase.instance.client;
      
      if (_orderId == null) {
        throw Exception('Order ID is null');
      }
      
      final orderId = _orderId!;
      
      // Update order status
      await supabase
          .from('orders')
          .update({
            'status': 'paid',
            'payment_id': response.paymentId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      // Clear cart
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Successful')),
        );
        Navigator.pushReplacementNamed(context, '/orders');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order: ${e.toString()}')),
        );
      }
    }
  }
  
  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
  }
  
  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet Selected: ${response.walletName}')),
    );
  }
  
  Future<List<Map<String, dynamic>>> _getProductPrices(String productId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('store_products')
          .select('''
            price,
            shop_id,
            shops:shops(name, location)
          ''')
          .eq('product_id', productId);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching product prices: $e');
      return [];
    }
  }
  
  Widget _buildStoreAvailability(List<Map<String, dynamic>> prices) {
    if (prices.isEmpty) {
      return const Text(
        'Not available in any stores',
        style: TextStyle(color: Colors.red),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available at Stores:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        ...prices.map((store) {
          final shopInfo = store['shops'] as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${shopInfo['name']} (${shopInfo['location']})',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  '₹${store['price'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getTranslatedText('checkout')),
      ),
      body: _isLoading
          ? const Center(child: SwapLoadingIndicator(size: 80))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                            _isProcessing = false;
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(languageProvider.getTranslatedText('try_again')),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              languageProvider.getTranslatedText('order_summary'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Card(
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _cartItems.length,
                                itemBuilder: (context, index) {
                                  final item = _cartItems[index];
                                  return Column(
                                    children: [
                                      ListTile(
                                        leading: item['image_url'] != null
                                            ? Image.network(
                                                item['image_url'],
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                              )
                                            : const Icon(Icons.image),
                                        title: Text(item['name']),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Qty: ${item['quantity']}'),
                                            const SizedBox(height: 4),
                                            FutureBuilder<List<Map<String, dynamic>>>(
                                              future: _getProductPrices(item['id']),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  return _buildStoreAvailability(snapshot.data!);
                                                }
                                                return const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        trailing: Text(
                                          '₹${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Divider(),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Total Amount
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      languageProvider.getTranslatedText('total'),
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    Text(
                                      '₹${_totalAmount.toStringAsFixed(2)}',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Delivery Information
                            Text(
                              languageProvider.getTranslatedText('delivery_info'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            
                            // Name
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: languageProvider.getTranslatedText('full_name'),
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return languageProvider.getTranslatedText('name_required');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Phone
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: languageProvider.getTranslatedText('phone'),
                                prefixIcon: const Icon(Icons.phone),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return languageProvider.getTranslatedText('phone_required');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Address
                            TextFormField(
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: languageProvider.getTranslatedText('delivery_address'),
                                prefixIcon: const Icon(Icons.location_on),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return languageProvider.getTranslatedText('address_required');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            // Payment Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isProcessing ? null : _startPayment,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isProcessing
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text('Processing...'),
                                        ],
                                      )
                                    : Text(languageProvider.getTranslatedText('pay_now')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isProcessing)
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        child: const Center(
                          child: SwapLoadingIndicator(size: 80),
                        ),
                      ),
                  ],
                ),
    );
  }
} 