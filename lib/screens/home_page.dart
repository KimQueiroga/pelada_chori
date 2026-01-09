import 'package:flutter/material.dart';
import 'package:pelada_chori/screens/configuracoes_page.dart';
import 'package:pelada_chori/screens/estatisticas_page.dart';
import 'package:pelada_chori/screens/meus_dados_page.dart';
import 'package:pelada_chori/screens/sorteio_page.dart';
import 'package:pelada_chori/screens/votacao_page.dart';
import 'package:pelada_chori/services/api_service.dart';
import 'package:pelada_chori/services/auth_service.dart';
import 'package:pelada_chori/widgets/app_version_text.dart';
import 'package:pelada_chori/widgets/home_highlights_carousel.dart';

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
  int _partidasHoje = 0;
  bool _statusCarregando = true;
  String? _statusErro;

  static const String kLogoUrl =
      'https://dapis-fotos-publicas.s3.us-east-2.amazonaws.com/logo_pelada.png';

  @override
  void initState() {
    super.initState();
    _carregarStatusDia();
  }

  Future<void> _carregarStatusDia() async {
    if (mounted) {
      setState(() {
        _statusCarregando = true;
        _statusErro = null;
      });
    }

    try {
      final res = await ApiService.getExibirDoDia();
      final sorteios = res.sorteios;

      var total = 0;
      for (final s in sorteios) {
        final partidas = await ApiService.getPartidasDoSorteio(s.id);
        total += partidas.length;
      }

      if (!mounted) return;
      setState(() {
        _partidasHoje = total;
        _statusCarregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusErro = 'Status indisponível';
        _statusCarregando = false;
      });
    }
  }

  List<Map<String, dynamic>> getBotoesExtras(BuildContext context) => [
        {
          'label': 'Meus dados',
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
          'onTap': () => _confirmarLogout(context),
        },
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await AuthService.logout();

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
          arguments: {'justLoggedOut': true},
        );
      }
    }
  }

  Widget _buildAtalho(Map<String, dynamic> btn, ColorScheme cs) {
    return InkWell(
      onTap: btn['onTap'],
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.primary.withOpacity(0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(btn['icon'], size: 22, color: cs.primary),
            ),
            const SizedBox(height: 10),
            Text(
              btn['label'],
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(ColorScheme cs) {
    final IconData icon;
    final String texto;

    if (_statusCarregando) {
      icon = Icons.hourglass_top;
      texto = 'Carregando status do dia...';
    } else if (_statusErro != null) {
      icon = Icons.info_outline;
      texto = _statusErro!;
    } else {
      icon = Icons.sports_soccer;
      texto = 'Partidas hoje: $_partidasHoje';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface),
            ),
          ),
          IconButton(
            tooltip: 'Atualizar',
            icon: Icon(Icons.refresh, size: 18, color: cs.primary),
            onPressed: _statusCarregando ? null : _carregarStatusDia,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(ColorScheme cs, List<Map<String, dynamic>> botoesFixos) {
    final itens = [...botoesFixos, ...getBotoesExtras(context)];

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Image.network(
                    kLogoUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/logo_pelada.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pelada Chori',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Atalhos e conta',
                        style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: cs.onSurface.withOpacity(0.08)),
            Expanded(
              child: ListView(
                children: itens.map((btn) {
                  final isLogout = btn['label'] == 'Sair';
                  final color = isLogout ? cs.error : cs.onSurface;
                  return ListTile(
                    leading: Icon(btn['icon'], color: color),
                    title: Text(
                      btn['label'],
                      style: TextStyle(
                        color: color,
                        fontWeight: isLogout ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      btn['onTap']();
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mostrarBanner =
        _statusCarregando || _statusErro != null || _partidasHoje > 0;

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
          Builder(
            builder: (ctx) => IconButton(
              tooltip: 'Menu',
              icon: Icon(Icons.menu, color: cs.primary),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: _buildDrawer(cs, botoesFixos),
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
                if (mostrarBanner) _buildStatusBanner(cs),
                if (mostrarBanner) const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
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
                    children: [
                      Row(
                        children: [
                          Text(
                            'Acesso rápido',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => setState(() => expandido = !expandido),
                            icon: Icon(
                              expandido ? Icons.expand_less : Icons.expand_more,
                              color: cs.primary,
                            ),
                            label: Text(
                              expandido ? 'Menos' : 'Mais',
                              style: TextStyle(color: cs.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: botoes.map((btn) => _buildAtalho(btn, cs)).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Destaques do mês',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _showEmBreve(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        'Ver todos',
                        style: TextStyle(color: cs.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const HomeHighlightsCarousel(),
                const SizedBox(height: 16),
                const AppVersionText(
                  padding: EdgeInsets.only(bottom: 8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
