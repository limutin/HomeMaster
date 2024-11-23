import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> sendToAll(BuildContext context, String message) async {
    try {
      final callable = _functions.httpsCallable('sendBatchEmails');
      final result = await callable.call({
        'message': message,
      });

      await _firestore.collection('announcements').add({
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'all',
        'status': 'completed',
        'successCount': result.data['successCount'],
        'failureCount': result.data['failureCount'],
        'totalRecipients': result.data['totalRecipients'],
      });

    } catch (e) {
      print('Error in sendToAll: $e');
      rethrow;
    }
  }

  Future<void> sendToUser(BuildContext context, String email, String message) async {
    try {
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }

      final callable = _functions.httpsCallable('sendEmail');
      await callable.call({
        'toEmail': email,
        'message': message,
      });

      await _firestore.collection('announcements').add({
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'single',
        'recipient': email,
        'status': 'completed',
      });

    } catch (e) {
      print('Error in sendToUser: $e');
      rethrow;
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
