import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/home_page.dart';

// novo: tema centralizado
import 'theme/app_theme.dart';

void main() {
  runApp(const PeladaChoriApp());
}

class PeladaChoriApp extends StatelessWidget {
  const PeladaChoriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pelada Chori',
      debugShowCheckedModeBanner: false,

      // aplica o tema global (Material 3 + suas cores)
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // se preferir seguir o tema do sistema, use ThemeMode.system
      themeMode: ThemeMode.light,

      initialRoute: '/',
      routes: {
        '/': (_) => const LoginPage(),
        '/cadastro': (_) => const RegisterPage(),
        '/home': (_) => const HomePage(),
      },
    );
  }
}
