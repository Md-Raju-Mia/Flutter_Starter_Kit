import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthRepositoryImpl(this._firebaseAuth);

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<UserCredential> signIn(String email, String password) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> signUp(String email, String password) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> updateProfilePicture(File imageFile) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    final bytes = await imageFile.readAsBytes();
    if (bytes.lengthInBytes > 1000000) {
      throw Exception('Image too large. Please select a smaller photo.');
    }
    
    String base64Image = base64Encode(bytes);

    await _firestore.collection('users').doc(user.uid).set({
      'profilePic': base64Image,
    }, SetOptions(merge: true));
  }

  @override
  Future<String?> getProfilePicture() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['profilePic'];
  }

  @override
  Future<void> updateDisplayName(String name) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'displayName': name,
    }, SetOptions(merge: true));
    
    // Also update Firebase Auth display name for consistency
    await user.updateDisplayName(name);
  }

  @override
  Future<String?> getDisplayName() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['displayName'] ?? user.displayName;
  }
}
