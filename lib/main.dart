import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'screens/main_navigator_screen.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  runApp(const UniversalRemoteApp());
}

class UniversalRemoteApp extends StatelessWidget {
  const UniversalRemoteApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, child) {
        return MaterialApp(
          title: 'Universal Remote',
          debugShowCheckedModeBanner: false,
          themeMode: currentThemeMode,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            fontFamily: 'Poppins',
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.grey[100],
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 1,
            ),
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            fontFamily: 'Poppins',
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.grey[900],
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey[850],
              foregroundColor: Colors.white,
              elevation: 1,
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/home': (context) => MainNavigatorScreen(themeNotifier: themeNotifier),
          },
        );
      },
    );
  }
}
