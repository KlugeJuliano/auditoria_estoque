import 'package:auditoria/model/produto.dart';
import 'package:auditoria/repostiories/products_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Produtos')),
      body: FutureBuilder<List<Produto>>(
        future: context.watch<ProductsRepository>().getAllProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data ?? const <Produto>[];
          if (products.isEmpty) {
            return const Center(
              child: Text('Nenhum produto importado ou cadastrado ainda.'),
            );
          }

          return ListView.separated(
            itemCount: products.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(product.nome),
                subtitle: Text(
                  'Barras: ${product.codigoBarras}'
                  '${product.codigoInterno != null ? ' | Interno: ${product.codigoInterno}' : ''}',
                ),
                trailing: Text('Esp: ${product.quantidadeEsperada}'),
              );
            },
          );
        },
      ),
    );
  }
}
