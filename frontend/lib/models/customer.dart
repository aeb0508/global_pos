class Customer {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? customerType;
  final String? taxId;
  final String? notes;
  final String? status;
  final double? discountPercent;
  final String? tags;
  final String? birthday;
  final String? preferredContact;
  final double? creditLimit;

  Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.customerType,
    this.taxId,
    this.notes,
    this.status,
    this.discountPercent,
    this.tags,
    this.birthday,
    this.preferredContact,
    this.creditLimit,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'].toString(),
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      customerType: json['customer_type'],
      taxId: json['tax_id'],
      notes: json['notes'],
      status: json['status'],
      discountPercent: json['discount_percent'] != null ? double.tryParse(json['discount_percent'].toString()) : null,
      tags: json['tags'],
      birthday: json['birthday'],
      preferredContact: json['preferred_contact'],
      creditLimit: json['credit_limit'] != null ? double.tryParse(json['credit_limit'].toString()) : null,
    );
  }
}
