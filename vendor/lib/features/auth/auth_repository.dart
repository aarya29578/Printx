import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_user_service.dart';

class AuthRepository {
  AuthRepository._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  static Future<UserCredential> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<void> logout() => _auth.signOut();

  static Future<void> createUserDocument({
    required String uid,
    required String fullName,
    required String email,
    required String phoneNumber,
    String? address,
  }) {
    return AuthUserService.createUserDoc(
      uid: uid,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      address: address,
    );
  }

  static Future<Map<String, dynamic>?> fetchUserDocument(
      {required String uid}) {
    return AuthUserService.fetchUserDoc(uid: uid);
  }
}
