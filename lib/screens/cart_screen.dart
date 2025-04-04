import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/language_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final cart = cartProvider.items;

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getTranslatedText('cart')),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              if (cart.items.isEmpty) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear Cart'),
                      content: const Text('Are you sure you want to clear the cart?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            cart.clear();
                            Navigator.of(ctx).pop();
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: cart.isEmpty
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
                    languageProvider.getTranslatedText('cart_empty'),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    child: const Text('Start Shopping'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.length,
                    itemBuilder: (ctx, i) {
                      final item = cart.values.toList()[i];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: Image.network(
                            item.imageUrl,
                            width: 50,
                            height: 50,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error);
                            },
                          ),
                          title: Text(item.name),
                          subtitle: Text(
                            '${languageProvider.getTranslatedText('total')}: \$${(item.price * item.quantity).toStringAsFixed(2)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  if (item.quantity > 1) {
                                    cartProvider.updateQuantity(
                                        item.id, item.quantity - 1);
                                  } else {
                                    cartProvider.removeItem(item.id);
                                  }
                                },
                              ),
                              Text('${item.quantity}'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  cartProvider.updateQuantity(
                                      item.id, item.quantity + 1);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  cartProvider.removeItem(item.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${languageProvider.getTranslatedText('total')}: ',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '\$${cartProvider.totalAmount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: cartProvider.itemCount > 0
                              ? () {
                                  // Implement checkout logic
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(languageProvider
                                          .getTranslatedText('checkout')),
                                    ),
                                  );
                                }
                              : null,
                          child: Text(
                              languageProvider.getTranslatedText('checkout')),
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