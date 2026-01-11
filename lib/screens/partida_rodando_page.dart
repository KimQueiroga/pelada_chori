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
  List<Map<String, dynamic>> _playersOrigA = const [];
  List<Map<String, dynamic>> _playersOrigB = const [];
  List<Map<String, dynamic>> _todosJogadores = const [];
  List<Map<String, dynamic>> _substituicoes = const [];
  List<Map<String, dynamic>> _substituicoesTodas = const [];

  // gols e contagens por jogador
  List<Map<String, dynamic>> _gols = const [];
  final Map<int, int> _golsPorJogador = {};
  final Map<int, int> _assistsPorJogador = {};
  bool _acaoSubstituicao = false;
  bool _wakeLockAtivo = false;
  bool _wakeLockAvisado = false;
  bool _golSplashVisible = false;

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
    final results = await Future.wait([
      ApiService.getTimesDoSorteio(_p.sorteioId),
      ApiService.getElencoPartida(_p.id),
    ]);

    final times = results[0] as List<Map<String, dynamic>>;
    final elenco = (results[1] as Map).cast<String, dynamic>();

    List<Map<String, dynamic>> toPlayers(Map<String, dynamic> t) =>
        ((t['jogadores'] as List?) ?? const [])
            .map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>())
            .toList();

    Map<String, dynamic> byId(int id) {
      return times.firstWhere(
        (x) => x['id'] == id,
        orElse: () => <String, dynamic>{},
      );
    }

    List<Map<String, dynamic>> flattenJogadores(List<Map<String, dynamic>> times) {
      final all = <Map<String, dynamic>>[];
      for (final t in times) {
        final timeId = (t['id'] as int?) ?? 0;
        final timeNome = (t['nome'] ?? '').toString();
        final jogadores = (t['jogadores'] as List?) ?? const [];
        for (final j in jogadores) {
          final map = Map<String, dynamic>.from((j as Map).cast<String, dynamic>());
          map['time_id'] = timeId;
          map['time_nome'] = timeNome;
          all.add(map);
        }
      }
      return all;
    }

    if (!mounted) return;
    setState(() {
      _todosJogadores = flattenJogadores(times);
      _playersOrigA = toPlayers(byId(_p.timeAId));
      _playersOrigB = toPlayers(byId(_p.timeBId));
      _aplicarElenco(elenco);
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

  void _aplicarElenco(Map<String, dynamic> elenco) {
    List<Map<String, dynamic>> toPlayers(Map<String, dynamic> t) =>
        ((t['jogadores'] as List?) ?? const [])
            .map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>())
            .toList();

    final timeA = (elenco['time_a'] as Map?)?.cast<String, dynamic>() ?? const {};
    final timeB = (elenco['time_b'] as Map?)?.cast<String, dynamic>() ?? const {};
    final subs = (elenco['substituicoes'] as List?) ?? const [];
    final subsTodas = (elenco['substituicoes_todas'] as List?) ?? subs;

    _playersA = toPlayers(timeA);
    _playersB = toPlayers(timeB);
    _substituicoes = subs
        .map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>())
        .toList();
    _substituicoesTodas = subsTodas
        .map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }

  String _nomeJogador(Map<String, dynamic>? j) {
    if (j == null) return 'Jogador';
    return (j['apelido'] ?? j['nome'] ?? 'Jogador').toString();
  }

  String _nomeJogadorPj(Map<String, dynamic> pj) {
    final j = (pj['jogador'] as Map?)?.cast<String, dynamic>();
    return _nomeJogador(j);
  }

  Map<String, dynamic> _wrapJogador(Map<String, dynamic>? j) {
    return {
      'jogador_id': (j?['id'] as int?) ?? 0,
      'jogador': j ?? <String, dynamic>{},
    };
  }

  List<Map<String, dynamic>> _substituicoesPorTime(
    List<Map<String, dynamic>> subs,
    int timeId,
  ) {
    return subs.where((s) => s['time_id'] == timeId).toList();
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

  String _tempoTexto() {
    if (_p.isLive) return _fmt(_decorrido);
    if (_p.isFT) return 'FT ${_fmt(_decorrido)}';
    return '00:00';
  }

  String _statusLabel() {
    if (_p.isLive) return 'LIVE';
    if (_p.isFT) return 'ENCERRADA';
    return 'AGUARDANDO';
  }

  Color _statusColor(ColorScheme cs) {
    if (_p.isLive) return cs.primary;
    if (_p.isFT) return cs.secondary;
    return cs.outline;
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

  Future<void> _registrarSubstituicao({
    required int timeId,
    required int jogadorSaiId,
    required int jogadorEntraId,
  }) async {
    setState(() => _acaoSubstituicao = true);
    try {
      final elenco = await ApiService.registrarSubstituicao(
        partidaId: _p.id,
        timeId: timeId,
        jogadorSaiId: jogadorSaiId,
        jogadorEntraId: jogadorEntraId,
      );
      if (!mounted) return;
      setState(() => _aplicarElenco(elenco));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _acaoSubstituicao = false);
    }
  }

  Future<void> _desfazerSubstituicao(int substituicaoId) async {
    setState(() => _acaoSubstituicao = true);
    try {
      final elenco = await ApiService.desfazerSubstituicao(
        partidaId: _p.id,
        substituicaoId: substituicaoId,
      );
      if (!mounted) return;
      setState(() => _aplicarElenco(elenco));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _acaoSubstituicao = false);
    }
  }

  Future<void> _abrirSubstituicoes() async {
    if (!_p.isLive) return;

    int? timeId = _p.timeAId;
    int? jogadorSaiId;
    int? jogadorEntraId;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (ctx, scrollController) {
          return StatefulBuilder(builder: (ctx, setSB) {
            final ativosIds = <int>{
              for (final p in _playersA) (p['jogador_id'] as int),
              for (final p in _playersB) (p['jogador_id'] as int),
            };

            final disponiveis = _todosJogadores
                .where((p) => !ativosIds.contains(p['jogador_id'] as int))
                .toList();

            final jogadoresDoTime =
                timeId == _p.timeAId ? _playersA : _playersB;

            if (jogadorSaiId != null &&
                !jogadoresDoTime.any((p) => p['jogador_id'] == jogadorSaiId)) {
              jogadorSaiId = null;
            }
            if (jogadorEntraId != null &&
                !disponiveis.any((p) => p['jogador_id'] == jogadorEntraId)) {
              jogadorEntraId = null;
            }

            final podeConfirmar =
                timeId != null && jogadorSaiId != null && jogadorEntraId != null;
            final theme = Theme.of(ctx);
            final cs = theme.colorScheme;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                top: 12,
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.swap_horiz, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Substituicoes',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar',
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Text(
                    'Troque jogadores durante a partida.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  if (_substituicoes.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ativas',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._substituicoes.map((s) {
                            final timeNome = (s['time_id'] == _p.timeAId)
                                ? _p.timeANome
                                : _p.timeBNome;
                            final sai = _nomeJogador(
                              (s['jogador_sai'] as Map?)?.cast<String, dynamic>(),
                            );
                            final entra = _nomeJogador(
                              (s['jogador_entra'] as Map?)?.cast<String, dynamic>(),
                            );
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cs.outlineVariant),
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                title: Text('$sai -> $entra'),
                                subtitle: Text(timeNome),
                                trailing: TextButton(
                                  onPressed: _acaoSubstituicao
                                      ? null
                                      : () async {
                                          Navigator.pop(ctx);
                                          await _desfazerSubstituicao(s['id'] as int);
                                        },
                                  child: const Text('Desfazer'),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.loop, size: 18, color: cs.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Nova substituicao',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          value: timeId,
                          items: [
                            DropdownMenuItem(
                              value: _p.timeAId,
                              child: Text(_p.timeANome),
                            ),
                            DropdownMenuItem(
                              value: _p.timeBId,
                              child: Text(_p.timeBNome),
                            ),
                          ],
                          onChanged: (v) => setSB(() => timeId = v),
                          decoration: InputDecoration(
                            labelText: 'Time',
                            filled: true,
                            fillColor: cs.surface.withOpacity(0.8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Jogador que sai',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...jogadoresDoTime.map((p) {
                          final jid = p['jogador_id'] as int;
                          final selected = jogadorSaiId == jid;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? cs.primary.withOpacity(0.08)
                                  : cs.surface.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? cs.primary.withOpacity(0.35)
                                    : cs.outlineVariant,
                              ),
                            ),
                            child: RadioListTile<int>(
                              value: jid,
                              groupValue: jogadorSaiId,
                              onChanged: (v) => setSB(() => jogadorSaiId = v),
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              title: Row(
                                children: [
                                  _avatar(p),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_nomeJogadorPj(p))),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 10),
                        Text(
                          'Jogador que entra (fora da partida)',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (disponiveis.isEmpty)
                          Text(
                            'Nenhum jogador disponivel.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ...disponiveis.map((p) {
                          final timeNome = (p['time_nome'] ?? '').toString();
                          final jid = p['jogador_id'] as int;
                          final selected = jogadorEntraId == jid;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? cs.primary.withOpacity(0.08)
                                  : cs.surface.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? cs.primary.withOpacity(0.35)
                                    : cs.outlineVariant,
                              ),
                            ),
                            child: RadioListTile<int>(
                              value: jid,
                              groupValue: jogadorEntraId,
                              onChanged: (v) => setSB(() => jogadorEntraId = v),
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              title: Row(
                                children: [
                                  _avatar(p),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${_nomeJogadorPj(p)}${timeNome.isEmpty ? '' : ' - $timeNome'}',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: (_acaoSubstituicao || !podeConfirmar)
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await _registrarSubstituicao(
                                timeId: timeId!,
                                jogadorSaiId: jogadorSaiId!,
                                jogadorEntraId: jogadorEntraId!,
                              );
                            },
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Confirmar substituicao'),
                    ),
                  ),
                ],
              ),
            );
          });
        },
      ),
    );
  }

  Future<void> _abrirSubstituicaoRapida({
    required Map<String, dynamic> jogadorSai,
    required int timeId,
    required String timeNome,
  }) async {
    if (!_p.isLive || _acaoSubstituicao) return;

    int? jogadorEntraId;
    final jogadorSaiId = jogadorSai['jogador_id'] as int;
    final jogadorSaiNome = _nomeJogadorPj(jogadorSai);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        builder: (ctx, scrollController) {
          return StatefulBuilder(builder: (ctx, setSB) {
            final ativosIds = <int>{
              for (final p in _playersA) (p['jogador_id'] as int),
              for (final p in _playersB) (p['jogador_id'] as int),
            };

            final disponiveis = _todosJogadores
                .where((p) => !ativosIds.contains(p['jogador_id'] as int))
                .toList();

            if (jogadorEntraId != null &&
                !disponiveis.any((p) => p['jogador_id'] == jogadorEntraId)) {
              jogadorEntraId = null;
            }

            final podeConfirmar = jogadorEntraId != null;
            final theme = Theme.of(ctx);
            final cs = theme.colorScheme;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                top: 12,
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.swap_horiz),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Substituir $jogadorSaiNome',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar',
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Time: $timeNome',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: disponiveis.isEmpty
                        ? Center(
                            child: Text(
                              'Nenhum jogador disponivel.',
                              style: theme.textTheme.bodySmall,
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: disponiveis.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final p = disponiveis[index];
                              final jid = p['jogador_id'] as int;
                              final selected = jogadorEntraId == jid;
                              final timeTxt = (p['time_nome'] ?? '').toString();
                              return Container(
                                decoration: BoxDecoration(
                                  color: selected
                                      ? cs.primary.withOpacity(0.08)
                                      : cs.surfaceVariant.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? cs.primary.withOpacity(0.35)
                                        : cs.outlineVariant,
                                  ),
                                ),
                                child: ListTile(
                                  onTap: () => setSB(() => jogadorEntraId = jid),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  leading: _avatar(p),
                                  title: Text(
                                    _nomeJogadorPj(p),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: timeTxt.isEmpty ? null : Text(timeTxt),
                                  trailing: selected
                                      ? Icon(Icons.check_circle,
                                          color: cs.primary)
                                      : const Icon(Icons.circle_outlined,
                                          size: 18),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _acaoSubstituicao || !podeConfirmar
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await _registrarSubstituicao(
                                timeId: timeId,
                                jogadorSaiId: jogadorSaiId,
                                jogadorEntraId: jogadorEntraId!,
                              );
                            },
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Confirmar substituicao'),
                    ),
                  ),
                ],
              ),
            );
          });
        },
      ),
    );
  }

  // ---------------- registrar gol via clique no jogador ----------------
  Future<void> _onTapJogador({
    required Map<String, dynamic> autorPj,
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
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Gol do $timeNome',
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar',
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Assistência (opcional)',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: 1 + jogadoresDoTime.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final selected = selecionado == null;
                          return Container(
                            decoration: BoxDecoration(
                              color: selected
                                  ? Theme.of(ctx)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.08)
                                  : Theme.of(ctx)
                                      .colorScheme
                                      .surfaceVariant
                                      .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? Theme.of(ctx)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.35)
                                    : Theme.of(ctx).colorScheme.outlineVariant,
                              ),
                            ),
                            child: RadioListTile<int?>(
                              value: null,
                              groupValue: selecionado,
                              onChanged: (v) => setSB(() => selecionado = v),
                              dense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              title: Row(
                                children: const [
                                  Icon(Icons.block, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(child: Text('Sem assistência')),
                                ],
                              ),
                            ),
                          );
                        }

                        final j = jogadoresDoTime[index - 1];
                        final jid = j['jogador_id'] as int;
                        if (jid == autorId) return const SizedBox.shrink();
                        final apelido = (j['jogador']?['apelido'] ??
                                j['jogador']?['nome'] ??
                                'Jogador')
                            .toString();
                        final selected = selecionado == jid;
                        return Container(
                          decoration: BoxDecoration(
                            color: selected
                                ? Theme.of(ctx)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.08)
                                : Theme.of(ctx)
                                    .colorScheme
                                    .surfaceVariant
                                    .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? Theme.of(ctx)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.35)
                                  : Theme.of(ctx).colorScheme.outlineVariant,
                            ),
                          ),
                          child: RadioListTile<int?>(
                            value: jid,
                            groupValue: selecionado,
                            onChanged: (v) => setSB(() => selecionado = v),
                            dense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            title: Row(
                              children: [
                                _avatar(j),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    apelido,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
      unawaited(_showGolSplash(autorPj, timeNome));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  // ---------------- UI helpers ----------------
  Widget _buildGolSplashCard(
    BuildContext context,
    Map<String, dynamic> pj,
    String timeNome,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final nome = _nomeJogadorPj(pj);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'GOL!',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.primary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cs.primary.withOpacity(0.4), width: 2),
            ),
            child: _avatar(pj, size: 64),
          ),
          const SizedBox(height: 10),
          Text(
            nome,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: cs.primary.withOpacity(0.35)),
            ),
            child: Text(
              'GOL DO ${timeNome.toUpperCase()}!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showGolSplash(Map<String, dynamic> pj, String timeNome) async {
    if (!mounted || _golSplashVisible) return;
    _golSplashVisible = true;

    final navigator = Navigator.of(context, rootNavigator: true);

    Future<void> close() async {
      if (!_golSplashVisible) return;
      if (!mounted) return;
      if (navigator.canPop()) {
        navigator.pop();
      }
    }

    Future.delayed(const Duration(milliseconds: 1800), close);

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Gol',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, anim, anim2) {
        return Material(
          type: MaterialType.transparency,
          child: Center(child: _buildGolSplashCard(ctx, pj, timeNome)),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );

    _golSplashVisible = false;
  }
  Widget _statusPill(ThemeData theme) {
    final cs = theme.colorScheme;
    final color = _statusColor(cs);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        _statusLabel(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _miniStatIcon(ThemeData theme, IconData icon, int value, Color color) {
    return SizedBox(
      width: 22,
      height: 18,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Icon(icon, size: 16, color: color),
          ),
          Positioned(
            right: 0,
            top: -2,
            child: Text(
              '$value',
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreHeader(ThemeData theme) {
    final cs = theme.colorScheme;
    final tempoTxt = _tempoTexto();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _p.timeANome,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cs.primary.withOpacity(0.35)),
                ),
                child: Text(
                  '${_p.placarA} x ${_p.placarB}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _p.timeBNome,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statusPill(theme),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Text(
                  tempoTxt,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (_p.isLive) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Toque no jogador para gol',
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final content = InkWell(
      onTap: () => _onTapJogador(
        autorPj: pj,
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
            if (gols > 0 || asts > 0) ...[
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (gols > 0)
                    _miniStatIcon(theme, Icons.sports_soccer, gols, cs.primary),
                  if (gols > 0 && asts > 0) const SizedBox(width: 6),
                  if (asts > 0)
                    _miniStatIcon(theme, Icons.assistant, asts, cs.secondary),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    if (!_p.isLive) return content;

    final swipeBg = Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swap_horiz, color: cs.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Substituir',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Dismissible(
      key: ValueKey('sub-$timeId-$jid'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        if (_acaoSubstituicao) return false;
        await _abrirSubstituicaoRapida(
          jogadorSai: pj,
          timeId: timeId,
          timeNome: timeNome,
        );
        return false;
      },
      background: swipeBg,
      secondaryBackground: swipeBg,
      child: content,
    );
  }

  Widget _substituicaoTile(Map<String, dynamic> s) {
    final cs = Theme.of(context).colorScheme;
    final entra = (s['jogador_entra'] as Map?)?.cast<String, dynamic>();
    final sai = (s['jogador_sai'] as Map?)?.cast<String, dynamic>();
    final entraNome = _nomeJogador(entra);
    final saiNome = _nomeJogador(sai);
    final jid = (entra?['id'] as int?) ?? 0;
    final gols = _golsPorJogador[jid] ?? 0;
    final asts = _assistsPorJogador[jid] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.arrow_upward, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              _avatar(_wrapJogador(entra), size: 22),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entraNome,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (gols > 0)
                Row(children: [const Icon(Icons.sports_soccer, size: 16), Text(' $gols')]),
              const SizedBox(width: 6),
              if (asts > 0)
                Row(children: [const Icon(Icons.checkroom, size: 16), Text(' $asts')]),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.arrow_downward, size: 16, color: cs.onSurface.withOpacity(0.45)),
              const SizedBox(width: 6),
              _avatar(_wrapJogador(sai), size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  saiNome,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
                ),
              ),
              Text(
                'Saiu',
                style: TextStyle(color: cs.onSurface.withOpacity(0.45), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _teamColumn({
    required String titulo,
    required int placar,
    required List<Map<String, dynamic>> jogadores,
    required int timeId,
    required Color accentColor,
    List<Map<String, dynamic>> substituicoes = const [],
    bool mostrarSubstituicoes = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accentColor.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: accentColor.withOpacity(0.35)),
                    ),
                    child: Text(
                      '$placar',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                itemCount:
                    jogadores.length + (mostrarSubstituicoes && substituicoes.isNotEmpty ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  if (index < jogadores.length) {
                    final pj = jogadores[index];
                    return _playerTile(
                      pj: pj,
                      timeId: timeId,
                      timeNome: titulo,
                      jogadoresDoTime: jogadores,
                    );
                  }
                  return Column(
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cs.primary.withOpacity(0.12)),
                        ),
                        child: const Center(
                          child: Text(
                            'Substituicoes',
                            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...substituicoes.map(_substituicaoTile),
                    ],
                  );
                },
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
    final mostrarOriginais = _p.isFT;
    final jogadoresA = mostrarOriginais ? _playersOrigA : _playersA;
    final jogadoresB = mostrarOriginais ? _playersOrigB : _playersB;
    final subsA = mostrarOriginais
        ? _substituicoesPorTime(_substituicoesTodas, _p.timeAId)
        : const <Map<String, dynamic>>[];
    final subsB = mostrarOriginais
        ? _substituicoesPorTime(_substituicoesTodas, _p.timeBId)
        : const <Map<String, dynamic>>[];

    return Scaffold(
      appBar: AppBar(
        title: Text('${_p.timeANome}  ${_p.placarA} x ${_p.placarB}  ${_p.timeBNome}'),
        actions: [
          if (_p.isLive && kIsWeb)
            IconButton(
              tooltip: _wakeLockAtivo ? 'Tela ligada' : 'Manter tela ligada',
              icon: Icon(_wakeLockAtivo ? Icons.lock : Icons.lock_open),
              onPressed: _wakeLockAtivo ? null : _solicitarWakeLockManual,
            ),
          if (_p.isLive)
            IconButton(
              tooltip: 'Substituicoes',
              icon: _acaoSubstituicao
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.swap_horiz),
              onPressed: _acaoSubstituicao ? null : _abrirSubstituicoes,
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
                _scoreHeader(Theme.of(context)),
                // colunas dos times
                Expanded(
                  child: Row(
                    children: [
                      _teamColumn(
                        titulo: _p.timeANome,
                        placar: _p.placarA,
                        jogadores: jogadoresA,
                        timeId: _p.timeAId,
                        accentColor: cs.primary,
                        substituicoes: subsA,
                        mostrarSubstituicoes: mostrarOriginais,
                      ),
                      _teamColumn(
                        titulo: _p.timeBNome,
                        placar: _p.placarB,
                        jogadores: jogadoresB,
                        timeId: _p.timeBId,
                        accentColor: cs.secondary,
                        substituicoes: subsB,
                        mostrarSubstituicoes: mostrarOriginais,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
