enum ContagemStatus { pendente, conferido }

class Contagem {
  final int? id;
  final DateTime data;
  final ContagemStatus status;

  Contagem({
    this.id,
    required this.data,
    this.status = ContagemStatus.pendente,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data.toIso8601String(),
      'status': status.index,
    };
  }

  factory Contagem.fromMap(Map<String, dynamic> map) {
    return Contagem(
      id: map['id'],
      data: DateTime.parse(map['data']),
      status: ContagemStatus.values[map['status']],
    );
  }
}

class ItemContagem {
  final int? id;
  final int contagemId;
  final int produtoId;
  final double quantidadeContada;
  final double diferenca;

  ItemContagem({
    this.id,
    required this.contagemId,
    required this.produtoId,
    required this.quantidadeContada,
    required this.diferenca,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contagemId': contagemId,
      'produtoId': produtoId,
      'quantidadeContada': quantidadeContada,
      'diferenca': diferenca,
    };
  }

  factory ItemContagem.fromMap(Map<String, dynamic> map) {
    return ItemContagem(
      id: map['id'],
      contagemId: map['contagemId'],
      produtoId: map['produtoId'],
      quantidadeContada: map['quantidadeContada'],
      diferenca: map['diferenca'],
    );
  }
}
