import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homemaster/screens/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  Future<void> _handleAccept(BuildContext context) async {
    // Save terms acceptance
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terms_accepted', true);

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
    }
  }

  void _handleDecline() {
    // Exit the app
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _handleDecline();
        return false;
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1C59D2),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/icon/icon.png',
                    height: 100,
                    width: 100,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Terms and Conditions',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Welcome to HomeMaster'),
                            _buildText(
                              'By using our app, you agree to these terms and conditions. Please read them carefully.',
                            ),
                            
                            _buildSectionTitle('1. Service Description'),
                            _buildText(
                              'HomeMaster is a platform connecting homeowners with service providers for various home maintenance and improvement services.',
                            ),
                            
                            _buildSectionTitle('2. User Responsibilities'),
                            _buildText(
                              '• Users must provide accurate information\n'
                              '• Users must maintain account security\n'
                              '• Users must not misuse the platform\n'
                              '• Users must be 18 years or older',
                            ),
                            
                            _buildSectionTitle('3. Privacy Policy'),
                            _buildText(
                              'We collect and process personal data as described in our Privacy Policy:\n\n'
                              '• Contact information\n'
                              '• Service history\n'
                              '• Payment information\n'
                              '• Location data\n\n'
                              'Your data is protected and will only be used to improve our services.',
                            ),
                            
                            _buildSectionTitle('4. Service Provider Terms'),
                            _buildText(
                              '• Must maintain professional standards\n'
                              '• Must have required licenses and insurance\n'
                              '• Must complete work as agreed\n'
                              '• Must maintain accurate availability',
                            ),
                            
                            _buildSectionTitle('5. Homeowner Terms'),
                            _buildText(
                              '• Must provide accurate service requirements\n'
                              '• Must provide safe working conditions\n'
                              '• Must pay for services as agreed\n'
                              '• Must communicate professionally',
                            ),
                            
                            _buildSectionTitle('6. Liability'),
                            _buildText(
                              'HomeMaster serves as a platform connecting users and is not liable for:\n'
                              '• Quality of work performed\n'
                              '• Accidents or damages\n'
                              '• Payment disputes\n'
                              '• User conflicts',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleDecline,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Decline',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleAccept(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1C59D2),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Accept',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1C59D2),
        ),
      ),
    );
  }

  Widget _buildText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.black87,
          height: 1.5,
        ),
      ),
    );
  }
}
