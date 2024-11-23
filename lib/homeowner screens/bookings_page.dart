import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  Future<bool> _onWillPop(BuildContext context) async {
    Navigator.pushReplacementNamed(context, '/dashboard');
    return false;
  }

  Future<void> _showCancelDialog(BuildContext context, String bookingId) async {
    final reasonController = TextEditingController();
    bool isLoading = false;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
          title: Text(
            'Cancel Booking',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : null,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please provide a reason for cancellation:',
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (reasonController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please provide a reason'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        final batch = FirebaseFirestore.instance.batch();
                        
                        // Update booking status
                        final bookingRef = FirebaseFirestore.instance
                            .collection('bookings')
                            .doc(bookingId);
                            
                        batch.update(bookingRef, {
                          'status': 'cancelled',
                          'cancellationReason': reasonController.text.trim(),
                          'cancelledAt': FieldValue.serverTimestamp(),
                        });

                        // Create notification for service provider
                        final bookingDoc = await bookingRef.get();
                        final bookingData = bookingDoc.data() as Map<String, dynamic>;
                        
                        final notificationRef = FirebaseFirestore.instance
                            .collection('notifications')
                            .doc();
                            
                        batch.set(notificationRef, {
                          'userId': bookingData['serviceProviderId'],
                          'title': 'Booking Cancelled',
                          'message': 'A booking has been cancelled by the client.\nReason: ${reasonController.text.trim()}',
                          'timestamp': FieldValue.serverTimestamp(),
                          'read': false,
                          'type': 'booking_cancelled',
                          'bookingId': bookingId,
                        });

                        await batch.commit();

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Booking cancelled successfully'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Submit',
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          elevation: 0,
          title: Text(
            'My Bookings',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1C59D2),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('homeownerId', isEqualTo: user?.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'No bookings yet',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final booking = snapshot.data!.docs[index];
                final data = booking.data() as Map<String, dynamic>;
                final scheduledDateTime = (data['scheduledDateTime'] as Timestamp).toDate();

                return Card(
                  color: isDark ? Colors.grey[800] : Colors.white,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    collapsedTextColor: isDark ? Colors.white : null,
                    textColor: isDark ? Colors.white : null,
                    iconColor: isDark ? Colors.white : null,
                    title: Text(
                      data['serviceType'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Provider: ${data['serviceProviderName']}',
                          style: GoogleFonts.poppins(
                            color: isDark ? Colors.white70 : null,
                          ),
                        ),
                        Text(
                          'Status: ${data['status'].toString().toUpperCase()}',
                          style: GoogleFonts.poppins(
                            color: _getStatusColor(data['status'], theme),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Schedule: ${DateFormat('MMM dd, yyyy - hh:mm a').format(scheduledDateTime)}',
                              style: GoogleFonts.poppins(
                                color: isDark ? Colors.white : null,
                              ),
                            ),
                            Text(
                              'Price: PHP ${data['price']}',
                              style: GoogleFonts.poppins(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Address: ${data['address']}',
                              style: GoogleFonts.poppins(
                                color: isDark ? Colors.white : null,
                              ),
                            ),
                            if (data['notes']?.isNotEmpty ?? false)
                              Text(
                                'Notes: ${data['notes']}',
                                style: GoogleFonts.poppins(),
                              ),
                            if (data['cancellationReason']?.isNotEmpty ?? false)
                              Text(
                                'Cancellation Reason: ${data['cancellationReason']}',
                                style: GoogleFonts.poppins(color: Colors.red),
                              ),
                            if (data['status'] == 'pending')
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: ElevatedButton(
                                  onPressed: () => _showCancelDialog(context, booking.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel Booking',
                                    style: GoogleFonts.poppins(color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return theme.primaryColor;
      default:
        return Colors.grey;
    }
  }
}
