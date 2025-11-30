import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../models/user_profile_model.dart';

class FirestoreUserProfileRepository implements UserProfileRepository {
  FirestoreUserProfileRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users');

  @override
  Future<void> createProfile(UserProfile profile) {
    final data = UserProfileModel(
      uid: profile.uid,
      email: profile.email,
      name: profile.name,
      age: profile.age,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
      gender: profile.gender,
      avatarBase64: profile.avatarBase64,
      theme: profile.theme,
      language: profile.language,
      createdAt: profile.createdAt ?? DateTime.now(),
      updatedAt: profile.updatedAt ?? DateTime.now(),
    ).toMap();

    return _collection.doc(profile.uid).set(data);
  }

  @override
  Future<UserProfile?> fetchProfile(String uid) async {
    final snapshot = await _collection.doc(uid).get();
    if (!snapshot.exists) return null;
    final data = snapshot.data();
    if (data == null) return null;
    return UserProfileModel.fromMap({...data, 'uid': uid});
  }

  @override
  Future<void> updateProfile(UserProfile profile) {
    final data = UserProfileModel(
      uid: profile.uid,
      email: profile.email,
      name: profile.name,
      age: profile.age,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
      gender: profile.gender,
      avatarBase64: profile.avatarBase64,
      theme: profile.theme,
      language: profile.language,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt ?? DateTime.now(),
    ).toMap();

    final avatarIsNull = profile.avatarBase64 == null;
    data.removeWhere((key, value) => value == null);
    if (avatarIsNull) {
      data['avatarBase64'] = FieldValue.delete();
    }
    return _collection.doc(profile.uid).update(data);
  }
}

