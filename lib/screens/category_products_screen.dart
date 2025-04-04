import 'package:flutter/material.dart';

class CategoryProductsScreen extends StatelessWidget {
  const CategoryProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Products'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 10, // This will be replaced with actual data
        itemBuilder: (context, index) {
          return Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Expanded(
                  child: Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image, size: 40),
                    ),
                  ),
                ),
                
                // Product Details
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Product Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '₹0.00',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/product');
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 36),
                        ),
                        child: const Text('View Details'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 