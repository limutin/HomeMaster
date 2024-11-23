import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:lottie/lottie.dart';
import 'package:homemaster/screens/terms_and_conditions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'login_page.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  late Future<bool> _connectionCheck;
  static const String TERMS_ACCEPTED_KEY = 'terms_accepted';

  @override
  void initState() {
    super.initState();
    _connectionCheck = checkConnectivity();
  }

  Future<bool> checkConnectivity() async {
    await Future.delayed(const Duration(seconds: 3));

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    final hasInternetAccess = await InternetConnectionChecker().hasConnection;
    if (hasInternetAccess && mounted) {
      // Check if terms have been accepted
      final prefs = await SharedPreferences.getInstance();
      final termsAccepted = prefs.getBool(TERMS_ACCEPTED_KEY) ?? false;

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => termsAccepted
                ? const LoginPage()
                : const TermsAndConditionsScreen(),
          ),
        );
      });
    }

    return hasInternetAccess;
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          'assets/loading.json',
          width: 200,
          height: 200,
        ),
        const SizedBox(height: 20),
        Text(
          'Checking connection...',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildNoInternetState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          'assets/no_internet.json',
          width: 200,
          height: 200,
        ),
        const SizedBox(height: 20),
        Text(
          'No Internet Connection',
          style: GoogleFonts.roboto(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Please check your connection and try again',
          style: GoogleFonts.roboto(
            color: Colors.black,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _connectionCheck = checkConnectivity();
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1C59D2),
            padding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 15,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            'Retry',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          'assets/check_animation.json',
          width: 100,
          height: 100,
        ),
        const SizedBox(height: 20),
        Text(
          'Connected!',
          style: GoogleFonts.roboto(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: FutureBuilder<bool>(
              future: _connectionCheck,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (snapshot.hasError || snapshot.data == false) {
                  return _buildNoInternetState();
                }

                return _buildConnectedState();
              },
            ),
          ),
        ),
      ),
    );
  }
}
