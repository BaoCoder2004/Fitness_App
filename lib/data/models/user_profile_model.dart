import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.uid,
    required super.email,
    required super.name,
    super.age,
    super.heightCm,
    super.weightKg,
    super.gender,
    super.avatarBase64,
    super.theme,
    super.language,
    super.createdAt,
    super.updatedAt,
  });

  factory UserProfileModel.fromMap(Map<String, dynamic> data) {
    return UserProfileModel(
      uid: data['uid'] as String,
      email: data['email'] as String,
      name: data['name'] as String? ?? '',
      age: data['age'] as int?,
      heightCm: (data['heightCm'] as num?)?.toDouble(),
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      gender: data['gender'] as String?,
      avatarBase64: data['avatarBase64'] as String?,
      theme: data['theme'] as String?,
      language: data['language'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'gender': gender,
      'avatarBase64': avatarBase64,
      'theme': theme,
      'language': language,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

