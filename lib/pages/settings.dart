import 'dart:io';

import 'package:auditoria/repostiories/products_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isImporting = false;
  String? _lastImportMessage;

  Future<void> _importProducts() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt', 'xlsx'],
    );

    if (!mounted || result == null) {
      return;
    }

    final path = result.files.single.path;
    final fileName = result.files.single.name;
    if (path == null) {
      return;
    }

    setState(() {
      _isImporting = true;
      _lastImportMessage = 'Importando $fileName...';
    });

    try {
      final repo = context.read<ProductsRepository>();
      final importedCount = await repo.importProducts(File(path));

      if (!mounted) {
        return;
      }

      final message = importedCount == 1
          ? '1 produto importado de $fileName.'
          : '$importedCount produtos importados de $fileName.';

      setState(() {
        _lastImportMessage = message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = 'Erro na importacao: $error';
      setState(() {
        _lastImportMessage = message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuracoes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.file_upload_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Importar cadastro de estoque',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use o arquivo atual do cliente para carregar ou atualizar produtos antes da contagem.',
                  ),
                  const SizedBox(height: 12),
                  const _InfoLine(
                    icon: Icons.table_rows_outlined,
                    text: 'Formatos aceitos: CSV, TXT e XLSX.',
                  ),
                  const _InfoLine(
                    icon: Icons.view_column_outlined,
                    text:
                        'Colunas: codigo de barras, codigo interno, nome, quantidade esperada.',
                  ),
                  const _InfoLine(
                    icon: Icons.rule_outlined,
                    text:
                        'CSV/TXT pode usar virgula, ponto e virgula ou tabulacao.',
                  ),
                  const _InfoLine(
                    icon: Icons.numbers_outlined,
                    text: 'Quantidade aceita decimal com ponto ou virgula.',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Exemplo:\n7891234567890;12345;Arroz Tipo 1;10,5',
                    ),
                  ),
                  if (_lastImportMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_lastImportMessage!),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isImporting ? null : _importProducts,
                      icon: _isImporting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file_outlined),
                      label: Text(
                        _isImporting ? 'Importando...' : 'Selecionar arquivo',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.scale_outlined),
              title: const Text('Codigo de balanca'),
              subtitle: const Text(
                'Prefixos 20-29, codigo interno nas posicoes 3-7 e peso nas posicoes 8-12.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_off_outlined),
              title: const Text('Modo offline'),
              subtitle: const Text(
                'Produtos, contagens, historico e auditorias ficam salvos localmente.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
