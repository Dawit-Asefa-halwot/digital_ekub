import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const DigitalEkubApp());
}

/// Root widget of the Digital Ekub application.
/// Enforces global authentication guard: unauthenticated users see SignInScreen,
/// authenticated users see MainScreen.
class DigitalEkubApp extends StatelessWidget {
  const DigitalEkubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Ekub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: ListenableBuilder(
        listenable: AuthService.instance,
        builder: (context, child) {
          if (!AuthService.instance.isAuthenticated) {
            return const SignInScreen();
          }
          return const MainScreen();
        },
      ),
    );
  }
}
