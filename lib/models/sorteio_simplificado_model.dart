// models/sorteio_simplificado_model.dart
class SorteioSimplificadoModel {
  final int id;
  final String descricao;
  final String data;
  final int numero;

  SorteioSimplificadoModel({
    required this.id,
    required this.descricao,
    required this.data,
    required this.numero,
  });

  factory SorteioSimplificadoModel.fromJson(Map<String, dynamic> json) {
    return SorteioSimplificadoModel(
      id: json['id'],
      descricao: json['descricao'],
      data: json['data'],
      numero: json['numero'],
    );
  }
}
