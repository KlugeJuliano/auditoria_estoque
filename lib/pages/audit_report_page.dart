import 'dart:io';

import 'package:auditoria/repostiories/products_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class AuditReportPage extends StatefulWidget {
  final Map<String, double> currentCount;

  const AuditReportPage({super.key, required this.currentCount});

  @override
  State<AuditReportPage> createState() => _AuditReportPageState();
}

class _AuditReportPageState extends State<AuditReportPage> {
  static const List<String> _questions = [
    'Area de estoque organizada?',
    'Produtos avariados identificados?',
    'Etiquetas e codigos legiveis?',
  ];

  final TextEditingController _notesController = TextEditingController();
  final Map<String, String> _checklistAnswers = {
    for (final question in _questions) question: 'N/A',
  };
  final List<String> _photoPaths = [];
  final ImagePicker _imagePicker = ImagePicker();
  int? _savedContagemId;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );

    if (result == null) {
      return;
    }

    setState(() {
      _photoPaths
        ..clear()
        ..addAll(
          result.files
              .map((file) => file.path)
              .whereType<String>()
              .where((path) => path.isNotEmpty),
        );
    });
  }

  Future<void> _capturePhoto() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo == null || !mounted) {
        return;
      }

      setState(() {
        _photoPaths.add(photo.path);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir a camera: $error')),
      );
    }
  }

  Future<void> _exportData(
    BuildContext context,
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

      final reportData = await repo.buildReportData(widget.currentCount);
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      late final File file;
      switch (format) {
        case ExportFileFormat.csv:
          file = File('${directory.path}/contagem_$timestamp.csv');
          await file.writeAsString(await repo.exportToCsv(reportData));
          break;
        case ExportFileFormat.txt:
          file = File('${directory.path}/contagem_$timestamp.txt');
          await file.writeAsString(
            await repo.exportToCsv(reportData, delimiter: ';'),
          );
          break;
        case ExportFileFormat.xlsx:
          file = File('${directory.path}/contagem_$timestamp.xlsx');
          await file.writeAsBytes(await repo.exportToExcel(reportData));
          break;
      }

      if (!mounted) {
        return;
      }

      navigator.pop();

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Relatorio de Auditoria de Estoque',
          text: 'Relatorio exportado em ${format.name.toUpperCase()}',
        ),
      );

      if (!mounted) {
        return;
      }

      if (result.status == ShareResultStatus.success) {
        _savedContagemId ??= await repo.saveContagem(
          widget.currentCount,
          observacoes: _notesController.text.trim(),
          checklist: _checklistAnswers.entries
              .map((entry) => {
                    'question': entry.key,
                    'answer': entry.value,
                  })
              .toList(),
          photoPaths: _photoPaths,
        );

        if (!mounted) {
          return;
        }

        messenger.showSnackBar(
          const SnackBar(content: Text('Exportacao concluida com sucesso!')),
        );
        navigator.pop(true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao exportar: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatorio de Divergencias')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: context
            .read<ProductsRepository>()
            .buildReportData(widget.currentCount),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? const <Map<String, dynamic>>[];
          if (data.isEmpty) {
            return const Center(child: Text('Nenhum dado para exibir.'));
          }

          final total = data.length;
          final pendentes =
              data.where((item) => item['status'] == 'Pendente').length;
          final divergencias =
              data.where((item) => (item['diferenca'] as num).abs() > 0).length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SummaryChip(label: 'Itens', value: '$total'),
                  _SummaryChip(label: 'Pendentes', value: '$pendentes'),
                  _SummaryChip(label: 'Divergencias', value: '$divergencias'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Checklist de auditoria',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._questions.map(
                (question) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(question),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'Sim', label: Text('Sim')),
                            ButtonSegment(value: 'Nao', label: Text('Nao')),
                            ButtonSegment(value: 'N/A', label: Text('N/A')),
                          ],
                          selected: {_checklistAnswers[question] ?? 'N/A'},
                          onSelectionChanged: (selection) {
                            setState(() {
                              _checklistAnswers[question] = selection.first;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observacoes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _capturePhoto,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Tirar foto'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickPhotos,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Selecionar arquivo'),
                    ),
                  ),
                ],
              ),
              if (_photoPaths.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${_photoPaths.length} foto(s) anexada(s)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                ..._photoPaths.map(
                  (path) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.image_outlined),
                    title: Text(path.split(Platform.pathSeparator).last),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() {
                          _photoPaths.remove(path);
                        });
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Itens auditados',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...data.map((item) {
                final hasDivergence = (item['diferenca'] as num).abs() > 0;
                final isPending = item['status'] == 'Pendente';

                return Card(
                  color: isPending
                      ? Colors.orange.shade50
                      : hasDivergence
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                  child: ListTile(
                    title: Text('${item['nome']} (${item['barcode']})'),
                    subtitle: Text(
                      'Esperado: ${item['esperado']} | '
                      'Contado: ${item['contado']}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item['status'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Dif: ${item['diferenca']}'),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _exportData(context, ExportFileFormat.csv),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Exportar CSV'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _exportData(context, ExportFileFormat.txt),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Exportar TXT'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _exportData(context, ExportFileFormat.xlsx),
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('Exportar XLSX'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      avatar: const Icon(Icons.assessment_outlined, size: 18),
    );
  }
}
