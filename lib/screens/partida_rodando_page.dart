import 'dart:async';
import 'package:flutter/material.dart';
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
  Timer? _ticker;
  Duration _decorrido = Duration.zero; // exibição
  bool _carregando = true;
  bool _acao = false;

  @override
  void initState() {
    super.initState();
    _p = widget.partida;
    _recarregar();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _recarregar() async {
    setState(() => _carregando = true);
    try {
      // busca estado atual da partida
      final d = await ApiService.getPartidaDetalhe(_p.id);
      final p = Partida.fromJson(d['partida'] as Map<String, dynamic>);
      if (!mounted) return;
      setState(() {
        _p = p;
        _setupCronometro();
      });
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _setupCronometro() {
    _ticker?.cancel();
    if (!_p.emAndamento || _p.iniciadoEm == null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final dec = nowSec - (_p.iniciadoEm ?? nowSec);
      setState(() => _decorrido = Duration(seconds: dec));
    });
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2,'0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2,'0');
    return '$m:$s';
  }

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha: $e')));
    } finally {
      if (mounted) setState(() => _acao = false);
    }
  }

  Future<void> _registrarGol() async {
    // abre dialog: escolher time -> jogador (e opcional assistente)
    final timeEscolhido = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Quem fez o gol?'),
        children: [
          SimpleDialogOption(onPressed: ()=>Navigator.pop(context, _p.timeAId), child: Text(_p.timeANome)),
          SimpleDialogOption(onPressed: ()=>Navigator.pop(context, _p.timeBId), child: Text(_p.timeBNome)),
        ],
      ),
    );
    if (timeEscolhido == null) return;

    // busca jogadores do time
    final times = await ApiService.getTimesDoSorteio(_p.sorteioId);
    final t = times.firstWhere((x) => x['id'] == timeEscolhido);
    final jogadores = ((t['jogadores'] as List?) ?? const [])
        .map<Map<String,dynamic>>((e)=> (e as Map).cast<String,dynamic>()).toList();

    int? autorId;
    int? assistId;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, __) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Gol do ${t['nome']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Autor do gol'),
                items: jogadores.map((j)=>DropdownMenuItem(
                  value: j['jogador_id'] as int,
                  child: Text(j['jogador']?['apelido'] ?? j['jogador']?['nome'] ?? 'Jogador'),
                )).toList(),
                onChanged: (v)=> autorId = v,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Assistência (opcional)'),
                items: [
                  const DropdownMenuItem(value: -1, child: Text('Sem assistência')),
                  ...jogadores.map((j)=>DropdownMenuItem(
                    value: j['jogador_id'] as int,
                    child: Text(j['jogador']?['apelido'] ?? j['jogador']?['nome'] ?? 'Jogador'),
                  )),
                ],
                onChanged: (v)=> assistId = v == -1 ? null : v,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: (){
                  if (autorId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Selecione o autor do gol.')),
                    );
                    return;
                  }
                  Navigator.pop(context, {'autor': autorId, 'assist': assistId});
                },
                icon: const Icon(Icons.check),
                label: const Text('Registrar gol'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    ).then((res) async {
      if (res == null) return;
      try {
        await ApiService.registrarGol(
          partidaId: _p.id,
          timeId: timeEscolhido,
          jogadorId: res['autor'] as int,
          assistJogadorId: res['assist'] as int?,
        );
        await _recarregar();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    });
  }

  Future<void> _encerrar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Encerrar partida?'),
        content: const Text('Confirma encerrar agora? (o sistema registra vencedor/empate)'),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: ()=>Navigator.pop(context, true), child: const Text('Encerrar')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _acao = true);
    try {
      final p = await ApiService.encerrarPartida(_p.id);
      if (!mounted) return;
      setState(() => _p = p);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partida encerrada.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _acao = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_p.timeANome}  ${_p.placarA} x ${_p.placarB}  ${_p.timeBNome}'),
        actions: [
          if (!_p.emAndamento && !_p.encerrada)
            IconButton(
              tooltip: 'Iniciar',
              icon: _acao ? const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2))
                          : const Icon(Icons.play_arrow_rounded),
              onPressed: _acao ? null : _iniciar,
            ),
          if (_p.emAndamento)
            IconButton(
              tooltip: 'Encerrar',
              icon: _acao ? const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2))
                          : const Icon(Icons.flag_circle_outlined),
              onPressed: _acao ? null : _encerrar,
            ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  _p.emAndamento ? 'Tempo decorrido' : _p.encerrada ? 'Partida encerrada' : 'Aguardando início',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer, borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _fmt(_decorrido),
                    style: const TextStyle(fontSize: 36, fontFeatures: [FontFeature.tabularFigures()]),
                  ),
                ),
                const SizedBox(height: 16),
                if (_p.emAndamento)
                  FilledButton.icon(
                    onPressed: _registrarGol,
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar gol'),
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: ApiService.getPartidaDetalhe(_p.id),
                    builder: (_, snapshot) {
                      final gols = ((snapshot.data?['gols'] as List?) ?? const [])
                          .map<Map<String, dynamic>>((e)=> (e as Map).cast<String,dynamic>()).toList();

                      if (gols.isEmpty) {
                        return const Center(child: Text('Sem gols registrados.'));
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: gols.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final g = gols[i];
                          final lado = (g['time_id'] == _p.timeAId) ? _p.timeANome : _p.timeBNome;
                          final autor = (g['autor_nome'] ?? 'Autor') as String;
                          final assist = (g['assistente_nome'] as String?);
                          return ListTile(
                            leading: const Icon(Icons.sports_soccer),
                            title: Text('$lado — $autor'),
                            subtitle: Text(assist == null || assist.isEmpty ? 'Sem assistência' : 'Assistência: $assist'),
                            trailing: Text('min ${g['minuto'] ?? '-'}'),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
