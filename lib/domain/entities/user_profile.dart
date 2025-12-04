class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    this.age,
    this.heightCm,
    this.weightKg,
    this.gender,
    this.avatarBase64,
    this.theme,
    this.language,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final String name;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final String? gender;
  final String? avatarBase64;
  final String? theme;
  final String? language;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile copyWith({
    String? name,
    int? age,
    bool overrideAge = false,
    double? heightCm,
    bool overrideHeight = false,
    double? weightKg,
    bool overrideWeight = false,
    String? gender,
    bool overrideGender = false,
    String? avatarBase64,
    bool avatarBase64Set = false,
    String? theme,
    String? language,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      name: name ?? this.name,
      age: overrideAge ? age : (age ?? this.age),
      heightCm: overrideHeight ? heightCm : (heightCm ?? this.heightCm),
      weightKg: overrideWeight ? weightKg : (weightKg ?? this.weightKg),
      gender: overrideGender ? gender : (gender ?? this.gender),
      avatarBase64:
          avatarBase64Set ? avatarBase64 : (avatarBase64 ?? this.avatarBase64),
      theme: theme ?? this.theme,
      language: language ?? this.language,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

