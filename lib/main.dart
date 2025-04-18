import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/home_page.dart';
import 'theme/colors.dart';

void main() {
  runApp(const PeladaChoriApp());
}

class PeladaChoriApp extends StatelessWidget {
  const PeladaChoriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pelada Chori',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const LoginPage(),
        '/cadastro': (_) => const RegisterPage(),
        '/home': (_) => const HomePage(),
      },
    );
  }
}
