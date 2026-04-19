class Discount {
  final String? id;
  final String name;
  final String type; // 'percentage' or 'fixed'
  final double value;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? code;

  Discount({
    this.id,
    required this.name,
    required this.type,
    required this.value,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.code,
  });

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      id: json['id']?.toString(),
      name: json['name'],
      type: json['type'],
      value: double.parse(json['value'].toString()),
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] == 1,
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'value': value,
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      if (code != null) 'code': code,
    };
  }

  double calculateDiscount(double amount) {
    if (type == 'percentage') {
      return amount * (value / 100);
    } else {
      return value;
    }
  }

  bool isValid() {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }
}
