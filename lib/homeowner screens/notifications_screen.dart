import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser;

  NotificationsScreen({super.key});

  // Add this function to mark notifications as read
  Future<void> _markNotificationsAsRead() async {
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final notifications = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user?.uid)
        .where('read', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    // Call markNotificationsAsRead when screen is built
    _markNotificationsAsRead();

    return const Scaffold(
      // ... rest of your notifications screen code ...
    );
  }
}
