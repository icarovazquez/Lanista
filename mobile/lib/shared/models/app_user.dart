import 'user_role.dart';

class AppUser {
  final String id;
  final String email;
  final UserRole role;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final String language;
  final bool isActive;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.language = 'en',
    this.isActive = true,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      role: UserRole.fromString(json['role'] as String),
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      language: json['language'] as String? ?? 'en',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role.name,
      'first_name': firstName,
      'last_name': lastName,
      'avatar_url': avatarUrl,
      'language': language,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? language,
    bool? isActive,
  }) {
    return AppUser(
      id: id,
      email: email,
      role: role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      language: language ?? this.language,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
