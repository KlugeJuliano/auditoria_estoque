import 'dart:io';

import 'package:auditoria/repostiories/products_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuracoes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('Importar produtos'),
              subtitle: const Text(
                'Suporta CSV, TXT e XLSX com colunas: barcode, internalCode, name, expectedQty',
              ),
              onTap: () async {
                final result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['csv', 'txt', 'xlsx'],
                );

                if (!context.mounted) {
                  return;
                }

                if (result == null) {
                  return;
                }

                final path = result.files.single.path;
                if (path == null) {
                  return;
                }

                try {
                  final repo = context.read<ProductsRepository>();
                  final messenger = ScaffoldMessenger.of(context);

                  await repo.importProducts(File(path));

                  if (!context.mounted) {
                    return;
                  }

                  messenger.showSnackBar(
                    const SnackBar(content: Text('Importacao concluida!')),
                  );
                } catch (error) {
                  final messenger = ScaffoldMessenger.of(context);

                  messenger.showSnackBar(
                    SnackBar(content: Text('Erro na importacao: $error')),
                  );
                }
              },
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
