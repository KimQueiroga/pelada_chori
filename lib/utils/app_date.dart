import 'package:intl/intl.dart';

/// Utilitário para lidar com datas vindas da API sem sofrer com fuso/ISO.
class AppDate {
  /// Converte uma string da API para um DateTime "date-only" (sem timezone).
  /// Aceita "yyyy-MM-dd" ou ISO completo (ex.: "yyyy-MM-ddTHH:mm:ss.sssZ").
  static DateTime parseApi(String raw) {
    if (raw.isEmpty) {
      throw ArgumentError('Data vazia.');
    }
    // Fica só com a parte yyyy-MM-dd.
    final core = raw.length >= 10 ? raw.substring(0, 10) : raw;
    final parts = core.split('-'); // [yyyy, MM, dd]
    if (parts.length != 3) {
      throw FormatException('Formato de data inválido: $raw');
    }
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);
    // Cria DateTime local sem componente de hora (sem timezone).
    return DateTime(y, m, d);
  }

  /// Formata para dd/MM/yyyy.
  static String br(DateTime dt) => DateFormat('dd/MM/yyyy').format(dt);

  /// Atalho: recebe string da API e devolve pronta no formato dd/MM/yyyy.
  static String brFromApi(String raw) => br(parseApi(raw));
}

