import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import '../reusable/build_text_field.dart';
import '../reusable/form_text_field.dart';
import 'home_owner_dashboard.dart';
import '../screens/role_selectiom.dart';


class HomeownerRegistrationPage extends StatefulWidget {
  const HomeownerRegistrationPage({super.key});

  @override
  State<HomeownerRegistrationPage> createState() => _HomeownerRegistrationPageState();
}

class _HomeownerRegistrationPageState extends State<HomeownerRegistrationPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactController = TextEditingController(text: '+63');
  final TextEditingController emailController = TextEditingController();
  
  DateTime? _selectedBirthDate;

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied')),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      String address = await _getAddressFromCoordinates(
          position.latitude, position.longitude);
      setState(() {
        addressController.text = address;
      });
      await _launchMap(position.latitude, position.longitude);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location: $e')),
      );
    }
  }

  Future<String> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        return '${placemark.street}, ${placemark.locality}, ${placemark.country}';
      }
      return 'No address found';
    } catch (e) {
      return 'Error retrieving address';
    }
  }

  Future<void> _launchMap(double latitude, double longitude) async {
    final googleMapUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(googleMapUrl)) {
      await launch(googleMapUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
      );

      Map<String, dynamic> homeownerData = {
        "fullName": fullNameController.text,
        "age": int.tryParse(ageController.text) ?? 0,
        "address": addressController.text,
        "contact": contactController.text,
        "email": emailController.text,
        "userId": user.uid,
        "createdAt": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('homeowners')
          .doc(user.uid)
          .set(homeownerData);

      if (mounted) Navigator.pop(context);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeOwnerDashboard(),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting form: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        ageController.text = (DateTime.now().year - picked.year).toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    emailController.text = user.email ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light(),
      child: WillPopScope(
        onWillPop: () async {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const RoleSelectionPage(),
            ),
          );
          return false;
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF1C59D2),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                children: [
                  Text(
                    'Personal Information',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField1(
                            controller: fullNameController,
                            labelText: 'Name',
                            icon: Icons.person,
                            onIconPressed: () {},
                          ),
                          const SizedBox(height: 16),
                          _buildDatePickerField(context, 'Birth Date', Icons.cake),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: addressController,
                            labelText: 'Address',
                            icon: Icons.home,
                            onIconPressed: _getCurrentLocation,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField1(
                            controller: contactController,
                            labelText: 'Contact Number',
                            icon: Icons.phone,
                            isNumeric: true,
                            onIconPressed: () {},
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your contact number';
                              }
                              // Remove the +63 prefix for validation
                              final numberOnly = value.replaceAll('+63', '').trim();
                              if (numberOnly.length != 10) {
                                return 'Please enter 10 digits after +63';
                              }
                              if (!RegExp(r'^[0-9]+$').hasMatch(numberOnly)) {
                                return 'Please enter only numbers';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField1(
                            controller: emailController,
                            labelText: 'Email',
                            icon: Icons.email,
                            isEmail: true,
                            onIconPressed: () {},
                            enabled: false,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1C59D2),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check),
                        const SizedBox(width: 8),
                        Text(
                          'Submit',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(BuildContext context, String labelText, IconData icon) {
    return GestureDetector(
      onTap: () => _selectBirthDate(context),
      child: AbsorbPointer(
        child: TextFormField(
          controller: ageController,
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: GoogleFonts.poppins(
              color: const Color(0xFF1C59D2).withOpacity(0.7),
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF1C59D2)),
            suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF1C59D2)),
            filled: true,
            fillColor: Colors.white,
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
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
          style: GoogleFonts.poppins(
            color: const Color(0xFF1C59D2),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your birth date';
            }
            int? age = int.tryParse(value);
            if (age == null || age < 18) {
              return 'You must be at least 18 years old';
            }
            return null;
          },
        ),
      ),
    );
  }
}
