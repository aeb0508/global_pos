class Order {
  final String? id;
  final String? orderNumber;
  final String? customerId;
  final String userId;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;
  final List<OrderItem> items;
  List<Map<String, dynamic>>? payments; // for split payments

  Order({
    this.id,
    this.orderNumber,
    this.customerId,
    required this.userId,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.items,
    this.payments,
  });

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'user_id': userId,
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'payment_method': paymentMethod,
      'items': items.map((item) => item.toJson()).toList(),
      if (payments != null && payments!.isNotEmpty) 'payments': payments,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString(),
      orderNumber: json['order_number'],
      customerId: json['customer_id']?.toString(),
      userId: json['user_id'].toString(),
      subtotal: double.parse(json['subtotal'].toString()),
      discount: double.parse((json['discount'] ?? 0).toString()),
      tax: double.parse((json['tax'] ?? 0).toString()),
      total: double.parse(json['total'].toString()),
      paymentMethod: json['payment_method'] ?? 'cash',
      items: [],
    );
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }
}
