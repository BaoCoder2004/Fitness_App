import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

/// Script để tạo tài khoản admin
/// 
/// Cách sử dụng:
/// 1. Chạy: dart run lib/admin/scripts/create_admin.dart
/// 2. Nhập email và password cho admin account
/// 3. Script sẽ tạo user trong Firebase Auth và set role = "admin" trong Firestore
Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('=== Tạo tài khoản Admin ===\n');

  // Nhập email và password
  stdout.write('Nhập email cho admin account: ');
  final email = stdin.readLineSync()?.trim();
  if (email == null || email.isEmpty) {
    print('Email không hợp lệ!');
    return;
  }

  stdout.write('Nhập password (tối thiểu 6 ký tự): ');
  final password = stdin.readLineSync()?.trim();
  if (password == null || password.length < 6) {
    print('Password phải có ít nhất 6 ký tự!');
    return;
  }

  try {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    // Kiểm tra xem user đã tồn tại chưa
    UserCredential? userCredential;
    try {
      // Thử đăng nhập trước
      userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✓ User đã tồn tại trong Firebase Auth');
    } catch (e) {
      // Nếu không tồn tại, tạo mới
      userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✓ Đã tạo user mới trong Firebase Auth');
    }

    final user = userCredential.user;
    if (user == null) {
      print('✗ Không thể lấy thông tin user!');
      return;
    }

    // Kiểm tra xem profile đã tồn tại trong Firestore chưa
    final userDoc = firestore.collection('users').doc(user.uid);
    final userSnapshot = await userDoc.get();

    if (userSnapshot.exists) {
      // Update role thành admin
      await userDoc.update({
        'role': 'admin',
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✓ Đã cập nhật user thành admin trong Firestore');
    } else {
      // Tạo profile mới với role admin
      await userDoc.set({
        'uid': user.uid,
        'email': user.email ?? email,
        'name': user.displayName ?? 'Admin',
        'role': 'admin',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✓ Đã tạo profile admin trong Firestore');
    }

    print('\n=== Thành công! ===');
    print('Email: $email');
    print('UID: ${user.uid}');
    print('Role: admin');
    print('\nBạn có thể đăng nhập vào admin panel với email và password này.');

  } catch (e) {
    print('\n✗ Lỗi: $e');
    if (e is FirebaseAuthException) {
      print('Mã lỗi: ${e.code}');
      print('Thông báo: ${e.message}');
    }
  }
}

