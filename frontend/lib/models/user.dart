class User {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      username: json['username'],
      email: json['email'],
      fullName: json['full_name'],
      role: json['role'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'role': role,
      'is_active': isActive ? 1 : 0,
    };
  }
}
