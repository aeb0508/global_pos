class Supplier {
  final String? id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? contactPerson;
  final bool isActive;

  Supplier({
    this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.contactPerson,
    this.isActive = true,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id']?.toString(),
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      contactPerson: json['contact_person'],
      isActive: json['is_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'contact_person': contactPerson,
      'is_active': isActive ? 1 : 0,
    };
  }
}
