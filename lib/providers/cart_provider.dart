import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(),
      imageUrl: json['imageUrl'],
      quantity: json['quantity'],
    );
  }
}

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};
  static const String _key = 'cart_items';

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.price * item.quantity;
    });
    return total;
  }

  CartProvider() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_key);
    if (cartJson != null) {
      final cartMap = json.decode(cartJson) as Map<String, dynamic>;
      _items = cartMap.map((key, value) => MapEntry(
            key,
            CartItem.fromJson(value as Map<String, dynamic>),
          ));
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartMap = _items.map((key, value) => MapEntry(key, value.toJson()));
    await prefs.setString(_key, json.encode(cartMap));
  }

  void addItem(String productId, String name, double price, String imageUrl) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existingItem) => CartItem(
          id: existingItem.id,
          name: existingItem.name,
          price: existingItem.price,
          imageUrl: existingItem.imageUrl,
          quantity: existingItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: productId,
          name: name,
          price: price,
          imageUrl: imageUrl,
        ),
      );
    }
    _saveCart();
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (_items.containsKey(productId)) {
      if (quantity > 0) {
        _items.update(
          productId,
          (existingItem) => CartItem(
            id: existingItem.id,
            name: existingItem.name,
            price: existingItem.price,
            imageUrl: existingItem.imageUrl,
            quantity: quantity,
          ),
        );
      } else {
        _items.remove(productId);
      }
      _saveCart();
      notifyListeners();
    }
  }

  void clear() {
    _items = {};
    _saveCart();
    notifyListeners();
  }
} 