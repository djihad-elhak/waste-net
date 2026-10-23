class AuthUser {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String username;
  final String? photoUrl;
  final bool isEmailVerified;
  final DateTime createdAt;

  const AuthUser({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.photoUrl,
    required this.isEmailVerified,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  String get displayName => username.isNotEmpty ? username : fullName;

  AuthUser copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? username,
    String? photoUrl,
    bool? isEmailVerified,
    DateTime? createdAt,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
