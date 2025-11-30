class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.emailVerified,
    this.displayName,
    this.photoUrl,
    this.createdAt,
    this.lastLoginAt,
  });

  final String uid;
  final String email;
  final bool emailVerified;
  final String? displayName;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  AppUser copyWith({
    bool? emailVerified,
    String? displayName,
    String? photoUrl,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      emailVerified: emailVerified ?? this.emailVerified,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

