import 'package:flutter/material.dart';
import 'package:pelada_chori/screens/configuracoes_page.dart';
import 'package:pelada_chori/screens/votacao_page.dart';
import 'package:pelada_chori/screens/meus_dados_page.dart';
import 'package:pelada_chori/screens/estatisticas_page.dart';
import 'package:pelada_chori/screens/sorteio_page.dart';
import 'package:pelada_chori/widgets/home_highlights_carousel.dart';
import 'package:pelada_chori/services/auth_service.dart'; // <-- novo
import 'package:pelada_chori/widgets/app_version_text.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

void _showEmBreve(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => const AlertDialog(
      title: Text('Ops!'),
      content: Text('Funcionalidade será disponibilizada em breve...'),
    ),
  );
}


class _HomePageState extends State<HomePage> {
  bool expandido = true;

  static const String kLogoUrl =
      'https://dapis-fotos-publicas.s3.us-east-2.amazonaws.com/logo_pelada.png';

  List<Map<String, dynamic>> getBotoesExtras(BuildContext context) => [
        {
          'label': 'Meus Dados',
          'icon': Icons.person,
          'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MeusDadosPage()),
          ),
        },
        {
          'label': 'Configurações', 
          'icon': Icons.settings, 
          'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ConfiguracoesPage()),
           ),
         }, 
        {
          'label': 'Sair', 
          'icon': Icons.logout, 
          'onTap': () => _confirmarLogout(context),},
      ];
  Future<void> _confirmarLogout(BuildContext context) async {
  final cs = Theme.of(context).colorScheme;

  final confirmou = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => AlertDialog(
      title: const Text('Sair'),
      content: const Text('Deseja realmente sair da sua conta?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: cs.errorContainer,
            foregroundColor: cs.onErrorContainer,
          ),
          child: const Text('Sair'),
        ),
      ],
    ),
  );

  if (confirmou == true) {
    // 1) abre loading modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // 2) faz logout (chama backend + limpa token)
    await AuthService.logout();

    // 3) fecha o loading
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // fecha o diálogo de loading
    }

    // 4) navega para login limpando a pilha
        if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
          arguments: {'justLoggedOut': true},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final List<Map<String, dynamic>> botoesFixos = [
      {
        'label': 'Votação',
        'icon': Icons.groups,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VotacaoPage()),
        ),
      },
      {
        'label': 'Sorteio',
        'icon': Icons.format_list_bulleted,
        'onTap': () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SorteioPage()),
          );
        },
      },
      {
        'label': 'Estatísticas', 
        'icon': Icons.show_chart, 
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EstatisticasPage()),
        ),
        },
    ];

    final botoes = [...botoesFixos, if (expandido) ...getBotoesExtras(context)];

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.network(
            kLogoUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Image.asset('assets/logo_pelada.png', fit: BoxFit.contain),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Icon(Icons.menu, color: cs.primary),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // GRID
              GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: botoes.map((btn) {
                  return GestureDetector(
                    onTap: btn['onTap'],
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: cs.primary),
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).cardColor, // integra com tema
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(btn['icon'], size: 30, color: cs.onSurface),
                          const SizedBox(height: 8),
                          Text(btn['label'], style: TextStyle(color: cs.onSurface)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              // COLAPSE
              Center(
                child: IconButton(
                  onPressed: () => setState(() => expandido = !expandido),
                  iconSize: 28,
                  color: cs.primary,
                  icon: Icon(expandido ? Icons.expand_less : Icons.expand_more),
                ),
              ),

              const SizedBox(height: 8),

              // TÍTULO + CARROSSEL
              Text(
                'Destaques do mês',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const HomeHighlightsCarousel(),
              const SizedBox(height: 16),
              const AppVersionText(
                padding: EdgeInsets.only(bottom: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
