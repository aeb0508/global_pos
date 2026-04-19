class PaymentSplit {
  final String method;
  final double amount;

  PaymentSplit({
    required this.method,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'amount': amount,
    };
  }

  factory PaymentSplit.fromJson(Map<String, dynamic> json) {
    return PaymentSplit(
      method: json['method'],
      amount: double.parse(json['amount'].toString()),
    );
  }
}

class MultiPayment {
  final List<PaymentSplit> splits;
  final double total;

  MultiPayment({
    required this.splits,
    required this.total,
  });

  double get totalPaid {
    return splits.fold(0.0, (sum, split) => sum + split.amount);
  }

  double get remaining {
    return total - totalPaid;
  }

  bool get isComplete {
    return totalPaid >= total;
  }

  Map<String, dynamic> toJson() {
    return {
      'splits': splits.map((s) => s.toJson()).toList(),
      'total': total,
    };
  }
}
