import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart'; // Import for reverse geocoding
import 'package:google_fonts/google_fonts.dart'; // Import this package
import '../reusable/build_text_field.dart';
import '../reusable/form_text_field copy.dart';
import '../reusable/form_text_field.dart';
import '../homeservice provider screens/home_service_provider_dashboard.dart'; // Add this import
// Add this package for modern progress indicator
import '../screens/role_selectiom.dart';

class HomeServiceProviderPage extends StatefulWidget {
  const HomeServiceProviderPage({super.key});

  @override
  State<HomeServiceProviderPage> createState() =>
      _HomeServiceProviderPageState();
}

class _HomeServiceProviderPageState extends State<HomeServiceProviderPage> {
  final user = FirebaseAuth.instance.currentUser!;
  int _currentPage = 0;
  final _formKey = GlobalKey<FormState>();
  final _pages = [
    'Personal Information',
    'Service Information',
    'Availability & Rates',
    'Confirmation'
  ];
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactController =
      TextEditingController(text: '+63');
  final TextEditingController emailController = TextEditingController(
    text: FirebaseAuth.instance.currentUser?.email ?? ''
  );
  final TextEditingController serviceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController serviceAreaController = TextEditingController();
  final TextEditingController certificationsController =
      TextEditingController();
  final TextEditingController availabilityController = TextEditingController();
  final TextEditingController hourlyRateController = TextEditingController();
  final TextEditingController preferredHoursController =
      TextEditingController();

  DateTime? _selectedBirthDate;

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

  final List<String> _experienceYears = [
    'Less than 1 year',
    '1 year',
    '2 years',
    '3 years',
    '4 years',
    '5 years',
    '6 years',
    '7 years',
    '8 years',
    '9 years',
    '10 years',
    'More than 10 years'
  ];
  String? _selectedExperience;

  final List<String> _workingHours = [
    '8:00 AM - 5:00 PM',
    '9:00 AM - 6:00 PM',
    '10:00 AM - 7:00 PM',
    'Flexible Hours',
    'By Appointment Only',
    'Weekends Only',
    'On-Call 24/7'
  ];
  String? _selectedWorkingHours;

  Future<void> _getCurrentLocation() async {
    // Check for location permission
    LocationPermission permission = await Geolocator.checkPermission();

    // If permission is denied, request permission
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, show a message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Location permission is denied. Please allow access to use this feature.')),
        );
        return; // Exit the function if permission is denied
      }
    }

    // If permission is denied forever, show an error message
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Location permissions are permanently denied, we cannot access the location.')),
      );
      return; // Exit the function
    }

    // If permission is granted, get the location
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      // Get address from coordinates
      String address = await _getAddressFromCoordinates(
          position.latitude, position.longitude);
      setState(() {
        addressController.text = address; // Set the retrieved address
      });
      await _launchMap(position.latitude, position.longitude);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location: $e')),
      );
    }
  }

  Future<String> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        return '${placemark.street}, ${placemark.locality}, ${placemark.country}';
      } else {
        return 'No address found';
      }
    } catch (e) {
      print(e);
      return 'Error retrieving address';
    }
  }

  Future<void> _launchMap(double latitude, double longitude) async {
    final String googleMapUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
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
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );

      Map<String, dynamic> providerData = {
        "fullName": fullNameController.text,
        "age": int.tryParse(ageController.text) ?? 0,
        "address": addressController.text,
        "contact": contactController.text,
        "email": emailController.text,
        "service": _selectedService,
        "description": descriptionController.text,
        "experience": int.tryParse(experienceController.text) ?? 0,
        "serviceArea": serviceAreaController.text,
        "certifications": certificationsController.text,
        "availability": availabilityController.text,
        "hourlyRate": double.tryParse(hourlyRateController.text) ?? 0.0,
        "preferredHours": preferredHoursController.text,
        "userId": user.uid, // Add user ID to link the profile
        "createdAt": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('service_providers')
          .add(providerData);

      // Close loading indicator
      if (mounted) Navigator.pop(context);

      // Show success message and navigate
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeServiceProviderDashboard(),
          ),
        );
      }
    } catch (e) {
      // Close loading indicator
      if (mounted) Navigator.pop(context);

      // Show error message
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

  Widget _buildPageContent() {
    switch (_currentPage) {
      case 0:
        return _buildSection([
          CustomTextField1(
            controller: fullNameController,
            labelText: 'Name',
            icon: Icons.person,
            onIconPressed:
                () {}, // You can add any functionality here if needed
          ),
          _buildDatePickerField(context, 'Birth Date', Icons.cake),
          CustomTextField(
            controller: addressController,
            labelText: 'Address',
            icon: Icons.home,
            onIconPressed: _getCurrentLocation, // Call the location method
          ),
          CustomTextField1(
            controller: contactController,
            labelText: 'Contact Number',
            icon: Icons.phone,
            isNumeric: true,
            onIconPressed:
                () {}, // You can add any functionality here if needed
          ),
          CustomTextField1(
            controller: emailController,
            labelText: 'Email',
            icon: Icons.email,
            isEmail: true,
            readOnly: true,
            onIconPressed:
                () {}, // You can add any functionality here if needed
          ),
        ]);
      case 1:
        return _buildSection([
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: DropdownButtonFormField<String>(
              value: _selectedService,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Service Offered',
                labelStyle: GoogleFonts.poppins(
                  color: const Color(0xFF1C59D2).withOpacity(0.7),
                ),
                prefixIcon: const Icon(
                  Icons.build,
                  color: Color(0xFF1C59D2),
                ),
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
              ),
              items: _serviceTypes.map((String service) {
                return DropdownMenuItem<String>(
                  value: service,
                  child: Text(
                    service,
                    style: GoogleFonts.poppins(),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedService = newValue;
                  serviceController.text = newValue ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a service type';
                }
                return null;
              },
            ),
          ),
          CustomTextField1(
            controller: descriptionController,
            labelText: 'Service Description',
            icon: Icons.description,
            maxLines: 3,
            onIconPressed:
                () {}, // You can add any functionality here if needed
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: DropdownButtonFormField<String>(
              value: _selectedExperience,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Years of Experience',
                labelStyle: GoogleFonts.poppins(
                  color: const Color(0xFF1C59D2).withOpacity(0.7),
                ),
                prefixIcon: const Icon(
                  Icons.star,
                  color: Color(0xFF1C59D2),
                ),
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
              ),
              items: _experienceYears.map((String years) {
                return DropdownMenuItem<String>(
                  value: years,
                  child: Text(
                    years,
                    style: GoogleFonts.poppins(),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedExperience = newValue;
                  experienceController.text = newValue ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your years of experience';
                }
                return null;
              },
            ),
          ),
          CustomTextField1(
            controller: serviceAreaController,
            labelText: 'Service Area (Locations)',
            icon: Icons.location_on,
            onIconPressed:
                () {}, // You can add any functionality here if needed
          ),
          CustomTextField1(
            controller: certificationsController,
            labelText: 'Certifications (if any)',
            icon: Icons.card_membership,
            onIconPressed:
                () {}, // You can add any functionality here if needed
          ),
        ]);
      case 2:
        return _buildSection([
          CustomTextField1(
            controller: availabilityController,
            labelText: 'Availability Schedule',
            icon: Icons.schedule,
            onIconPressed:
                () {}, // You can add any functionality here if needed
          ),
          CustomTextField2(
            controller: hourlyRateController,
            labelText: 'Hourly Rate',
            icon: Icons.attach_money,
            isNumeric: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onIconPressed:
                () {}, // You can add any functionality here if needed
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: DropdownButtonFormField<String>(
              value: _selectedWorkingHours,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Preferred Working Hours',
                labelStyle: GoogleFonts.poppins(
                  color: const Color(0xFF1C59D2).withOpacity(0.7),
                ),
                prefixIcon: const Icon(
                  Icons.access_time,
                  color: Color(0xFF1C59D2),
                ),
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
              ),
              items: _workingHours.map((String hours) {
                return DropdownMenuItem<String>(
                  value: hours,
                  child: Text(
                    hours,
                    style: GoogleFonts.poppins(),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedWorkingHours = newValue;
                  preferredHoursController.text = newValue ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select preferred working hours';
                }
                return null;
              },
            ),
          ),
        ]);

      case 3:
        return _buildSection([
          _buildConfirmationDetail('Full Name', fullNameController.text),
          _buildConfirmationDetail('Age', ageController.text),
          _buildConfirmationDetail('Address', addressController.text),
          _buildConfirmationDetail('Contact', contactController.text),
          _buildConfirmationDetail('Email', emailController.text),
          const SizedBox(height: 8),
          _buildConfirmationDetail('Service Offered', _selectedService ?? 'Not selected'),
          _buildConfirmationDetail('Description', descriptionController.text),
          _buildConfirmationDetail('Experience', _selectedExperience ?? 'Not selected'),
          _buildConfirmationDetail('Service Area', serviceAreaController.text),
          _buildConfirmationDetail('Certifications', certificationsController.text),
          const SizedBox(height: 8),
          _buildConfirmationDetail('Availability', availabilityController.text),
          _buildConfirmationDetail('Hourly Rate', '\$${hourlyRateController.text}'),
          _buildConfirmationDetail('Preferred Hours', preferredHoursController.text),
        ]);
      default:
        return const SizedBox();
    }
  }

  Widget _buildDatePickerField(
      BuildContext context, String labelText, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GestureDetector(
        onTap: () => _selectBirthDate(context),
        child: AbsorbPointer(
          child: TextFormField(
            controller: ageController,
            decoration: InputDecoration(
              labelText: labelText,
              labelStyle: GoogleFonts.poppins(
                color: const Color(0xFF1C59D2).withOpacity(0.7),
              ),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF1C59D2),
              ),
              suffixIcon: const Icon(
                Icons.calendar_today,
                color: Color(0xFF1C59D2),
              ),
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
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            ),
            style: GoogleFonts.poppins(
              color: const Color(0xFF1C59D2),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your birth date';
              }
              // Assuming the age is calculated and stored in the controller as a string
              int? age = int.tryParse(value);
              if (age == null || age < 18) {
                return 'You must be at least 18 years old';
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...children.map((child) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: child,
            )),
      ],
    );
  }

  Widget _buildConfirmationDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '$label: $value',
        style: GoogleFonts.lato(fontSize: 16, color: Colors.grey.shade800),
      ),
    );
  }

  void _nextPage() {
    if (_formKey.currentState!.validate()) {
      if (_currentPage < _pages.length - 1) {
        setState(() {
          _currentPage++;
        });
      } else {
        _submitForm();
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  String formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(date);
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
          body: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1C59D2),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                child: Column(
                  children: [
                    // Progress Section
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => Container(
                            width: 70,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: index <= _currentPage
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Page Title
                    Text(
                      _pages[_currentPage],
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Form Content
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
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _buildPageContent(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Navigation Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentPage > 0)
                          _buildNavigationButton(
                            onPressed: _previousPage,
                            text: 'Back',
                            icon: Icons.arrow_back,
                          ),
                        if (_currentPage > 0) const Spacer(),
                        _buildNavigationButton(
                          onPressed: _nextPage,
                          text:
                              _currentPage == _pages.length - 1 ? 'Submit' : 'Next',
                          icon: _currentPage == _pages.length - 1
                              ? Icons.check
                              : Icons.arrow_forward,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
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
          Icon(icon),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      style: GoogleFonts.poppins(
        color: const Color(0xFF1C59D2),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: const Color(0xFF1C59D2).withOpacity(0.7),
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF1C59D2),
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
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
