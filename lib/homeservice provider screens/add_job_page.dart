import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class AddJobPage extends StatefulWidget {
  const AddJobPage({super.key});

  @override
  State<AddJobPage> createState() => _AddJobPageState();
}

class _AddJobPageState extends State<AddJobPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;
  final List<String> _serviceTypes = [
    'Handyman Services',
    'Cleaning Services',
    'Plumbing Services',
    'Electrical Services',
    'Lawn and Landscaping Services',
    'Pest Control Services',
    'Security and Smart Home Installation',
    'Home Renovation and Remodeling',
  ];
  String? _selectedService;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      
      // Update the collection name to match your Firestore structure
      final providerDoc = await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(user.uid)
          .get();
      
      if (!providerDoc.exists) {
        throw 'Service provider profile not found. Please complete your profile first.';
      }
      
      final providerData = providerDoc.data();
      if (providerData == null) {
        throw 'Service provider data is empty. Please update your profile.';
      }
      
      final providerName = providerData['fullName'] ?? 'Unknown Provider';
      final now = FieldValue.serverTimestamp();
      final price = double.parse(_priceController.text).toStringAsFixed(2);
      
      await FirebaseFirestore.instance.collection('jobs').add({
        'title': _selectedService,
        'description': _descriptionController.text.trim(),
        'price': double.parse(price),
        'date': Timestamp.fromDate(_selectedDate!),
        'serviceProviderId': user.uid,
        'serviceProviderName': providerName,
        'serviceProviderImage': providerData['profileImageBase64'], // Optional field
        'serviceProviderEmail': user.email,
        'status': 'in_progress',
        'createdAt': now,
        'service': _selectedService,
        'clientName': 'Not Assigned',
        'timestamp': now,
        'lastUpdated': now,
        'canEdit': true,
        'location': providerData['address'] ?? 'Not Specified',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job added successfully'),
            backgroundColor: Color(0xFF1C59D2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark ? [
              Colors.grey[900]!,
              Colors.grey[900]!,
            ] : [
              const Color(0xFF1C59D2),
              Colors.white,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDark ? Colors.white : Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Add New Job',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Form Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedService,
                            isExpanded: true,
                            dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                            decoration: InputDecoration(
                              labelText: 'Service Type',
                              labelStyle: GoogleFonts.poppins(
                                color: isDark ? Colors.white70 : const Color(0xFF1C59D2).withOpacity(0.7),
                              ),
                              prefixIcon: Icon(
                                Icons.work_outline,
                                color: isDark ? Colors.white70 : const Color(0xFF1C59D2),
                              ),
                              filled: true,
                              fillColor: isDark ? Colors.grey[800] : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white30 : const Color(0xFF1C59D2).withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.white30 : const Color(0xFF1C59D2).withOpacity(0.3),
                                ),
                              ),
                            ),
                            items: _serviceTypes.map((String service) {
                              return DropdownMenuItem<String>(
                                value: service,
                                child: Text(
                                  service,
                                  style: GoogleFonts.poppins(),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedService = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a service type';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _descriptionController,
                            labelText: 'Description',
                            icon: Icons.description_outlined,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _priceController,
                            labelText: 'Price',
                            icon: Icons.attach_money, // Using attach_money icon instead since currency_peso isn't available
                            prefixText: 'PHP ',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          const SizedBox(height: 20),
                          ListTile(
                            title: Text(
                              'Select Date',
                              style: GoogleFonts.poppins(),
                            ),
                            subtitle: Text(
                              _selectedDate == null
                                  ? 'No date selected'
                                  : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                              style: GoogleFonts.poppins(),
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () => _selectDate(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade400),
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitJob,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1C59D2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      'Add Job',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? prefixText,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(
        color: isDark ? Colors.white : const Color(0xFF1C59D2),
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.poppins(
          color: isDark ? Colors.white70 : const Color(0xFF1C59D2).withOpacity(0.7),
        ),
        prefixText: prefixText,
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.white70 : const Color(0xFF1C59D2),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFF1C59D2).withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFF1C59D2).withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF1C59D2),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $labelText';
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
} 