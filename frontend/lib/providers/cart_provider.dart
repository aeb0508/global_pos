import 'package:flutter/material.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.sellingPrice * quantity;
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  double _discount = 0;
  double _taxRate = 0; // loaded from DB via AppSettingsProvider

  List<CartItem> get items => _items;
  double get discount => _discount;
  double get taxRate => _taxRate;

  double get subtotal {
    return _items.fold(0, (sum, item) => sum + item.total);
  }

  double get tax {
    return (subtotal - _discount) * _taxRate;
  }

  double get total {
    return subtotal - _discount + tax;
  }

  void setTaxRate(double rate) {
    if (_taxRate != rate) {
      _taxRate = rate;
      notifyListeners();
    }
  }

  void addProduct(Product product) {
    if (product.stockQuantity <= 0) return;

    final existingIndex =
        _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      if (_items[existingIndex].quantity + 1 > product.stockQuantity) return;
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeProduct(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final index =
        _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (quantity > 0) {
        if (quantity > _items[index].product.stockQuantity) {
          _outOfStockProductName = _items[index].product.name;
          notifyListeners();
          return;
        }
        _items[index].quantity = quantity;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  // Holds the name of the last product that hit stock limit, cleared after read.
  String? _outOfStockProductName;
  String? consumeStockLimitWarning() {
    final name = _outOfStockProductName;
    _outOfStockProductName = null;
    return name;
  }

  void setDiscount(double value) {
    _discount = value;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _discount = 0;
    notifyListeners();
  }
}
