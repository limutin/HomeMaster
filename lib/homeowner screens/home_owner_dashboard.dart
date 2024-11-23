import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homemaster/homeowner screens/homeowner_profile.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HomeOwnerDashboard extends StatefulWidget {
  const HomeOwnerDashboard({super.key});

  @override
  State<HomeOwnerDashboard> createState() => _HomeOwnerDashboardState();
}

class _HomeOwnerDashboardState extends State<HomeOwnerDashboard> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<String> _serviceCategories = [
    'Handyman Services',
    'Cleaning Services',
    'Plumbing Services',
    'Electrical Services',
    'Lawn and Landscaping Services',
    'Pest Control Services',
    'Security and Smart Home Installation',
    'Home Renovation and Remodeling',
  ];
  final RefreshController _refreshController = RefreshController();
  final int _currentIndex = 0;

  Stream<QuerySnapshot> get _notificationsStream => FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: user?.uid)
      .where('read', isEqualTo: false)
      .where('type', whereIn: ['booking_accepted', 'booking_declined'])
      .orderBy('timestamp', descending: true)
      .snapshots();

  Stream<QuerySnapshot> get _unreadMessagesStream => FirebaseFirestore.instance
      .collection('chat_rooms')
      .where('participants', arrayContains: user?.uid)
      .where('lastMessageReadBy', whereNotIn: [user?.uid])
      .snapshots();

  Widget _buildNotificationBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: _notificationsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Icon(Icons.notifications);
        }

        final unreadCount = snapshot.data!.docs.length;

        return Badge(
          label: Text(unreadCount.toString()),
          child: const Icon(Icons.notifications),
        );
      },
    );
  }

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

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
    _refreshController.refreshCompleted();
  }

  void _onPageChanged(int index) {
    if (_currentIndex == index) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/bookings');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/messages');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/user_settings');
        break;
    }
  }

  Future<Map<String, dynamic>?> _fetchHomeownerData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('homeowners')
          .doc(user.uid)
          .get();
      return doc.data();
    }
    return null;
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
      child: GestureDetector(
        onHorizontalDragEnd: (DragEndDetails details) {
          if (details.primaryVelocity! > 0) {
            _onPageChanged(_currentIndex > 0 ? _currentIndex - 1 : 3);
          } else if (details.primaryVelocity! < 0) {
            _onPageChanged(_currentIndex < 3 ? _currentIndex + 1 : 0);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('homeowners')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final homeownerData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  return Row(
                    children: [
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('homeowners')
                            .doc(user?.uid)
                            .snapshots(),
                        builder: (context, profileSnapshot) {
                          final profileData = profileSnapshot.data?.data()
                              as Map<String, dynamic>?;
                          return CircleAvatar(
                            backgroundImage:
                                profileData?['profileImageBase64'] != null
                                    ? MemoryImage(base64Decode(
                                        profileData!['profileImageBase64']))
                                    : null,
                            child: profileData?['profileImageBase64'] == null
                                ? const Icon(Icons.person)
                                : null,
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            homeownerData['fullName'] ?? 'User',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
                return const Text('Loading...');
              },
            ),
            actions: [
              IconButton(
                icon: _buildNotificationBadge(),
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.person,
                  color: isDark ? Colors.white : const Color(0xFF1C59D2),
                  size: 28,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeownerProfile(),
                  ),
                ),
              )
            ],
          ),
          body: SmartRefresher(
            controller: _refreshController,
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search for services...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white : theme.primaryColor,
                        ),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Service Categories',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _serviceCategories.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_serviceCategories[index]),
                            selected: _searchQuery ==
                                _serviceCategories[index].toLowerCase(),
                            onSelected: (selected) {
                              setState(() {
                                _searchQuery = selected
                                    ? _serviceCategories[index].toLowerCase()
                                    : '';
                                _searchController.text =
                                    selected ? _serviceCategories[index] : '';
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Available Services',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('jobs')
                        .where('status', isEqualTo: 'in_progress')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var services = snapshot.data!.docs;

                      if (_searchQuery.isNotEmpty) {
                        services = services.where((service) {
                          final data = service.data() as Map<String, dynamic>;
                          return data['title']
                                  .toString()
                                  .toLowerCase()
                                  .contains(_searchQuery) ||
                              data['description']
                                  .toString()
                                  .toLowerCase()
                                  .contains(_searchQuery);
                        }).toList();
                      }

                      if (services.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              'No services available',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          final service =
                              services[index].data() as Map<String, dynamic>;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('service_providers')
                                  .doc(service['serviceProviderId'])
                                  .get(),
                              builder: (context, providerSnapshot) {
                                if (providerSnapshot.connectionState == ConnectionState.waiting) {
                                  return const ListTile(
                                    leading: CircleAvatar(
                                      child: CircularProgressIndicator(),
                                    ),
                                    title: Text('Loading...'),
                                  );
                                }

                                final providerData = providerSnapshot.data?.data() as Map<String, dynamic>?;
                                final providerName = providerData?['fullName'] ?? 'Unknown Provider';
                                final providerImage = providerData?['profileImageBase64'];

                                return ListTile(
                                  leading: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                                        backgroundImage: providerImage != null
                                            ? MemoryImage(base64Decode(providerImage))
                                            : null,
                                        child: providerImage == null
                                            ? Icon(Icons.person, color: theme.primaryColor)
                                            : null,
                                      ),
                                    ],
                                  ),
                                  title: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service['title'] ?? 'Service',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        providerName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 5),
                                      Text(
                                        service['description'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Price: ₱${service['price']}',
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/book_service',
                                        arguments: {
                                          'serviceId': services[index].id,
                                          'serviceData': service,
                                          'providerData': providerData,
                                        },
                                      );
                                    },
                                    child: const Text('Book'),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index == 0) return;

              switch (index) {
                case 1:
                  Navigator.pushNamed(context, '/bookings');
                  break;
                case 2:
                  Navigator.pushNamed(context, '/messages');
                  break;
                case 3:
                  Navigator.pushNamed(context, '/user_settings');
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
                icon: Icon(Icons.book_outlined),
                activeIcon: Icon(Icons.book),
                label: 'Bookings',
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshController.dispose();
    super.dispose();
  }
}
