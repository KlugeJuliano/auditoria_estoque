import 'dart:convert';
import 'dart:io';

import 'package:auditoria/repostiories/products_repository.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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
          final items = (entry['items'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>();

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
                Text('Checklist',
                    style: Theme.of(context).textTheme.titleMedium),
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
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _exportHistory(
                  context,
                  items,
                  ExportFileFormat.csv,
                ),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Exportar CSV'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _exportHistory(
                  context,
                  items,
                  ExportFileFormat.txt,
                ),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Exportar TXT'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _exportHistory(
                  context,
                  items,
                  ExportFileFormat.xlsx,
                ),
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('Exportar XLSX'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportHistory(
    BuildContext context,
    List<Map<String, dynamic>> items,
    ExportFileFormat format,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repo = context.read<ProductsRepository>();

    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final exportItems = items
          .map(
            (item) => {
              'barcode': item['codigoBarras'],
              'nome': item['nomeProduto'],
              'esperado': item['quantidadeEsperada'],
              'contado': item['quantidadeContada'],
              'diferenca': item['diferenca'],
              'status': item['status'],
            },
          )
          .toList();
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      late final File file;
      switch (format) {
        case ExportFileFormat.csv:
          file =
              File('${directory.path}/contagem_${contagemId}_$timestamp.csv');
          await file.writeAsString(await repo.exportToCsv(exportItems));
          break;
        case ExportFileFormat.txt:
          file =
              File('${directory.path}/contagem_${contagemId}_$timestamp.txt');
          await file.writeAsString(
            await repo.exportToCsv(exportItems, delimiter: ';'),
          );
          break;
        case ExportFileFormat.xlsx:
          file =
              File('${directory.path}/contagem_${contagemId}_$timestamp.xlsx');
          await file.writeAsBytes(await repo.exportToExcel(exportItems));
          break;
      }

      if (!context.mounted) {
        return;
      }

      navigator.pop();

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Relatorio de Auditoria de Estoque #$contagemId',
          text: 'Relatorio exportado em ${format.name.toUpperCase()}',
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao exportar: $error')),
      );
    }
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
