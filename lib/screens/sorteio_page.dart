import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../models/sorteio_simplificado_model.dart';
import 'selecionar_jogadores_page.dart';
import 'sorteio_detalhe_page.dart';
import '../models/sorteio_detalhe_model.dart';
import '../../utils/app_date.dart';
import 'rascunhos_dia_page.dart';

class SorteioPage extends StatefulWidget {
  const SorteioPage({Key? key}) : super(key: key);

  @override
  State<SorteioPage> createState() => _SorteioPageState();
}

class _SorteioPageState extends State<SorteioPage> {
  List<SorteioSimplificadoModel> _sorteios = [];
  bool _loading = true;

  // rascunhos hoje?
  bool _temRascunhosHoje = false;

  // votos (id => total) e votantes (id => lista)
  Map<int, int> _votosHoje = {};
  Map<int, List<Map<String, dynamic>>> _votantesPorSorteio = {};

  int get _totalVotosHoje =>
      _votosHoje.values.fold<int>(0, (prev, e) => prev + e);

  @override
  void initState() {
    super.initState();
    _carregarTudo();
  }

  Future<void> _carregarTudo() async {
    setState(() => _loading = true);
    try {
      await _carregarSorteios(); // precisa ser antes para termos os IDs
      await Future.wait([
        _carregarResumoVotos(),
        _carregarDetalhesDeCadaSorteio(), // <- detalhe=1 por sorteio
      ]);
      await _verificarRascunhosHoje();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _carregarSorteios() async {
    final sorteios = await ApiService.getSorteiosAtivos();
    if (!mounted) return;
    setState(() {
      _sorteios = sorteios;
    });
  }

  Future<void> _carregarResumoVotos() async {
    try {
      final resumo = await ApiService.getResumoVotosHoje();
      if (!mounted) return;
      setState(() => _votosHoje = resumo);
    } catch (_) {}
  }

  Future<void> _carregarDetalhesDeCadaSorteio() async {
    if (_sorteios.isEmpty) return;
    try {
      final results = await Future.wait(
        _sorteios.map((s) => ApiService.getVotosDetalheSorteio(s.id)),
      );
      final byId = <int, List<Map<String, dynamic>>>{};
      final totals = Map<int, int>.from(_votosHoje);

      for (var i = 0; i < _sorteios.length; i++) {
        final s = _sorteios[i];
        final r = results[i];
        byId[s.id] = (r['votos'] as List).cast<Map<String, dynamic>>();
        totals[s.id] = r['total'] as int;
      }

      if (!mounted) return;
      setState(() {
        _votantesPorSorteio = byId;
        _votosHoje = totals;
      });
    } catch (_) {
      // silencioso por enquanto (UI ainda funciona com o resumo)
    }
  }

  Future<void> _verificarRascunhosHoje() async {
    try {
      final rasc = await ApiService.getRascunhosDoDia();
      if (!mounted) return;
      setState(() => _temRascunhosHoje = rasc.isNotEmpty);
    } catch (_) {}
  }

  void _abrirRascunhos() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RascunhosDiaPage()),
    ).then((_) => _carregarTudo());
  }

  void _abrirNovoSorteio() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SelecionarJogadoresPage()),
    ).then((_) => _carregarTudo());
  }

  void _abrirMenuAcoes() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Criar novo sorteio'),
                onTap: () {
                  Navigator.pop(context);
                  _abrirNovoSorteio();
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Rascunhos de hoje'),
                enabled: _temRascunhosHoje,
                subtitle: _temRascunhosHoje
                    ? const Text('Selecione a dupla vencedora')
                    : const Text('Não há rascunhos hoje'),
                onTap: _temRascunhosHoje
                    ? () {
                        Navigator.pop(context);
                        _abrirRascunhos();
                      }
                    : null,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ---------- helpers ----------

  String _initialFromName(String? nome) {
    final n = (nome ?? '').trim();
    if (n.isEmpty) return '?';
    return n.characters.first.toUpperCase();
  }

  Widget _votersFacepile(int sorteioId) {
    final lista = _votantesPorSorteio[sorteioId] ?? const [];
    if (lista.isEmpty) return const SizedBox.shrink();

    final top3 = lista.take(3).toList();

    // Cálculo de largura: 1º avatar = 28px, cada próximo desloca 18px
    final double base = 28.0;
    final double overlap = 18.0;
    final double width = base + (top3.length - 1) * overlap;

    return SizedBox(
      height: 28,
      width: width, // <<< IMPORTANTE: largura finita para a Stack
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < top3.length; i++)
            Positioned(
              left: i * overlap,
              child: CircleAvatar(
                radius: 14,
                backgroundImage: (() {
                  final foto = (top3[i]['jogador_foto'] as String?)?.trim();
                  if (foto != null && foto.isNotEmpty) return NetworkImage(foto);
                  return null;
                })(),
                child: (() {
                  final foto = (top3[i]['jogador_foto'] as String?)?.trim();
                  if (foto != null && foto.isNotEmpty) return null;
                  final nome = (top3[i]['jogador_nome'] ??
                          top3[i]['user_name'] ??
                          '')
                      .toString();
                  return Text(
                    _initialFromName(nome),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  );
                })(),
              ),
            ),
        ],
      ),
    );
  }
  Widget _pollBar({
    required int votosDoSorteio,
    required int votosTotais,
    required VoidCallback onMostrarVotos, // <<< novo
  }) {
    final percent = (votosTotais > 0) ? (votosDoSorteio / votosTotais) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.how_to_vote, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              votosTotais > 0
                  ? '$votosDoSorteio de $votosTotais votos (${(percent * 100).toStringAsFixed(0)}%)'
                  : 'Nenhum voto ainda',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: (votosDoSorteio > 0) ? onMostrarVotos : null,
              icon: const Icon(Icons.people_alt_outlined, size: 18),
              label: const Text('Mostrar votos'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _mostrarVotantesDeSorteio(int sorteioId) async {
    // usa os dados já carregados (_votantesPorSorteio) por enquanto
    final s = _sorteios.firstWhere((e) => e.id == sorteioId);
    final lista = _votantesPorSorteio[sorteioId] ?? const [];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sorteio nº ${s.numero} — Votantes',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (lista.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Ainda não há votos.'),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final v = lista[i];
                      final nome = (v['jogador_nome'] ?? v['user_name'] ?? 'Jogador').toString();
                      final foto = (v['jogador_foto'] as String?)?.trim();
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              (foto != null && foto.isNotEmpty) ? NetworkImage(foto) : null,
                          child: (foto == null || foto.isEmpty)
                              ? Text(_initialFromName(nome))
                              : null,
                        ),
                        title: Text(nome),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- item ----------

  Widget _buildSorteioItem(SorteioSimplificadoModel sorteio) {
    final dataFormatada = AppDate.brFromApi(sorteio.data);
    final votosEste = _votosHoje[sorteio.id] ?? 0;

    return GestureDetector(
      onTap: () async {
        final detalhe = await ApiService.getSorteioDetalhe(sorteio.id);
        if (!mounted) return;

        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SorteioDetalhePage(sorteio: detalhe)),
        );

        if (result == true) {
          await _carregarTudo();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seu voto foi registrado.')),
          );
        }
      },
      child: Stack(
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // cabeçalho
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Sorteio nº ${sorteio.numero}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (votosEste > 0) _votersFacepile(sorteio.id),
                      const SizedBox(width: 8),
                      if (votosEste > 0)
                        Chip(
                          label: Text('$votosEste'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Data: $dataFormatada'),
                  if (sorteio.descricao.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        sorteio.descricao,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),

                  // barra estilo "enquete" (usa totais do dia)
                  if (_votosHoje.isNotEmpty)
                    _pollBar(
                      votosDoSorteio: votosEste,
                      votosTotais: _totalVotosHoje,
                      onMostrarVotos: () => _mostrarVotantesDeSorteio(sorteio.id), // <<< aqui
                    ),

                  const Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          // selo "ABERTO"
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: const Text(
                'ABERTO',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- BUILD ----------

  @override
  Widget build(BuildContext context) {
    final bodyList = _loading
        ? const Center(child: CircularProgressIndicator())
        : _sorteios.isEmpty
            ? const Center(child: Text('Nenhum sorteio ativo encontrado.'))
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: _sorteios.length,
                itemBuilder: (context, index) => _buildSorteioItem(_sorteios[index]),
              );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sorteios Ativos'),
        actions: [
          IconButton(
            tooltip: 'Rascunhos de hoje',
            icon: const Icon(Icons.description_outlined),
            onPressed: _abrirRascunhos,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregarTudo,
        child: Column(
          children: [
            if (_temRascunhosHoje)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Rascunhos de hoje disponíveis'),
                    subtitle: const Text('Escolha a dupla vencedora para abrir votação'),
                    trailing: TextButton(
                      onPressed: _abrirRascunhos,
                      child: const Text('Abrir'),
                    ),
                  ),
                ),
              ),
            Expanded(child: bodyList),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Novo Sorteio'),
        onPressed: _abrirMenuAcoes,
      ),
    );
  }
}
