import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../firebase_options.dart';

/// Script để update tất cả users hiện có thêm field role và status
/// 
/// Cách sử dụng:
/// flutter run -d windows --target=lib/admin/scripts/run_update_users_role.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('=== Cập nhật Role và Status cho Users ===\n');

  try {
    final firestore = FirebaseFirestore.instance;
    final usersRef = firestore.collection('users');

    print('Đang lấy danh sách users...');
    final snapshot = await usersRef.get();
    
    if (snapshot.docs.isEmpty) {
      print('Không có user nào trong Firestore.');
      return;
    }

    print('Tìm thấy ${snapshot.docs.length} user(s).\n');

    int updated = 0;
    int skipped = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final needsUpdate = (data['role'] == null) || (data['status'] == null);

      if (needsUpdate) {
        final updateData = <String, dynamic>{};
        
        if (data['role'] == null) {
          updateData['role'] = 'user';
          print('  - ${data['email'] ?? doc.id}: Thêm role = "user"');
        }
        
        if (data['status'] == null) {
          updateData['status'] = 'active';
          print('  - ${data['email'] ?? doc.id}: Thêm status = "active"');
        }

        if (updateData.isNotEmpty) {
          updateData['updatedAt'] = FieldValue.serverTimestamp();
          await doc.reference.update(updateData);
          updated++;
        }
      } else {
        skipped++;
        print('  - ${data['email'] ?? doc.id}: Đã có đầy đủ role và status, bỏ qua');
      }
    }

    print('\n=== Hoàn tất! ===');
    print('Đã cập nhật: $updated user(s)');
    print('Đã bỏ qua: $skipped user(s)');
    print('\nTất cả users hiện có đã có role và status.');

  } catch (e) {
    print('\n✗ Lỗi: $e');
  }
  
  // Exit app
  exit(0);
}

