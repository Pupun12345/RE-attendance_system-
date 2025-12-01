// lib/models/user_model.dart

class User {
  final String id;
  final String name;
  final String userId;
  final String phone;
  final String? email;
  final String role;
  final String? profileImageUrl;

  User({
    required this.id,
    required this.name,
    required this.userId,
    required this.phone,
    this.email,
    required this.role,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      name: json['name'],
      userId: json['userId'],
      phone: json['phone'],
      email: json['email'],
      role: json['role'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
}