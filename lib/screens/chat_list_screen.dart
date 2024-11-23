import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  Future<DocumentSnapshot<Object?>> _getUserData(String userId) async {
    // Try service_providers collection first
    final spDoc = await FirebaseFirestore.instance
        .collection('service_providers')
        .doc(userId)
        .get();
    
    if (spDoc.exists) return spDoc;

    // If not found, try homeowners collection
    return await FirebaseFirestore.instance
        .collection('homeowners')
        .doc(userId)
        .get();
  }

  Widget _buildNoMessagesWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, 
            size: 48, 
            color: Colors.grey[400]
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Messages', style: GoogleFonts.poppins()),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('participants', arrayContains: currentUser?.uid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return _buildNoMessagesWidget();
          }

          // Filter out hidden chats
          final visibleChats = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final hiddenFrom = data.containsKey('hidden_from') 
                ? List<String>.from(data['hidden_from']) 
                : <String>[];
            return !hiddenFrom.contains(currentUser?.uid);
          }).toList();

          if (visibleChats.isEmpty) {
            return _buildNoMessagesWidget();
          }

          return ListView.builder(
            itemCount: visibleChats.length,
            itemBuilder: (context, index) {
              final chatRoom = visibleChats[index];
              final participants = List<String>.from(chatRoom['participants'] ?? []);
              
              print('Chat Room ID: ${chatRoom.id}');
              print('Participants: $participants');
              print('Current User ID: ${currentUser?.uid}');
              
              if (participants.isEmpty) {
                return const SizedBox.shrink();
              }

              final otherUserId = participants.firstWhere(
                (id) => id != currentUser?.uid,
                orElse: () => '',
              );

              if (otherUserId.isEmpty) {
                return const SizedBox.shrink();
              }

              return FutureBuilder<DocumentSnapshot<Object?>>(
                future: _getUserData(otherUserId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.hasError) {
                    print('Error fetching user data: ${userSnapshot.error}');
                    return ListTile(
                      title: Text('Error: ${userSnapshot.error}'),
                    );
                  }

                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text('Loading...'),
                    );
                  }

                  if (!userSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final displayName = userData['fullName'] ?? 'Unknown User';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userData['profileImageBase64'] != null
                          ? MemoryImage(base64Decode(userData['profileImageBase64']))
                          : null,
                      child: userData['profileImageBase64'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(
                      displayName,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      chatRoom['lastMessage'] ?? 'No messages yet',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      chatRoom['lastMessageTime'] != null
                          ? DateFormat.jm().format(
                              (chatRoom['lastMessageTime'] as Timestamp).toDate())
                          : '',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/chat',
                        arguments: {
                          'chatRoomId': chatRoom.id,
                          'otherUserName': displayName,
                          'bookingId': chatRoom['bookingId'] ?? '',
                        },
                      );
                    },
                    onLongPress: () async {
                      final delete = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            'Delete Conversation',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                          ),
                          content: Text(
                            'Are you sure you want to delete this conversation?',
                            style: GoogleFonts.poppins(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                'Delete',
                                style: GoogleFonts.poppins(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (delete == true) {
                        // Instead of deleting the chat room, update it to hide from current user
                        await FirebaseFirestore.instance
                            .collection('chat_rooms')
                            .doc(chatRoom.id)
                            .update({
                          'hidden_from': FieldValue.arrayUnion([currentUser?.uid])
                        });
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
} 