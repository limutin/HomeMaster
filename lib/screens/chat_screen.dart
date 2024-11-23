import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String otherUserName;
  final String bookingId;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.otherUserName,
    required this.bookingId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _isCompleting = false;
  bool _isRating = false;
  double _rating = 0;

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final message = _messageController.text.trim();
      _messageController.clear();

      // Add message to messages subcollection
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add({
        'text': message,
        'senderId': currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update chat room with last message
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      // Scroll to bottom
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  Future<String?> _processImage(File imageFile) async {
    try {
      // Compress the image
      final result = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 1024, // Adjust these values based on your needs
        minHeight: 1024,
        quality: 70,     // Adjust quality (0-100)
      );
      
      if (result == null) return null;
      
      // Convert to base64
      final base64String = base64Encode(result);
      return base64String;
    } catch (e) {
      print('Error processing image: $e');
      return null;
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isUploading = true);

      // Process the image
      final base64Image = await _processImage(File(image.path));
      if (base64Image == null) {
        throw Exception('Failed to process image');
      }

      // Add image message to Firestore
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add({
        'text': null,
        'imageBase64': base64Image,
        'senderId': currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update chat room with last message
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .update({
        'lastMessage': '📷 Photo',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      setState(() => _isUploading = false);
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending image: $e')),
      );
    }
  }

  Future<void> _completeTransaction() async {
    if (_isCompleting) return;

    try {
      setState(() => _isCompleting = true);

      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .get();

      if (!bookingDoc.exists) {
        throw 'Booking not found';
      }

      final bookingData = bookingDoc.data()!;
      final isHomeowner = currentUser?.uid == bookingData['homeownerId'];
      
      // Update the completion status
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        isHomeowner ? 'homeownerCompleted' : 'providerCompleted': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Check if both parties have marked as complete
      final updatedDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .get();
      
      final updatedData = updatedDoc.data()!;
      
      if (updatedData['homeownerCompleted'] == true && 
          updatedData['providerCompleted'] == true) {
        
        // If user is homeowner, show rating dialog before completing
        if (isHomeowner && mounted) {
          await _showRatingDialog(bookingData['serviceProviderId']);
        }

        // Complete the transaction
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          // Update booking status
          transaction.update(
            FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId),
            {
              'status': 'completed',
              'completedAt': FieldValue.serverTimestamp(),
            },
          );

          // Update job status if it exists
          if (bookingData['jobId'] != null) {
            transaction.update(
              FirebaseFirestore.instance.collection('jobs').doc(bookingData['jobId']),
              {
                'status': 'completed',
                'completedAt': FieldValue.serverTimestamp(),
              },
            );
          }

          // Create notifications for both parties
          final notifications = FirebaseFirestore.instance.collection('notifications');
          
          // Notification for homeowner
          transaction.set(notifications.doc(), {
            'userId': bookingData['homeownerId'],
            'title': 'Service Completed',
            'message': 'The service has been marked as completed.',
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
            'type': 'service_completed',
          });

          // Notification for service provider
          transaction.set(notifications.doc(), {
            'userId': bookingData['serviceProviderId'],
            'title': 'Service Completed',
            'message': 'The service has been marked as completed.',
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
            'type': 'service_completed',
          });
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Waiting for the other party to confirm completion'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing service: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  Future<void> _showRatingDialog(String serviceProviderId) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Rate Service Provider',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How would you rate your experience?',
                style: GoogleFonts.poppins(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(minWidth: 40),
                    onPressed: () {
                      setState(() => _rating = index + 1);
                    },
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: _isRating ? null : () async {
                try {
                  setState(() => _isRating = true);

                  // Save rating as double
                  await FirebaseFirestore.instance
                      .collection('service_providers')
                      .doc(serviceProviderId)
                      .collection('ratings')
                      .add({
                    'rating': _rating.toDouble(), // Explicitly convert to double
                    'userId': currentUser?.uid,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  // Calculate new average rating
                  final ratingsSnapshot = await FirebaseFirestore.instance
                      .collection('service_providers')
                      .doc(serviceProviderId)
                      .collection('ratings')
                      .get();

                  double totalRating = 0;
                  for (var doc in ratingsSnapshot.docs) {
                    totalRating += (doc.data()['rating'] as num).toDouble();
                  }

                  final averageRating = totalRating / ratingsSnapshot.docs.length;

                  await FirebaseFirestore.instance
                      .collection('service_providers')
                      .doc(serviceProviderId)
                      .update({
                    'averageRating': averageRating,
                    'totalRatings': ratingsSnapshot.docs.length,
                  });

                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving rating: $e')),
                  );
                } finally {
                  setState(() => _isRating = false);
                }
              },
              child: _isRating 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Submit',
                    style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.primary),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionButton() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final bookingData = snapshot.data!.data() as Map<String, dynamic>?;
        if (bookingData == null) return const SizedBox.shrink();

        final isHomeowner = currentUser?.uid == bookingData['homeownerId'];
        final hasCompleted = isHomeowner 
            ? bookingData['homeownerCompleted'] ?? false
            : bookingData['providerCompleted'] ?? false;
        
        if (bookingData['status'] == 'completed' || hasCompleted) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('✓ Completed', 
              style: TextStyle(color: Colors.green)),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: _isCompleting ? null : _completeTransaction,
            icon: _isCompleting 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(_isCompleting ? 'Completing...' : 'Complete Service'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletionStatus() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final bookingData = snapshot.data!.data() as Map<String, dynamic>?;
        if (bookingData == null) return const SizedBox.shrink();

        final isHomeowner = currentUser?.uid == bookingData['homeownerId'];
        final hasCompleted = isHomeowner 
            ? bookingData['homeownerCompleted'] ?? false
            : bookingData['providerCompleted'] ?? false;
        final otherPartyCompleted = isHomeowner 
            ? bookingData['providerCompleted'] ?? false
            : bookingData['homeownerCompleted'] ?? false;

        if (bookingData['status'] == 'completed') {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Service Completed',
                    style: GoogleFonts.poppins(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (bookingData['completedAt'] != null)
                  Text(
                    DateFormat('MMM dd').format(
                      (bookingData['completedAt'] as Timestamp).toDate()
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.green[700],
                    ),
                  ),
              ],
            ),
          );
        } else if (hasCompleted || otherPartyCompleted) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                const Icon(Icons.pending_outlined, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Waiting for ${otherPartyCompleted ? 'your' : 'other party\'s'} confirmation',
                    style: GoogleFonts.poppins(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.otherUserName,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          _buildCompletionButton(),
        ],
      ),
      body: Column(
        children: [
          _buildCompletionStatus(),
          if (_isUploading)
            const LinearProgressIndicator(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final messageDoc = snapshot.data!.docs[index];
                    final messageData = messageDoc.data() as Map<String, dynamic>;
                    
                    return _MessageBubble(
                      message: messageData['text']?.toString(),
                      imageBase64: messageData['imageBase64']?.toString(),
                      isMe: messageData['senderId'] == currentUser?.uid,
                      timestamp: messageData['timestamp'] as Timestamp?,
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: _isUploading ? null : _pickAndSendImage,
                  color: theme.primaryColor,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.poppins(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.poppins(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: theme.primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String? message;
  final String? imageBase64;
  final bool isMe;
  final Timestamp? timestamp;

  const _MessageBubble({
    this.message,
    this.imageBase64,
    required this.isMe,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeString = timestamp != null 
        ? DateFormat.jm().format(timestamp!.toDate())
        : 'Sending...';
    
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.75; // Maximum width of 75% of screen width

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                padding: imageBase64 == null 
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                    : const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isMe ? theme.primaryColor : theme.cardColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(isMe ? 12 : 0),
                    bottomRight: Radius.circular(isMe ? 0 : 12),
                  ),
                ),
                child: imageBase64 != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(imageBase64!),
                          fit: BoxFit.cover,
                          width: maxWidth,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                        ),
                      )
                    : Text(
                        message ?? '',
                        style: GoogleFonts.poppins(
                          color: isMe ? Colors.white : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
              ),
              const SizedBox(height: 2),
              Text(
                timeString,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 