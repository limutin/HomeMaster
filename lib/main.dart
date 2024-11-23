import 'package:flutter/material.dart';
import 'package:homemaster/homeowner%20screens/owner_settings_page.dart';
import 'package:homemaster/screens/terms_and_conditions.dart';
//import 'package:homemaster/screens/loading_screen.dart';
import 'homeowner screens/home_owner_dashboard.dart';
import 'homeservice provider screens/profile_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/theme_provider.dart';
import 'firebase_options.dart';
import 'homeservice provider screens/settings_page.dart';
import 'screens/login_page.dart';
import 'homeservice provider screens/schedule_page.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'homeowner screens/book_service_page.dart';
import 'homeowner screens/notifications_page.dart';
import 'homeservice provider screens/provider_notifications_page.dart';
import 'package:flutter/foundation.dart';
import 'admin/web_admin_login.dart';
import 'admin/web_admin_dashboard.dart';
import 'screens/chat_list_screen.dart';
import 'screens/chat_screen.dart';
import 'homeowner screens/notifications_screen.dart';
import 'homeowner screens/bookings_page.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize App Check
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.appAttest,
  );

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('darkMode') ?? false;

  // Run the app with the initial theme value
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(isDarkMode),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          routes: {
            '/': (context) => const TermsAndConditionsScreen(),
            '/dashboard': (context) => const HomeOwnerDashboard(),
            '/settings': (context) => const SettingsPage(),
            '/login': (context) => const LoginPage(),
            '/schedule': (context) => const SchedulePage(),
            '/profile': (context) => const ProfilePage(),
            '/user_settings': (context) => const OwnerSettingsPage(),
            '/book_service': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
              return BookServicePage(
                serviceId: args['serviceId'],
                serviceData: args['serviceData'],
              );
            },
            '/notifications': (context) => const NotificationsPage(),
            '/notifications_screen': (context) => NotificationsScreen(),
            '/provider_notifications': (context) =>
                const ProviderNotificationsPage(),
            ...kIsWeb
                ? {
                    '/admin/login': (context) => const WebAdminLogin(),
                    '/admin/dashboard': (context) => const WebAdminDashboard(),
                  }
                : {},
            '/messages': (context) => const ChatListScreen(),
            '/chat': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
              return ChatScreen(
                chatRoomId: args['chatRoomId'],
                otherUserName: args['otherUserName'],
                bookingId: args['bookingId'] ?? '',
              );
            },
            '/bookings': (context) => const BookingsPage(),
          },
          theme: themeProvider.themeData,
        );
      },
    );
  }
}
