import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Auth {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Check if user has completed profile
  Future<bool> hasCompletedProfile(String userId) async {
    try {
      final providerDoc = await _firestore
          .collection('service_providers')
          .where('userId', isEqualTo: userId)
          .get();

      return providerDoc.docs.isNotEmpty;
    } catch (e) {
      print('Error checking profile: $e');
      return false;
    }
  }

  // Updated Google Sign In with profile check
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final gUser = await GoogleSignIn().signIn();
      final gAuth = await gUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth?.accessToken,
        idToken: gAuth?.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Sign in with email and password with profile check
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential;
    } catch (e) {
      print('Error signing in with email: $e');
      return null;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'No user logged in';

      // Reauthenticate user first
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(newPassword);
    } catch (e) {
      throw 'Failed to change password: ${e.toString()}';
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw 'Failed to send password reset email: ${e.toString()}';
    }
  }
}
