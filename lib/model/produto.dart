class Produto {
  final int? id;
  final String codigoBarras;
  final String? codigoInterno;
  final String nome;
  final double quantidadeEsperada;

  Produto({
    this.id,
    required this.codigoBarras,
    this.codigoInterno,
    required this.nome,
    this.quantidadeEsperada = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigoBarras': codigoBarras,
      'codigoInterno': codigoInterno,
      'nome': nome,
      'quantidadeEsperada': quantidadeEsperada,
    };
  }

  factory Produto.fromMap(Map<String, dynamic> map) {
    return Produto(
      id: map['id'],
      codigoBarras: map['codigoBarras'],
      codigoInterno: map['codigoInterno'],
      nome: map['nome'],
      quantidadeEsperada: map['quantidadeEsperada'] ?? 0.0,
    );
  }
}
