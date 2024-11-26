import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../homeservice provider screens/add_job_page.dart';

class HomeServiceProviderDashboard extends StatefulWidget {
  const HomeServiceProviderDashboard({super.key});

  @override
  State<HomeServiceProviderDashboard> createState() =>
      _HomeServiceProviderDashboardState();
}

class _HomeServiceProviderDashboardState
    extends State<HomeServiceProviderDashboard> {
  final user = FirebaseAuth.instance.currentUser!;

  // Add stream for active jobs
  Stream<List<QueryDocumentSnapshot>> get _activeJobsStream =>
      FirebaseFirestore.instance
          .collection('jobs')
          .where('serviceProviderId', isEqualTo: user.uid)
          .where('status', whereIn: ['in_progress', 'pending'])
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
            // Create a map to store unique jobs by ID
            final uniqueJobs = <String, QueryDocumentSnapshot>{};

            // Add each job to the map, which will automatically handle duplicates
            for (var doc in snapshot.docs) {
              uniqueJobs[doc.id] = doc;
            }

            // Return list of unique documents
            return uniqueJobs.values.toList();
          });

  // Add stream for completed jobs
  Stream<QuerySnapshot> get _completedJobsStream => FirebaseFirestore.instance
      .collection('jobs')
      .where('serviceProviderId', isEqualTo: user.uid)
      .where('status', isEqualTo: 'completed')
      .snapshots();

  // Add stream for recent activities
  Stream<QuerySnapshot> get _recentActivitiesStream =>
      FirebaseFirestore.instance
          .collection('jobs')
          .where('serviceProviderId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(3)
          .snapshots();

  // Add stream for booking requests
  Stream<QuerySnapshot> get _bookingRequestsStream => FirebaseFirestore.instance
      .collection('bookings')
      .where('serviceProviderId', isEqualTo: user.uid)
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .snapshots();

  // Add this stream to the _HomeServiceProviderDashboardState class
  Stream<QuerySnapshot> get _pendingNotificationsStream =>
      FirebaseFirestore.instance
          .collection('bookings')
          .where('serviceProviderId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .where('notified', isEqualTo: false)
          .snapshots();

  // Add this stream for unread messages
  Stream<QuerySnapshot> get _unreadMessagesStream => FirebaseFirestore.instance
      .collection('chat_rooms')
      .where('participants', arrayContains: user.uid)
      .where('lastMessageReadBy', whereNotIn: [user.uid]).snapshots();

  void _navigateToAddJob() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddJobPage(), // Create this page
      ),
    );
  }

  void _editJob(DocumentSnapshot job) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleController = TextEditingController(text: job['title']);
    final descriptionController =
        TextEditingController(text: job['description']);
    final priceController =
        TextEditingController(text: job['price'].toString());
    DateTime selectedDate = (job['date'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Job',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1C59D2),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price',
                  prefixText: '₱',
                  labelStyle: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  'Date: ${DateFormat('MMM dd, yyyy').format(selectedDate)}',
                  style: GoogleFonts.poppins(),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    selectedDate = picked;
                  }
                },
              ),
            ],
          ),
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
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('jobs')
                    .doc(job.id)
                    .update({
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'price': double.parse(priceController.text),
                  'date': Timestamp.fromDate(selectedDate),
                  'lastUpdated': FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Job updated successfully'),
                      backgroundColor: Color(0xFF1C59D2),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating job: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              'Save',
              style: GoogleFonts.poppins(color: const Color(0xFF1C59D2)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(
                  'Exit App',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                content: Text(
                  'Do you want to exit the app?',
                  style: GoogleFonts.poppins(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'No',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      'Yes',
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ) ??
            false;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Image.asset(
                'assets/icon/icon.png',
                width: 40,
                height: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('service_providers')
                      .where('userId', isEqualTo: user.uid)
                      .snapshots()
                      .map((query) => query.docs.first),
                  builder: (context, snapshot) {
                    String providerName = 'Service Provider'; // Default name

                    if (snapshot.hasData && snapshot.data != null) {
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      if (data != null && data['fullName'] != null) {
                        providerName = data['fullName'];
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back!',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        Text(
                          providerName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: _buildNotificationBadge(),
              onPressed: () {
                Navigator.pushNamed(context, '/provider_notifications');
              },
            ),
            IconButton(
              icon: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('service_providers')
                    .where('userId', isEqualTo: user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final profileImageBase64 =
                        snapshot.data!.docs.first.data() as Map<String, dynamic>;
                    return CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      backgroundImage: profileImageBase64['profileImageBase64'] != null
                          ? MemoryImage(
                              base64Decode(profileImageBase64['profileImageBase64']))
                          : null,
                      child: profileImageBase64['profileImageBase64'] == null
                          ? Icon(
                              Icons.person,
                              color: theme.colorScheme.primary,
                              size: 20,
                            )
                          : null,
                    );
                  }
                  return CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  );
                },
              ),
              onPressed: () => Navigator.pushNamed(context, '/profile'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            return Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Cards with StreamBuilder
                  Row(
                    children: [
                      StreamBuilder<List<QueryDocumentSnapshot>>(
                        stream: _activeJobsStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) return const SizedBox();

                          return _buildStatCard(
                            'Active Jobs',
                            snapshot.hasData
                                ? snapshot.data!.length.toString()
                                : '0',
                            Icons.work_outline,
                          );
                        },
                      ),
                      const SizedBox(width: 15),
                      StreamBuilder<QuerySnapshot>(
                        stream: _completedJobsStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) return const SizedBox();

                          return _buildStatCard(
                            'Completed',
                            snapshot.hasData
                                ? snapshot.data!.docs.length.toString()
                                : '0',
                            Icons.check_circle_outline,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Active Jobs with StreamBuilder
                  Text(
                    'Active Jobs',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildActiveJobsList(),

                  const SizedBox(height: 30),

                  // Recent Activities with StreamBuilder
                  Text(
                    'Recent Activities',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 15),
                  StreamBuilder<QuerySnapshot>(
                    stream: _recentActivitiesStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                            child: Text('Something went wrong'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.history,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No recent activities',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final job = snapshot.data!.docs[index];
                          return _buildActivityCard(job);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  Text(
                    'Completed Jobs',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildCompletedJobsList(),

                  // Booking Requests Section
                  Text(
                    'Booking Requests',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildBookingRequestsList(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            BottomNavigationBar(
              currentIndex: 0,
              onTap: (index) {
                if (index == 0) return; // Already on dashboard
                if (index == 2) return; // Skip center item (Add Job)

                switch (index) {
                  case 1:
                    Navigator.pushNamed(context, '/schedule');
                    break;
                  case 3:
                    Navigator.pushNamed(context, '/messages');
                    break;
                  case 4:
                    Navigator.pushNamed(context, '/settings');
                    break;
                }
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
              selectedItemColor: const Color(0xFF1C59D2),
              unselectedItemColor: const Color(0xFF1C59D2),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined),
                  activeIcon: Icon(Icons.calendar_today),
                  label: 'Schedule',
                ),
                const BottomNavigationBarItem(
                  icon: SizedBox(height: 47),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: _buildMessageBadge(Icons.message_outlined),
                  activeIcon: _buildMessageBadge(Icons.message),
                  label: 'Messages',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
            // Floating Add Job button
            Positioned(
              bottom: 25, // Increased bottom padding
              child: SizedBox(
                height: 56,
                width: 56,
                child: FloatingActionButton(
                  elevation: 4,
                  backgroundColor: const Color(0xFF1C59D2),
                  onPressed: _navigateToAddJob,
                  child: const Icon(
                    Icons.add_circle_outline,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return GestureDetector(
          onTap: onTap,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C59D2),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCompletedJobs() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Completed Jobs',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1C59D2),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Completed jobs list
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildCompletedJobsList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(DocumentSnapshot job) {
    final jobData = job.data() as Map<String, dynamic>;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('homeowners')
          .doc(jobData['homeownerId'])
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final homeownerData = snapshot.data?.data() as Map<String, dynamic>?;
        final homeownerName = homeownerData?['fullName'] ?? 'Unknown User';

        // Safely handle the date
        DateTime? activityDate;
        try {
          activityDate = jobData['date'] != null
              ? (jobData['date'] as Timestamp).toDate()
              : null;
        } catch (e) {
          print('Error parsing activity date: $e');
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor : Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.work_outline,
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(
              jobData['title'] ?? 'Untitled Job',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text(
                  'Client: $homeownerName',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (activityDate != null)
                  Text(
                    DateFormat('MMM dd, yyyy').format(activityDate),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                Text(
                  'Status: ${(jobData['status'] ?? 'unknown').toUpperCase()}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _getStatusColor(jobData['status']),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildActiveJobsList() {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: _activeJobsStream,
      builder: (context, snapshot) {
        print('Stream connection state: ${snapshot.connectionState}');
        print('Has error: ${snapshot.hasError}');
        if (snapshot.hasError) {
          print('Error: ${snapshot.error}');
        }
        if (snapshot.hasData) {
          print('Number of docs: ${snapshot.data!.length}');
          for (var doc in snapshot.data!) {
            print('Job ID: ${doc.id}');
            print('Status: ${doc['status']}');
            print('ServiceProviderId: ${doc['serviceProviderId']}');
          }
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.work_off_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No active jobs yet',
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final job = snapshot.data![index];
            return _buildActiveJobCard(job);
          },
        );
      },
    );
  }

  Widget _buildActiveJobCard(DocumentSnapshot job) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final jobData = job.data() as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey[800]! : theme.dividerColor,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        childrenPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.work_outline,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          jobData['title'] ?? 'Untitled Job',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(
              'PHP ${jobData['price']?.toString() ?? '0'}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              DateFormat('MMM dd, yyyy')
                  .format((jobData['date'] as Timestamp).toDate()),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                jobData['description'] ?? 'No description provided',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _editJob(job),
                    icon: Icon(Icons.edit, color: theme.colorScheme.primary),
                    label: Text(
                      'Edit',
                      style: GoogleFonts.poppins(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  DropdownButton<String>(
                    value: jobData['status'],
                    items: [
                      DropdownMenuItem(
                        value: 'in_progress',
                        child: Text(
                          'In Progress',
                          style: GoogleFonts.poppins(
                              color: theme.colorScheme.primary),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text(
                          'Pending',
                          style: GoogleFonts.poppins(color: Colors.orange),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text(
                          'Completed',
                          style: GoogleFonts.poppins(color: Colors.green),
                        ),
                      ),
                    ],
                    onChanged: (String? newStatus) async {
                      if (newStatus == null) return;

                      try {
                        // Get the current job data to preserve the price
                        final currentJobData =
                            job.data() as Map<String, dynamic>;

                        await FirebaseFirestore.instance
                            .collection('jobs')
                            .doc(job.id)
                            .update({
                          'status': newStatus,
                          'lastUpdated': FieldValue.serverTimestamp(),
                          'price': currentJobData['price'] ??
                              0, // Preserve the existing price
                        });

                        String message =
                            'Job marked as ${newStatus.replaceAll('_', ' ')}';
                        Color backgroundColor = newStatus == 'completed'
                            ? Colors.green
                            : newStatus == 'pending'
                                ? Colors.orange
                                : theme.colorScheme.primary;

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              backgroundColor: backgroundColor,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error updating status: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedJobsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _completedJobsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.task_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No completed jobs yet',
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final job = snapshot.data!.docs[index];
            return _buildCompletedJobCard(job);
          },
        );
      },
    );
  }

  Widget _buildCompletedJobCard(DocumentSnapshot job) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final jobData = job.data() as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.green.withOpacity(0.3)
              : Colors.green.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
          ),
        ),
        title: Text(
          jobData['title'] ?? 'Untitled Job',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(
              'PHP ${jobData['price']?.toString() ?? '0'}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            if (jobData['date'] != null)
              Text(
                DateFormat('MMM dd, yyyy')
                    .format((jobData['date'] as Timestamp).toDate()),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _deleteCompletedJob(job),
        ),
      ),
    );
  }

  Future<void> _deleteCompletedJob(DocumentSnapshot job) async {
    // Show confirmation dialog
    bool confirmDelete = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Delete Job',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Are you sure you want to delete this completed job?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey),
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
        ) ??
        false;

    if (!confirmDelete) return;

    try {
      // Delete the job from Firestore
      await FirebaseFirestore.instance.collection('jobs').doc(job.id).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBookingRequestsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _bookingRequestsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No booking requests',
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final booking = snapshot.data!.docs[index];
            return _buildBookingRequestCard(booking);
          },
        );
      },
    );
  }

  Widget _buildBookingRequestCard(DocumentSnapshot booking) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('homeowners')
          .doc(booking['homeownerId'])
          .get(),
      builder: (context, homeownerSnapshot) {
        if (homeownerSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final homeownerData =
            homeownerSnapshot.data?.data() as Map<String, dynamic>?;
        final homeownerName = homeownerData?['fullName'] ?? 'Unknown User';
        final homeownerContact =
            homeownerData?['contact'] ?? 'No contact provided';

        // Safely handle the scheduledDateTime
        DateTime? scheduledDateTime;
        try {
          scheduledDateTime = booking['scheduledDateTime'] != null
              ? (booking['scheduledDateTime'] as Timestamp).toDate()
              : null;
        } catch (e) {
          print('Error parsing scheduledDateTime: $e');
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor : Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            childrenPadding: const EdgeInsets.all(20),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.calendar_today,
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(
              booking['serviceType'] ?? 'Untitled Booking',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text(
                  'From: $homeownerName',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (scheduledDateTime != null)
                  Text(
                    DateFormat('MMM dd, yyyy - hh:mm a')
                        .format(scheduledDateTime),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Number:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    homeownerContact,
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Service Address:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    booking['address'],
                    style: GoogleFonts.poppins(),
                  ),
                  if (booking['notes']?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Additional Notes:',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      booking['notes'],
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _handleBookingResponse(booking, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Accept',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _handleBookingResponse(booking, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Decline',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleBookingResponse(
      DocumentSnapshot booking, bool accept) async {
    try {
      final bookingData = booking.data() as Map<String, dynamic>;
      final homeownerDoc = await FirebaseFirestore.instance
          .collection('homeowners')
          .doc(bookingData['homeownerId'])
          .get();
      final homeownerData = homeownerDoc.data() as Map<String, dynamic>;
      final homeownerName = homeownerData['fullName'] ?? 'Unknown User';

      final batch = FirebaseFirestore.instance.batch();

      if (accept) {
        // Update booking status
        batch.update(
          FirebaseFirestore.instance.collection('bookings').doc(booking.id),
          {
            'status': 'accepted',
            'lastUpdated': FieldValue.serverTimestamp(),
          },
        );

        // Create or update chat room with participants array and initial message
        final chatRoomId = '${user.uid}_${bookingData['homeownerId']}';
        final chatRoomRef =
            FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId);

        // Check if chat room exists
        final chatRoomDoc = await chatRoomRef.get();
        if (!chatRoomDoc.exists) {
          // Create new chat room
          batch.set(chatRoomRef, {
            'participants': [user.uid, bookingData['homeownerId']],
            'lastMessage': 'Booking accepted',
            'lastMessageTime': FieldValue.serverTimestamp(),
            'lastMessageReadBy': [user.uid],
            'bookingId': booking.id,
            'hidden_from': [], // Initialize empty hidden_from array
          });

          // Add initial system message
          batch.set(
            chatRoomRef.collection('messages').doc(),
            {
              'text': 'Booking accepted',
              'senderId': user.uid,
              'timestamp': FieldValue.serverTimestamp(),
              'isSystemMessage': true,
            },
          );
        } else {
          // Update existing chat room and clear hidden_from array
          batch.update(chatRoomRef, {
            'lastMessage': 'Booking accepted',
            'lastMessageTime': FieldValue.serverTimestamp(),
            'lastMessageReadBy': [user.uid],
            'bookingId': booking.id,
            'hidden_from': [], // Clear the hidden_from array
          });
        }

        // Add initial system message
        batch.set(
          chatRoomRef.collection('messages').doc(),
          {
            'text': 'Booking accepted',
            'senderId': user.uid,
            'timestamp': FieldValue.serverTimestamp(),
            'isSystemMessage': true,
          },
        );

        // Create notification for homeowner
        batch.set(
          FirebaseFirestore.instance.collection('notifications').doc(),
          {
            'userId': bookingData['homeownerId'],
            'title': 'Booking Accepted',
            'message': 'Your booking has been accepted',
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
            'type': 'booking_accepted',
          },
        );
      } else {
        // If declining, just update the booking status
        batch.update(
          FirebaseFirestore.instance.collection('bookings').doc(booking.id),
          {
            'status': 'declined',
            'lastUpdated': FieldValue.serverTimestamp(),
          },
        );

        // Add decline notification
        batch.set(
          FirebaseFirestore.instance.collection('notifications').doc(),
          {
            'userId': bookingData['homeownerId'],
            'title': 'Booking Declined',
            'message':
                'Your booking request for ${bookingData['serviceType']} has been declined.',
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
            'type': 'booking_declined',
            'homeownerName': homeownerName,
          },
        );
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Booking ${accept ? 'accepted' : 'declined'} successfully'),
            backgroundColor: accept ? Colors.green : Colors.red,
          ),
        );

        // Navigate to chat after accepting
        if (accept) {
          Navigator.pushNamed(
            context,
            '/chat',
            arguments: {
              'chatRoomId': '${user.uid}_${bookingData['homeownerId']}',
              'otherUserName': homeownerName,
              'bookingId': booking.id,
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add this method to build the notification badge
  Widget _buildNotificationBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: _pendingNotificationsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Icon(Icons.notifications_outlined);
        }

        return Badge(
          label: Text(snapshot.data!.docs.length.toString()),
          child: const Icon(Icons.notifications_outlined),
        );
      },
    );
  }

  // Add this method to build message badge
  Widget _buildMessageBadge(IconData icon) {
    return StreamBuilder<QuerySnapshot>(
      stream: _unreadMessagesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Icon(icon);
        }

        return Badge(
          label: Text(snapshot.data!.docs.length.toString()),
          child: Icon(icon),
        );
      },
    );
  }
}
