// lib/screens/partida_rodando_page.dart
import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../services/api_service.dart';
import '../models/partida_model.dart';

class PartidaRodandoPage extends StatefulWidget {
  final Partida partida;
  const PartidaRodandoPage({super.key, required this.partida});

  @override
  State<PartidaRodandoPage> createState() => _PartidaRodandoPageState();
}

class _PartidaRodandoPageState extends State<PartidaRodandoPage> {
  late Partida _p;

  // cronômetro
  Timer? _ticker;
  Duration _decorrido = Duration.zero;

  // carregamento/ações
  bool _carregando = true;
  bool _acao = false;

  // times / jogadores
  List<Map<String, dynamic>> _playersA = const [];
  List<Map<String, dynamic>> _playersB = const [];

  // gols e contagens por jogador
  List<Map<String, dynamic>> _gols = const [];
  final Map<int, int> _golsPorJogador = {};
  final Map<int, int> _assistsPorJogador = {};
  bool _wakeLockAtivo = false;
  bool _wakeLockAvisado = false;

  @override
  void initState() {
    super.initState();
    _p = widget.partida;
    unawaited(_syncWakeLock());
    _bootstrap();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    if (_wakeLockAtivo) {
      unawaited(WakelockPlus.disable());
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _carregando = true);
    try {
      await Future.wait([_recarregarPartida(), _carregarTimes()]);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // ---------- carregamento tolerante ao shape do payload ----------
  Future<void> _recarregarPartida() async {
    final resp = await ApiService.getPartidaDetalhe(_p.id);
    final root = (resp as Map).cast<String, dynamic>();

    // pode vir {partida:{...}, gols:[...]} OU diretamente {...}
    final Map<String, dynamic> pMap = (root['partida'] is Map)
        ? (root['partida'] as Map).cast<String, dynamic>()
        : root;

    final List<Map<String, dynamic>> gols = ((root['gols'] as List?) ??
            (pMap['gols'] as List?) ??
            const [])
        .map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>())
        .toList();

    final p = Partida.fromJson(pMap);

    if (!mounted) return;
    setState(() {
      _p = p;
      _gols = gols;
      _rebuildStats();
      _setupCronometro();
    });
  }

  Future<void> _carregarTimes() async {
    final times = await ApiService.getTimesDoSorteio(_p.sorteioId);

    Map<String, dynamic> _byId(int id) {
      final t = times.cast<Map<String, dynamic>>().firstWhere(
            (x) => x['id'] == id,
            orElse: () => <String, dynamic>{},
          );
      return t;
    }

    List<Map<String, dynamic>> _toPlayers(Map<String, dynamic> t) =>
        ((t['jogadores'] as List?) ?? const [])
            .map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>())
            .toList();

    if (!mounted) return;
    setState(() {
      _playersA = _toPlayers(_byId(_p.timeAId));
      _playersB = _toPlayers(_byId(_p.timeBId));
    });
  }

  void _rebuildStats() {
    _golsPorJogador.clear();
    _assistsPorJogador.clear();
    for (final g in _gols) {
      final autor = g['jogador_id'] as int?;
      final assist = g['assist_jogador_id'] as int?;
      if (autor != null) {
        _golsPorJogador.update(autor, (v) => v + 1, ifAbsent: () => 1);
      }
      if (assist != null) {
        _assistsPorJogador.update(assist, (v) => v + 1, ifAbsent: () => 1);
      }
    }
  }

  // ---------------- cronômetro ----------------
  void _setupCronometro() {
    _ticker?.cancel();

    if (_p.isLive && _p.iniciadaEm != null) {
      setState(() => _decorrido = DateTime.now().difference(_p.iniciadaEm!));
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _decorrido = DateTime.now().difference(_p.iniciadaEm!));
      });
      unawaited(_syncWakeLock());
      return;
    }

    if (_p.isFT && _p.iniciadaEm != null && _p.encerradaEm != null) {
      _decorrido = _p.encerradaEm!.difference(_p.iniciadaEm!);
    } else {
      _decorrido = Duration.zero;
    }

    unawaited(_syncWakeLock());
  }

  Future<void> _syncWakeLock({bool force = false}) async {
    final deveManterTelaLigada = _p.isLive;
    if (!force && deveManterTelaLigada == _wakeLockAtivo) return;
    try {
      if (deveManterTelaLigada) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
      final ativo = await WakelockPlus.enabled;
      if (!mounted) return;
      if (_wakeLockAtivo != ativo) {
        setState(() => _wakeLockAtivo = ativo);
      }
      if (deveManterTelaLigada && !ativo) {
        _avisarWakeLockNaoSuportado();
      }
    } catch (_) {
      if (!deveManterTelaLigada) return;
      _avisarWakeLockNaoSuportado();
    }
  }

  void _avisarWakeLockNaoSuportado() {
    if (!kIsWeb || _wakeLockAvisado || !mounted) return;
    _wakeLockAvisado = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Seu navegador nao permite manter a tela ligada automaticamente. Tente ativar pelo icone ou mantenha a tela ativa manualmente.',
        ),
        action: SnackBarAction(
          label: 'Tentar',
          onPressed: _solicitarWakeLockManual,
        ),
      ),
    );
  }

  Future<void> _solicitarWakeLockManual() async {
    await _syncWakeLock(force: true);
  }

  String _fmt(Duration d) {
    final dd = d.isNegative ? Duration.zero : d;
    final m = dd.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = dd.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ---------------- ações ----------------
  Future<void> _iniciar() async {
    setState(() => _acao = true);
    try {
      final p = await ApiService.iniciarPartida(_p.id);
      if (!mounted) return;
      setState(() {
        _p = p;
        _setupCronometro();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Falha: $e')));
    } finally {
      if (mounted) setState(() => _acao = false);
    }
  }

  Future<void> _encerrar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Encerrar partida?'),
        content: const Text('Confirma encerrar agora?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Encerrar')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _acao = true);
    try {
      final p = await ApiService.encerrarPartida(_p.id);
      if (!mounted) return;
      setState(() {
        _p = p;
        _setupCronometro();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partida encerrada.')));
      Navigator.pop(context, true); // volta e força atualizar lista anterior
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _acao = false);
    }
  }

  // ---------------- registrar gol via clique no jogador ----------------
  Future<void> _onTapJogador({
    required int timeId,
    required int autorId,
    required String timeNome,
    required List<Map<String, dynamic>> jogadoresDoTime,
  }) async {
    if (!_p.isLive) return;

    // modal de assistência: seleção + confirmar (não confirma no toque)
    final assistId = await showModalBottomSheet<int?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, __) {
          int? selecionado;
          return StatefulBuilder(builder: (ctx, setSB) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Gol do $timeNome', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Assistência (opcional)', style: Theme.of(context).textTheme.labelLarge),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: [
                        RadioListTile<int?>(
                          value: null,
                          groupValue: selecionado,
                          onChanged: (v) => setSB(() => selecionado = v),
                          title: const Text('Sem assistência'),
                        ),
                        const Divider(height: 1),
                        ...jogadoresDoTime.map((j) {
                          final jid = j['jogador_id'] as int;
                          if (jid == autorId) return const SizedBox.shrink();
                          final apelido = (j['jogador']?['apelido'] ?? j['jogador']?['nome'] ?? 'Jogador').toString();
                          return RadioListTile<int?>(
                            value: jid,
                            groupValue: selecionado,
                            onChanged: (v) => setSB(() => selecionado = v),
                            title: Row(
                              children: [
                                _avatar(j),
                                const SizedBox(width: 8),
                                Expanded(child: Text(apelido, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(ctx, selecionado),
                    icon: const Icon(Icons.check),
                    label: const Text('Confirmar'),
                  ),
                ],
              ),
            );
          });
        },
      ),
    );

    try {
      await ApiService.registrarGol(
        partidaId: _p.id,
        timeId: timeId,
        jogadorId: autorId,
        assistJogadorId: assistId,
      );
      await _recarregarPartida(); // atualiza placar e ícones imediatamente
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  // ---------------- UI helpers ----------------
  Widget _avatar(Map<String, dynamic> pj, {double size = 32}) {
    final foto = (pj['jogador']?['foto'] as String?)?.trim();
    final nick = (pj['jogador']?['apelido'] ?? pj['jogador']?['nome'] ?? '?').toString();
    final initial = (nick.isEmpty ? '?' : nick.characters.first).toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundImage: (foto != null && foto.isNotEmpty) ? NetworkImage(foto) : null,
      child: (foto == null || foto.isEmpty)
          ? Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))
          : null,
    );
  }

  Widget _playerTile({
    required Map<String, dynamic> pj,
    required int timeId,
    required String timeNome,
    required List<Map<String, dynamic>> jogadoresDoTime,
  }) {
    final jid = pj['jogador_id'] as int;
    final apelido = (pj['jogador']?['apelido'] ?? pj['jogador']?['nome'] ?? 'Jogador').toString();
    final gols = _golsPorJogador[jid] ?? 0;
    final asts = _assistsPorJogador[jid] ?? 0;

    return InkWell(
      onTap: () => _onTapJogador(
        timeId: timeId,
        autorId: jid,
        timeNome: timeNome,
        jogadoresDoTime: jogadoresDoTime,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Row(
          children: [
            _avatar(pj),
            const SizedBox(width: 8),
            Expanded(child: Text(apelido, overflow: TextOverflow.ellipsis)),
            if (gols > 0) Row(children: [const Icon(Icons.sports_soccer, size: 18), Text(' $gols')]),
            const SizedBox(width: 6),
            if (asts > 0) Row(children: [const Icon(Icons.checkroom, size: 18), Text(' $asts')]), // “chuteira”
          ],
        ),
      ),
    );
  }

  Widget _teamColumn({
    required String titulo,
    required int placar,
    required List<Map<String, dynamic>> jogadores,
    required int timeId,
  }) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(8),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('$placar', style: const TextStyle(fontSize: 18)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: jogadores.length,
                itemBuilder: (_, i) => _playerTile(
                  pj: jogadores[i],
                  timeId: timeId,
                  timeNome: titulo,
                  jogadoresDoTime: jogadores,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- build ----------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_p.timeANome}  ${_p.placarA} x ${_p.placarB}  ${_p.timeBNome}'),
        actions: [
          if (_p.isLive && kIsWeb && !_wakeLockAtivo)
            IconButton(
              tooltip: 'Manter tela ligada',
              icon: const Icon(Icons.lock_open),
              onPressed: _solicitarWakeLockManual,
            ),
          if (!_p.isLive && !_p.isFT)
            IconButton(
              tooltip: 'Iniciar',
              icon: _acao
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.play_arrow_rounded),
              onPressed: _acao ? null : _iniciar,
            ),
          if (_p.isLive)
            IconButton(
              tooltip: 'Encerrar',
              icon: _acao
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.flag_circle_outlined),
              onPressed: _acao ? null : _encerrar,
            ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 10),
                // cronômetro
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _p.isLive ? _fmt(_decorrido) : (_p.isFT ? 'FT ${_fmt(_decorrido)}' : '00:00'),
                    style: const TextStyle(fontSize: 32, fontFeatures: [FontFeature.tabularFigures()]),
                  ),
                ),
                const SizedBox(height: 8),
                // colunas dos times
                Expanded(
                  child: Row(
                    children: [
                      _teamColumn(
                        titulo: _p.timeANome,
                        placar: _p.placarA,
                        jogadores: _playersA,
                        timeId: _p.timeAId,
                      ),
                      _teamColumn(
                        titulo: _p.timeBNome,
                        placar: _p.placarB,
                        jogadores: _playersB,
                        timeId: _p.timeBId,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
