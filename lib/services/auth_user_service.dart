import 'package:cloud_firestore/cloud_firestore.dart';

class AuthUserService {
  AuthUserService._();

  static final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection('users');

  static Future<void> createUserDoc({
    required String uid,
    required String fullName,
    required String email,
    required String phoneNumber,
    String? address,
  }) async {
    // NOTE: ServerTimestamp requires importing cloud_firestore; it is safe here.
    final now = FieldValue.serverTimestamp();

    await _users.doc(uid).set({
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address ?? '',
      'createdAt': now,
      'updatedAt': now,
    });
  }

  static Future<Map<String, dynamic>?> fetchUserDoc(
      {required String uid}) async {
    final snapshot = await _users.doc(uid).get();
    if (!snapshot.exists) return null;
    return snapshot.data();
  }

  static Future<void> updateUserDoc({
    required String uid,
    required String fullName,
    required String email,
    required String phoneNumber,
  }) async {
    final now = FieldValue.serverTimestamp();

    await _users.doc(uid).update({
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'updatedAt': now,
    });
  }
}
