import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homemaster/homeowner screens/homeowner_registration_page.dart';
import 'package:homemaster/screens/login_page.dart';
import '../reusable/my_button.dart';
import '../reusable/wave.dart';
import '../homeservice provider screens/home_service_provider_registration.dart'; // Import the home service provider page// Import the homeowner page
import 'package:firebase_auth/firebase_auth.dart';
import '../authentication/auth.dart'; // Add this import
import '../homeservice provider screens/home_service_provider_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homemaster/homeowner screens/home_owner_dashboard.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  // Add this method to handle navigation
  Future<void> _handleServiceProviderNavigation(BuildContext context) async {
    final auth = Auth();
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      final hasProfile = await auth.hasCompletedProfile(user.uid);
      
      if (!context.mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => hasProfile 
              ? const HomeServiceProviderDashboard()
              : const HomeServiceProviderPage(),
        ),
      );
    }
  }

  // Add this method to handle homeowner navigation
  Future<void> _handleHomeownerNavigation(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final docSnapshot = await FirebaseFirestore.instance
          .collection('homeowners')
          .doc(user.uid)
          .get();

      if (!context.mounted) return;

      if (docSnapshot.exists) {
        // User has already registered, go directly to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeOwnerDashboard(),
          ),
        );
      } else {
        // First time user, go to registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeownerRegistrationPage(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor:
            const Color(0xFF1C59D2), // Teal background for consistency
        body: Stack(children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1C59D2),
                  Color(0xFFFE6A6A),
                  Color(0xFFFEC260),
                ],
                stops: [0.1, 0.5, 0.9],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: WavePainter(),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Form(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Select Your Role',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),

                        // Role Selection Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Home Service Provider Role
                            _buildRoleOption(
                              context,
                              'assets/homeservice.png',
                              'Service Provider',
                              const HomeServiceProviderPage(),
                            ),

                            // Homeowner Role
                            _buildRoleOption(
                              context,
                              'assets/homeowner.png',
                              'Homeowner',
                              const HomeownerRegistrationPage(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Option to return to login
                        MyButton(
                          gradientColors: const [
                            Colors.orange,
                            Color.fromRGBO(238, 68, 145, 1),
                          ],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          color: Colors.white,
                          child: Text(
                            'Back',
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ]));
  }

  // Function to build each role option
  Widget _buildRoleOption(
    BuildContext context,
    String imagePath,
    String roleText,
    Widget navigateToPage,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Check which role was selected
          if (navigateToPage is HomeServiceProviderPage) {
            _handleServiceProviderNavigation(context);
          } else if (navigateToPage is HomeownerRegistrationPage) {
            _handleHomeownerNavigation(context);
          }
        },
        child: Column(
          children: [
            // Role Image Stack Container
            Stack(
              alignment: Alignment.center,
              children: [
                _roleBox(),
                Center(
                  child: Image.asset(
                    imagePath,
                    height: 150,
                    width: 150,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Role Text
            Text(
              roleText,
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to create a role box
  Widget _roleBox() {
    return Container(
      width: 100,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
    );
  }
}
