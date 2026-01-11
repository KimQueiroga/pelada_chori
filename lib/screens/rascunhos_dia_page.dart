import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/api_service.dart';
import '../models/sorteio_detalhe_model.dart';
import '../utils/app_date.dart';
import '../screens/sorteio_page.dart';
import '../models/jogador_sorteio_model.dart';
import '../models/sorteio_time_model.dart';

class RascunhosDiaPage extends StatefulWidget {
  const RascunhosDiaPage({Key? key}) : super(key: key);

  @override
  State<RascunhosDiaPage> createState() => _RascunhosDiaPageState();
}

class _RascunhosDiaPageState extends State<RascunhosDiaPage> {
  bool _loading = true;
  String? _erro;

  /// Lista de pares (cada item é a lista de sorteios de uma tentativa).
  late List<List<SorteioDetalhe>> _pares;
  int? _tentativaSelecionada;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final lista = await ApiService.getRascunhosDoDia();

      // Agrupa por tentativa (cada tentativa deve ter 2 sorteios: nº1 e nº2)
      final Map<int, List<SorteioDetalhe>> porTentativa = {};
      for (final s in lista) {
        final t = s.tentativa ?? 0;
        porTentativa.putIfAbsent(t, () => []).add(s);
      }

      // Ordena tentativas desc e monta pares (ordenando nº 1 e nº 2 por 'numero')
      final chaves = porTentativa.keys.toList()..sort((a, b) => b.compareTo(a));
      final pares = <List<SorteioDetalhe>>[];
      for (final t in chaves) {
        final arr = porTentativa[t]!..sort((a, b) => a.numero.compareTo(b.numero));
        pares.add(arr);
      }

      setState(() {
        _pares = pares;
        _loading = false;
        // Seleciona por padrão a tentativa mais recente se estiver completa
        if (_pares.isNotEmpty && _pares.first.length == 2) {
          _tentativaSelecionada = _pares.first.first.tentativa;
        } else {
          _tentativaSelecionada = null;
        }
      });
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar rascunhos: $e';
        _loading = false;
      });
    }
  }

  Future<void> _publicarSelecionado() async {
    if (_tentativaSelecionada == null) return;

    // Localiza o par da tentativa selecionada
    final par = _pares.firstWhere(
      (p) => p.isNotEmpty && p.first.tentativa == _tentativaSelecionada,
      orElse: () => const <SorteioDetalhe>[],
    );

    if (par.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta tentativa não está completa.')),
      );
      return;
    }

    final id1 = par[0].id;
    final id2 = par[1].id;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publicar dupla'),
        content: Text(
          'Publicar a tentativa ${par.first.tentativa} para votação?\n'
          'Data: ${AppDate.brFromApi(par.first.data)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ApiService.publicarDuplaPorIds(sorteioId1: id1, sorteioId2: id2);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dupla publicada! Abrindo sorteios ativos...')),
      );

      // Abre Sorteios Ativos
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SorteioPage()),
        (route) => false,
      );

      // Recarrega (defensivo)
      _carregar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao publicar: $e')),
      );
    }
  }

  // ---------- COMPARTILHAR ----------

  Future<void> _shareText(String text) async {
    // Tenta WhatsApp (wa.me). Se não rolar, cai no share sheet do SO.
    final wa = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    try {
      if (await canLaunchUrl(wa)) {
        await launchUrl(wa, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    await Share.share(text);
  }

  // Helpers de formatação “bonita”
  String _bold(String s) => '*$s*';

  String _fmtNum(double? v) =>
      (v == null) ? '-' : v.toStringAsFixed(2).replaceAll('.', ',');

  String _pad2(String? numero) {
    if (numero == null || numero.trim().isEmpty) return '--';
    final n = int.tryParse(numero) ?? -1;
    if (n < 0) return numero; // se vier algo não numérico, devolve bruto
    return n.toString().padLeft(2, '0');
  }

  /// Rótulo curto da posição, sem emoji.
  String _posShort(String? pos) {
    switch ((pos ?? '').toLowerCase()) {
      case 'defesa':
        return 'DEF';
      case 'meio':
        return 'MEI';
      case 'ataque':
        return 'ATA';
      default:
        return pos ?? '';
    }
  }

  String _formatJogadorLinhaBonito(JogadorSorteio j) {
    final numero = _pad2(j.numeroCamisa);
    final nome = j.apelido?.trim().isNotEmpty == true
        ? j.apelido!
        : (j.nome ?? 'Jogador');
    final pos = _posShort(j.posicao);
    final posTxt = pos.isNotEmpty ? ' ($pos)' : '';
    return '- $numero - $nome$posTxt';
  }

  String _formatTimeBonito(SorteioTime t) {
    final buffer = StringBuffer();
    final media = _fmtNum(t.mediaCalculada ?? t.media); // compat com seu modelo
    buffer.writeln('${_bold(t.nome ?? 'Time')} (media $media)');
    for (final j in t.jogadores) {
      buffer.writeln(_formatJogadorLinhaBonito(j));
    }
    return buffer.toString().trimRight();
  }

  String _formatSorteioBonito(SorteioDetalhe s) {
    final buffer = StringBuffer();
    buffer.writeln(_bold('Sorteio ${s.numero} - ${AppDate.brFromApi(s.data)}'));
    if ((s.descricao ?? '').isNotEmpty) {
      buffer.writeln('Descricao: ${s.descricao!.trim()}');
    }
    for (var i = 0; i < s.times.length; i++) {
      buffer.writeln(_formatTimeBonito(s.times[i]));
      if (i != s.times.length - 1) buffer.writeln();
    }
    return buffer.toString().trimRight();
  }

  String _formatTentativaBonito(List<SorteioDetalhe> par) {
    if (par.isEmpty) return '';
    final tentativa = par.first.tentativa ?? 0;
    final data = AppDate.brFromApi(par.first.data);

    final buffer = StringBuffer();
    buffer.writeln(_bold('Pelada Chori'));
    buffer.writeln('Tentativa $tentativa - $data');
    buffer.writeln();
    for (var i = 0; i < par.length; i++) {
      buffer.writeln(_formatSorteioBonito(par[i]));
      if (i != par.length - 1) {
        buffer.writeln();
        buffer.writeln('----');
        buffer.writeln();
      }
    }
    buffer.writeln();
    buffer.write('Enviado pelo app Pelada Chori');
    return buffer.toString().trimRight();
  }

  Future<void> _shareTentativa(List<SorteioDetalhe> par) async {
    final text = _formatTentativaBonito(par);
    if (text.trim().isEmpty) return;
    await _shareText(text);
  }

  Future<void> _shareSorteio(SorteioDetalhe s) async {
    final text = _formatSorteioBonito(s);
    if (text.trim().isEmpty) return;
    await _shareText(text);
  }

  // ---------- UI ----------

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sem rascunhos hoje',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Quando houver novas tentativas, elas vao aparecer aqui.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _carregar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(ThemeData theme, {required bool completa}) {
    final baseColor = completa ? Colors.green[700] : Colors.orange[700];
    final color = baseColor ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        completa ? 'Par completo' : 'Incompleto',
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _metaPill(ThemeData theme, String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Título com a data: usa a do 1º card (se houver),
    // senão usa a data de hoje — SEM toLocal().
    final tituloData = (!_loading &&
            _erro == null &&
            _pares.isNotEmpty &&
            _pares.first.isNotEmpty)
        ? AppDate.brFromApi(_pares.first.first.data)
        : AppDate.br(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text('Rascunhos de Hoje • $tituloData'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
              : _pares.isEmpty
                  ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                    itemCount: _pares.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final par = _pares[index];
                      final tentativa = par.isNotEmpty ? par.first.tentativa : null;
                      final completa = par.length == 2;
                      final selecionada = tentativa != null &&
                          tentativa == _tentativaSelecionada;
                      final dataTentativa =
                          par.isNotEmpty ? AppDate.brFromApi(par.first.data) : '';

                      return Card(
                        margin: EdgeInsets.zero,
                        elevation: selecionada ? 2 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: selecionada
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cabeçalho (radio + “Tentativa X” + status + share tentativa)
                              InkWell(
                                onTap: completa
                                    ? () => setState(
                                        () => _tentativaSelecionada = tentativa)
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Radio<int>(
                                        value: tentativa ?? -1,
                                        groupValue: _tentativaSelecionada,
                                        onChanged: completa
                                            ? (v) => setState(
                                                () => _tentativaSelecionada = v)
                                            : null,
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Tentativa ${tentativa ?? '-'}',
                                              style: theme.textTheme.titleMedium,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (dataTentativa.isNotEmpty)
                                              Text(
                                                'Data: $dataTentativa',
                                                style: theme.textTheme.bodySmall,
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _statusPill(theme, completa: completa),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        tooltip: 'Compartilhar tentativa',
                                        onPressed: par.isNotEmpty
                                            ? () => _shareTentativa(par)
                                            : null,
                                        icon: const Icon(Icons.share),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Cartões dos sorteios desta tentativa (1 e 2)
                              ...par
                                  .map(_cardSorteio)
                                  .expand((w) => [w, const SizedBox(height: 8)])
                                  .toList()
                                ..removeLast(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: (_tentativaSelecionada != null &&
                    _pares.any((p) =>
                        p.isNotEmpty &&
                        p.first.tentativa == _tentativaSelecionada &&
                        p.length == 2))
                ? _publicarSelecionado
                : null,
            icon: const Icon(Icons.publish),
            label: const Text('Publicar dupla selecionada'),
          ),
        ),
      ),
    );
  }

  /// Card com *um sorteio* (título + data + times e jogadores) + botão compartilhar sorteio.
  Widget _cardSorteio(SorteioDetalhe s) {
    final theme = Theme.of(context);
    final dataTxt = AppDate.brFromApi(s.data);

    return Card(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título + data do sorteio + share
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sorteio ${s.numero}',
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _metaPill(theme, dataTxt, icon: Icons.event),
                IconButton(
                  tooltip: 'Compartilhar sorteio',
                  onPressed: () => _shareSorteio(s),
                  icon: const Icon(Icons.share),
                ),
              ],
            ),

            if ((s.descricao ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Text(
                  s.descricao!,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Times e jogadores
            ...s.times.asMap().entries.map((entry) {
              final t = entry.value;
              final isLast = entry.key == s.times.length - 1;
              final mediaTxt = _fmtNum(t.mediaCalculada ?? t.media);
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.nome ?? 'Time',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _metaPill(theme, 'Media $mediaTxt',
                              icon: Icons.bar_chart),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...t.jogadores.map((j) {
                        final pos = _posShort(j.posicao);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundImage: (j.foto != null &&
                                        j.foto!.isNotEmpty)
                                    ? NetworkImage(j.foto!)
                                    : null,
                                child: (j.foto == null || j.foto!.isEmpty)
                                    ? const Icon(Icons.person, size: 16)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_pad2(j.numeroCamisa)} - ${j.apelido ?? j.nome ?? "Jogador"}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (pos.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceVariant
                                        .withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: theme.colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Text(
                                    pos,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
