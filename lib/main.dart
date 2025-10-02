import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/home_page.dart';
import 'theme/app_theme.dart';
import 'controllers/theme_controller.dart';
import 'services/theme_prefs.dart';

late ThemeController themeController; // simples acesso global

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialMode = await ThemePrefs.load();
  themeController = ThemeController(initialMode);

  runApp(const PeladaChoriApp());
}

class PeladaChoriApp extends StatelessWidget {
  const PeladaChoriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Pelada Chori',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.mode, // ← controla o modo
          initialRoute: '/',
          routes: {
            '/': (_) => const LoginPage(),
            '/cadastro': (_) => const RegisterPage(),
            '/home': (_) => const HomePage(),
          },
        );
      },
    );
  }
}
