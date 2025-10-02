import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'package:pelada_chori/screens/votacao_page.dart';
import 'package:pelada_chori/screens/meus_dados_page.dart';
import 'package:pelada_chori/screens/sorteio_page.dart';
import 'package:pelada_chori/widgets/home_highlights_carousel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
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
        {'label': 'Configurações', 'icon': Icons.settings, 'onTap': () {}},
        {'label': 'Sair', 'icon': Icons.logout, 'onTap': () {}},
      ];

  @override
  Widget build(BuildContext context) {
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
      {'label': 'Estatísticas', 'icon': Icons.show_chart, 'onTap': () {}},
    ];

    final botoes = [...botoesFixos, if (expandido) ...getBotoesExtras(context)];

    return Scaffold(
      backgroundColor: AppColors.background, // <- fundo do app
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
        actions: const [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Icon(Icons.menu, color: AppColors.primary),
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
                        border: Border.all(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.background, // mantém identidade visual
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(btn['icon'], size: 30, color: AppColors.textDark),
                          const SizedBox(height: 8),
                          Text(btn['label'], style: const TextStyle(color: AppColors.textDark)),
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
                  color: AppColors.primary,
                  icon: Icon(expandido ? Icons.expand_less : Icons.expand_more),
                ),
              ),

              const SizedBox(height: 8),

              // TÍTULO + CARROSSEL
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Destaques do mês',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textDark),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const HomeHighlightsCarousel(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
