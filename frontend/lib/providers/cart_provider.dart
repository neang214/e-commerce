import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  bool _loading = false;

  List<CartItem> get items => _items;
  bool get loading => _loading;
  int get itemCount => _items.fold(0, (s, i) => s + i.quantity);
  double get total => _items.fold(0, (s, i) => s + i.subtotal);

  Future<void> fetch() async {
    _loading = true;
    notifyListeners();
    try {
      _items = await ApiService.getCart();
    } catch (_) {
      _items = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> add(String productId, int quantity) async {
    await ApiService.addToCart(productId, quantity);
    await fetch();
  }

  Future<void> updateQty(String itemId, int quantity) async {
    await ApiService.updateCartItem(itemId, quantity);
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      _items[idx].quantity = quantity;
      notifyListeners();
    }
  }

  Future<void> remove(String itemId) async {
    await ApiService.removeCartItem(itemId);
    _items.removeWhere((i) => i.id == itemId);
    notifyListeners();
  }

  void clear() {
    _items = [];
    notifyListeners();
  }
}
