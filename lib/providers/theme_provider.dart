import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider(this._isDarkMode);

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = !_isDarkMode;
    await prefs.setBool('darkMode', _isDarkMode);
    notifyListeners();
  }

  ThemeData get themeData {
    return _isDarkMode ? _darkTheme : _lightTheme;
  }

  static final _lightTheme = ThemeData(
    primaryColor: const Color(0xFF1C59D2),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF1C59D2)),
      titleTextStyle: TextStyle(
        color: Color(0xFF1C59D2),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF1C59D2),
      secondary: const Color(0xFF1C59D2).withOpacity(0.1),
      surface: Colors.white,
    ),
    cardColor: Colors.white,
    dividerColor: Colors.grey.withOpacity(0.1),
  );

  static final _darkTheme = ThemeData(
    primaryColor: const Color(0xFF1C59D2),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF1C59D2)),
      titleTextStyle: TextStyle(
        color: Color(0xFF1C59D2),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF1C59D2),
      secondary: const Color(0xFF1C59D2).withOpacity(0.1),
      surface: const Color(0xFF1E1E1E),
    ),
    cardColor: const Color(0xFF1E1E1E),
    dividerColor: Colors.white.withOpacity(0.1),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
    ),
  );
}
