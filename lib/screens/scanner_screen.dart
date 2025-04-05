import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:share_plus/share_plus.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import 'package:provider/provider.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;
  bool _isLoading = false;
  Map<String, dynamic>? _scannedProduct;
  String? _error;

  Future<void> _onBarcodeDetected(String barcode) async {
    if (!_isScanning) return; // Prevent multiple scans

    setState(() {
      _isLoading = true;
      _isScanning = false; // Stop scanning after first detection
    });

    try {
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
          .eq('barcode', barcode)
          .single();

      setState(() {
        _scannedProduct = response;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Product not found';
        _isLoading = false;
        _isScanning = true; // Resume scanning if product not found
      });
    }
  }

  Future<void> _shareProduct() async {
    if (_scannedProduct == null) return;

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

${_scannedProduct!['name']}
Price: ₹${_scannedProduct!['original_price']}
${_scannedProduct!['description']}

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sharing product')),
      );
    }
  }

  void _addToCart() {
    if (_scannedProduct == null) return;

    final storePrices = List<Map<String, dynamic>>.from(_scannedProduct!['store_products'] ?? []);
    final lowestPrice = storePrices.isEmpty
        ? _scannedProduct!['original_price']
        : storePrices
            .map((sp) => sp['price'] as num)
            .reduce((a, b) => a < b ? a : b);

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addToCart(CartItem(
      id: _scannedProduct!['id'],
      name: _scannedProduct!['name'],
      imageUrl: _scannedProduct!['image_url'],
      price: lowestPrice.toDouble(),
      quantity: 1,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_scannedProduct!['name']} added to cart'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Product'),
        actions: [
          if (_scannedProduct != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareProduct,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isScanning || _scannedProduct == null)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: controller,
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty && barcodes[0].rawValue != null) {
                          _onBarcodeDetected(barcodes[0].rawValue!);
                        }
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.orange,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_scannedProduct != null)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_scannedProduct!['image_url'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Image.network(
                            _scannedProduct!['image_url'],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      _scannedProduct!['name'] ?? '',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${_scannedProduct!['original_price'].toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (_scannedProduct!['description'] != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _scannedProduct!['description'],
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addToCart,
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text('Add to Cart'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _scannedProduct = null;
                          _isScanning = true;
                        });
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan Another Product'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _isScanning = true;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
} 