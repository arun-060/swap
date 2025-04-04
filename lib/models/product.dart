class ProductPrice {
  final String id;
  final double price;
  final String size;
  final String productId;

  ProductPrice({
    required this.id,
    required this.price,
    required this.size,
    required this.productId,
  });

  factory ProductPrice.fromJson(Map<String, dynamic> json) {
    return ProductPrice(
      id: json['id'] as String,
      price: (json['price'] as num).toDouble(),
      size: json['size'] as String,
      productId: json['product_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'price': price,
      'size': size,
      'product_id': productId,
    };
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<ProductPrice> prices;
  final String category;
  final bool isPopular;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.prices,
    required this.category,
    required this.isPopular,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String,
      prices: (json['product_prices'] as List)
          .map((price) => ProductPrice.fromJson(price))
          .toList(),
      category: json['category'] as String,
      isPopular: json['is_popular'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'product_prices': prices.map((price) => price.toJson()).toList(),
      'category': category,
      'is_popular': isPopular,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get minPrice {
    if (prices.isEmpty) return 0.0;
    return prices.map((p) => p.price).reduce((a, b) => a < b ? a : b);
  }

  double get maxPrice {
    if (prices.isEmpty) return 0.0;
    return prices.map((p) => p.price).reduce((a, b) => a > b ? a : b);
  }
}

class StorePrice {
  final String storeName;
  final String storeLocation;
  final double price;

  StorePrice({
    required this.storeName,
    required this.storeLocation,
    required this.price,
  });

  factory StorePrice.fromJson(Map<String, dynamic> json) {
    return StorePrice(
      storeName: json['store_name'] ?? '',
      storeLocation: json['store_location'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'store_name': storeName,
      'store_location': storeLocation,
      'price': price,
    };
  }
} 