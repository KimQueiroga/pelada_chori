import 'package:flutter/material.dart';
import '../main.dart' show themeController; // acessa o controller global
import 'package:pelada_chori/widgets/app_version_text.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = themeController.mode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Modo escuro'),
            value: isDark,
            onChanged: (v) async {
              await themeController.toggleDark(v);
              setState(() {});
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          const AppVersionText(
            padding: EdgeInsets.symmetric(vertical: 24),
          ),
          // Opcional: 3 escolhas (Sistema, Claro, Escuro)
          // ListTile(...)
        ],
      ),
    );
  }
}
