import 'package:auditoria/model/produto.dart';
import 'package:auditoria/pages/home_page.dart';
import 'package:auditoria/repostiories/products_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeProductsRepository extends ProductsRepository {
  @override
  Future<List<Produto>> getAllProducts() async {
    return [
      Produto(
        id: 1,
        codigoBarras: '7891234567890',
        codigoInterno: '12345',
        nome: 'Arroz',
        quantidadeEsperada: 10,
      ),
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getHistory() async {
    return [
      {
        'id': 1,
        'data': DateTime(2026, 4, 5, 10, 30).toIso8601String(),
        'status': 1,
        'observacoes': '',
        'checklistJson': '[]',
        'fotosJson': '[]',
        'totalItens': 1,
        'pendentes': 0,
        'divergencias': 0,
      },
    ];
  }
}

void main() {
  testWidgets('exibe as abas principais do app', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ProductsRepository>.value(
        value: _FakeProductsRepository(),
        child: const MaterialApp(home: HomePage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Auditoria de Estoque'), findsOneWidget);
    expect(find.text('Contagem'), findsOneWidget);
    expect(find.text('Produtos'), findsOneWidget);
    expect(find.text('Historico'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);

    await tester.tap(find.text('Produtos'));
    await tester.pumpAndSettle();
    expect(find.text('Lista de Produtos'), findsOneWidget);
    expect(find.textContaining('Arroz'), findsOneWidget);

    await tester.tap(find.text('Historico'));
    await tester.pumpAndSettle();
    expect(find.text('Contagem #1'), findsOneWidget);
  });
}
