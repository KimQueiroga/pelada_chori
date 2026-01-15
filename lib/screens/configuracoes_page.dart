import 'package:flutter/material.dart';

import '../main.dart' show themeController;
import 'package:pelada_chori/widgets/app_version_text.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.primary.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mode = themeController.mode;
    final isSystem = mode == ThemeMode.system;
    final isDark = mode == ThemeMode.dark ||
        (isSystem &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                cs.background,
                cs.surface.withOpacity(0.98),
                cs.background,
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withOpacity(0.65),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(Icons.settings, size: 44, color: cs.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Preferências',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ajuste a aparência e configurações do app',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 16),
                _sectionCard(
                  context: context,
                  title: 'Aparência',
                  child: SwitchListTile(
                    value: isDark,
                    onChanged: (v) async {
                      await themeController.toggleDark(v);
                      if (mounted) setState(() {});
                    },
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Modo escuro'),
                    subtitle: Text(
                      'Use um tema mais suave para ambientes escuros',
                      style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.dark_mode, color: cs.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  context: context,
                  title: 'Sobre',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.info_outline, color: cs.primary),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Versão do app',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const AppVersionText(
                        textAlign: TextAlign.left,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
