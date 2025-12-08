import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  bool _isAdmin = false;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  bool get isAdmin => _isAdmin;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _auth.authStateChanges().listen((user) async {
      _currentUser = user;
      if (user != null) {
        await _checkAdminRole();
      } else {
        _isAdmin = false;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _checkAdminRole() async {
    if (_currentUser == null) {
      _isAdmin = false;
      return;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        _isAdmin = data?['role'] == 'admin';
      } else {
        _isAdmin = false;
      }
    } catch (e) {
      _isAdmin = false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _checkAdminRole();

      if (!_isAdmin) {
        await signOut();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    _isAdmin = false;
    notifyListeners();
  }
}

