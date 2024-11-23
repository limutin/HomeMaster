import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> createAdminUser({
  required String email,
  required String password,
  required String name,
}) async {
  try {
    // 1. Create auth user
    final UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Create admin document in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
      'uid': userCredential.user!.uid,
      'email': email,
      'name': name,
      'role': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
    });

    print('Admin user created successfully');
  } catch (e) {
    print('Error creating admin user: $e');
    rethrow;
  }
  await createAdminUser(
    email: 'homemaster@gmail.com',
    password: 'nextstep2024',
    name: 'NextStep',
  );
}
