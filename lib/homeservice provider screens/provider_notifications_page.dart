import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ProviderNotificationsPage extends StatelessWidget {
  const ProviderNotificationsPage({super.key});

  void _showDeleteDialog(BuildContext context, String notificationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Notification',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this notification?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(notificationId)
                  .delete()
                  .then((_) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              });
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'booking_accepted':
        return Icons.check_circle_outline;
      case 'booking_declined':
        return Icons.cancel_outlined;
      case 'new_booking':
        return Icons.book_online;
      default:
        return Icons.notifications;
    }
  }

  Future<String> _getNotificationMessage(Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    final serviceType = data['serviceType'] as String?;
    final homeownerId = data['homeownerId'] as String?;
    
    String homeownerName = 'Homeowner';
    if (homeownerId != null) {
      final homeownerDoc = await FirebaseFirestore.instance
          .collection('homeowners')
          .doc(homeownerId)
          .get();
      if (homeownerDoc.exists) {
        homeownerName = homeownerDoc.data()?['fullName'] ?? 'Unknown User';
      }
    }
    
    switch (type) {
      case 'booking_accepted':
        return 'Booking for ${serviceType ?? 'service'} has been accepted for $homeownerName';
      case 'booking_declined':
        return 'Booking for ${serviceType ?? 'service'} has been declined for $homeownerName';
      case 'new_booking':
        return 'New booking request from $homeownerName for ${serviceType ?? 'service'}';
      default:
        return data['message'] ?? 'New notification';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No notifications',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final notification = snapshot.data!.docs[index];
              final data = notification.data() as Map<String, dynamic>;
              final timestamp = data['timestamp'] as Timestamp;

              return Dismissible(
                key: Key(notification.id),
                onDismissed: (_) {
                  FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(notification.id)
                      .delete();
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: FutureBuilder<String>(
                  future: _getNotificationMessage(data),
                  builder: (context, messageSnapshot) {
                    return InkWell(
                      onLongPress: () => _showDeleteDialog(context, notification.id),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Icon(
                            _getNotificationIcon(data['type']),
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        title: Text(
                          data['title'] ?? 'Notification',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              messageSnapshot.data ?? 'Loading...',
                              style: GoogleFonts.poppins(),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate()),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Mark as read
                          FirebaseFirestore.instance
                              .collection('notifications')
                              .doc(notification.id)
                              .update({'read': true});

                          // If it's a booking notification, navigate to bookings
                          if (data['type'] == 'new_booking') {
                            Navigator.pop(context);
                            // Navigate to the bookings section or specific booking
                          }
                        },
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
