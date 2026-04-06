import 'dart:convert';
import 'dart:io';

import 'package:auditoria/repostiories/products_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historico')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: context.watch<ProductsRepository>().getHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final history = snapshot.data ?? const <Map<String, dynamic>>[];
          if (history.isEmpty) {
            return const Center(
              child: Text('Nenhuma contagem finalizada ainda.'),
            );
          }

          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final entry = history[index];
              final date = DateTime.tryParse(entry['data'].toString());
              final formattedDate = date == null ? '-' : _formatDate(date);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Contagem #${entry['id']}'),
                  subtitle: Text(
                    '$formattedDate\n'
                    'Itens: ${entry['totalItens'] ?? 0} | '
                    'Pendentes: ${entry['pendentes'] ?? 0} | '
                    'Divergencias: ${entry['divergencias'] ?? 0}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistoryDetailPage(
                          contagemId: entry['id'] as int,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String _formatDate(DateTime date) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year} '
      '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
}

class HistoryDetailPage extends StatelessWidget {
  final int contagemId;

  const HistoryDetailPage({super.key, required this.contagemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contagem #$contagemId')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: context.read<ProductsRepository>().getHistoryEntry(contagemId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final entry = snapshot.data;
          if (entry == null) {
            return const Center(child: Text('Contagem nao encontrada.'));
          }

          final checklist = _decodeStringMapList(entry['checklistJson']);
          final photos = _decodeStringList(entry['fotosJson']);
          final items =
              (entry['items'] as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if ((entry['observacoes']?.toString().trim().isNotEmpty ?? false))
                Card(
                  child: ListTile(
                    title: const Text('Observacoes'),
                    subtitle: Text(entry['observacoes'].toString()),
                  ),
                ),
              if (checklist.isNotEmpty) ...[
                Text('Checklist', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...checklist.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item['question'] ?? ''),
                      trailing: Text(item['answer'] ?? ''),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (photos.isNotEmpty) ...[
                Text('Fotos', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...photos.map(
                  (path) => Card(
                    child: ListTile(
                      title: Text(path.split(Platform.pathSeparator).last),
                      subtitle: Text(path),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text('Itens', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...items.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(
                      '${item['nomeProduto'] ?? 'Sem nome'} (${item['codigoBarras'] ?? '-'})',
                    ),
                    subtitle: Text(
                      'Esperado: ${item['quantidadeEsperada']} | '
                      'Contado: ${item['quantidadeContada']}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(item['status']?.toString() ?? '-'),
                        Text('Dif: ${item['diferenca']}'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, String>> _decodeStringMapList(dynamic source) {
    if (source == null || source.toString().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(source.toString()) as List<dynamic>;
    return decoded
        .map((item) => Map<String, String>.from(item as Map))
        .toList();
  }

  List<String> _decodeStringList(dynamic source) {
    if (source == null || source.toString().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(source.toString()) as List<dynamic>;
    return decoded.map((item) => item.toString()).toList();
  }
}
