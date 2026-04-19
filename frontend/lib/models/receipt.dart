class Receipt {
  final String orderId;
  final String orderNumber;
  final DateTime date;
  final List<ReceiptItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final String paymentMethod;
  final double amountPaid;
  final double change;
  final String? customerName;
  final String cashierName;

  Receipt({
    required this.orderId,
    required this.orderNumber,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    required this.amountPaid,
    required this.change,
    this.customerName,
    required this.cashierName,
  });
}

class ReceiptItem {
  final String name;
  final int quantity;
  final double price;
  final double total;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.total,
  });
}
