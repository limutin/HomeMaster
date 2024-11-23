import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _HomeownerProfilePageState();
}

class _HomeownerProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser!;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _ageController;
  late TextEditingController _addressController;
  late TextEditingController _contactController;
  late TextEditingController _emailController;
  bool _isLoading = true;
  bool _isEditing = false;

  String? _profileImageBase64;
  final ImagePicker _picker = ImagePicker();

  late Map<String, dynamic> _initialData;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _ageController = TextEditingController();
    _addressController = TextEditingController();
    _contactController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _initialData = data;
        setState(() {
          _fullNameController.text = data['fullName'] ?? '';
          _ageController.text = (data['age'] ?? '').toString();
          _addressController.text = data['address'] ?? '';
          _contactController.text = data['contact'] ?? '';
          _emailController.text = data['email'] ?? '';
          _profileImageBase64 = data['profileImageBase64'];
          _isLoading = false;
        });
      } else {
        // If document doesn't exist, try to find it in the main service_providers collection
        final querySnapshot = await FirebaseFirestore.instance
            .collection('service_providers')
            .where('userId', isEqualTo: user.uid)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          setState(() {
            _fullNameController.text = data['fullName'] ?? '';
            _ageController.text = (data['age'] ?? '').toString();
            _addressController.text = data['address'] ?? '';
            _contactController.text = data['contact'] ?? '';
            _emailController.text = data['email'] ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Get current data from Firestore to compare
    final doc = await FirebaseFirestore.instance
        .collection('service_providers')
        .doc(user.uid)
        .get();
    
    if (!doc.exists) return;
    
    final currentData = doc.data()!;
    
    // Check if there are any changes
    bool hasChanges = false;
    
    if (currentData['fullName'] != _fullNameController.text ||
        (currentData['age']?.toString() ?? '') != _ageController.text ||
        currentData['address'] != _addressController.text ||
        currentData['contact'] != _contactController.text ||
        currentData['email'] != _emailController.text) {
      hasChanges = true;
    }

    // If no changes, just exit edit mode without saving
    if (!hasChanges) {
      setState(() => _isEditing = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(user.uid)
          .update({
        'fullName': _fullNameController.text,
        'age': int.tryParse(_ageController.text) ?? 0,
        'address': _addressController.text,
        'contact': _contactController.text,
        'email': _emailController.text,
        'profileImageBase64': _profileImageBase64,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Color(0xFF1C59D2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 400,
        maxHeight: 400,
      );
      
      if (image == null) return;

      setState(() => _isLoading = true);

      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      // Get document reference
      final docRef = FirebaseFirestore.instance
          .collection('service_providers')
          .doc(user.uid);

      // Check if document exists
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Update existing document
        await docRef.update({
          'profileImageBase64': base64Image,
        });
      } else {
        // Create new document
        await docRef.set({
          'profileImageBase64': base64Image,
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      setState(() {
        _profileImageBase64 = base64Image;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated successfully'),
          backgroundColor: Color(0xFF1C59D2),
        ),
      );
      
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    }
  }

  bool _hasChanges() {
    if (!_formKey.currentState!.validate()) return false;
    
    // Compare current values with initial values
    return _initialData['fullName'] != _fullNameController.text ||
        (_initialData['age']?.toString() ?? '') != _ageController.text ||
        _initialData['address'] != _addressController.text ||
        _initialData['contact'] != _contactController.text ||
        _initialData['email'] != _emailController.text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        appBar: AppBar(
          title: Text(
            'Profile',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1C59D2),
            ),
          ),
          backgroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(
            color: isDark ? Colors.white : const Color(0xFF1C59D2),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: isDark ? Colors.white : const Color(0xFF1C59D2),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.dark ? Colors.white : theme.colorScheme.primary,
          ),
        ),
        backgroundColor:
            theme.brightness == Brightness.dark ? Colors.grey[900] : theme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(
                Icons.edit,
                color: theme.brightness == Brightness.dark ? Colors.white : theme.colorScheme.primary,
              ),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image Section
              Stack(
                children: [
                  _buildProfileImage(),
                  if (_isEditing)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),

              // Ratings Section
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('service_providers')
                    .doc(user.uid)
                    .collection('ratings')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();

                  double averageRating = 0.0;
                  int totalRatings = snapshot.data?.docs.length ?? 0;

                  if (totalRatings > 0) {
                    double totalRating = 0;
                    for (var doc in snapshot.data!.docs) {
                      totalRating += (doc.data() as Map<String, dynamic>)['rating'].toDouble();
                    }
                    averageRating = totalRating / totalRatings;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...List.generate(5, (index) {
                              return Icon(
                                index < averageRating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 24,
                              );
                            }),
                          ],
                        ),
                        Text(
                          '${averageRating.toStringAsFixed(1)} ($totalRatings ratings)',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Form Fields
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _fullNameController,
                      enabled: _isEditing,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: const OutlineInputBorder(),
                        labelStyle: GoogleFonts.poppins(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Full name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ageController,
                      enabled: _isEditing,
                      decoration: InputDecoration(
                        labelText: 'Age',
                        border: const OutlineInputBorder(),
                        labelStyle: GoogleFonts.poppins(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Age is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      enabled: _isEditing,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        border: const OutlineInputBorder(),
                        labelStyle: GoogleFonts.poppins(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Address is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactController,
                      enabled: _isEditing,
                      decoration: InputDecoration(
                        labelText: 'Contact',
                        border: const OutlineInputBorder(),
                        labelStyle: GoogleFonts.poppins(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Contact is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      enabled: _isEditing,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: const OutlineInputBorder(),
                        labelStyle: GoogleFonts.poppins(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Email is required' : null,
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                'Save Changes',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() => _isEditing = false);
                                _loadUserData();
                              },
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final isDark = theme.brightness == Brightness.dark;

    return CircleAvatar(
      radius: 50,
      backgroundColor:
          theme.colorScheme.primary.withOpacity(0.1),
      backgroundImage: _profileImageBase64 != null
          ? MemoryImage(
              base64Decode(_profileImageBase64!))
          : null,
      child: _profileImageBase64 == null
          ? Icon(
              Icons.person,
              size: 50,
              color: theme.colorScheme.primary,
            )
          : null,
    );
  }
}
