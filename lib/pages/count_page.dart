import 'package:auditoria/model/produto.dart';
import 'package:auditoria/pages/audit_report_page.dart';
import 'package:auditoria/repostiories/products_repository.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CountPage extends StatefulWidget {
  const CountPage({super.key});

  @override
  State<CountPage> createState() => _CountPageState();
}

class _CountPageState extends State<CountPage> {
  final Map<String, double> _currentCount = {};
  final TextEditingController _quantityController =
      TextEditingController(text: '1');
  final TextEditingController _barcodeController = TextEditingController();

  Future<void> _scanBarcode() async {
    try {
      final result = await BarcodeScanner.scan();
      if (!mounted || result.rawContent.isEmpty) {
        return;
      }

      _barcodeController.text = result.rawContent;
      await _prepareBarcode(result.rawContent);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao escanear: $error')),
      );
    }
  }

  Future<void> _prepareBarcode(String barcode) async {
    final repo = context.read<ProductsRepository>();
    final scaleData = repo.parseScaleBarcode(barcode);

    if (scaleData != null) {
      final code = scaleData['productCode'] as String;
      final weight = scaleData['weight'] as double;
      final produto = await repo.getProductByBarcodeOrInternalCode(code);

      if (!mounted) {
        return;
      }

      if (produto == null) {
        _showQuickRegisterDialog(
          barcode,
          suggestedInternalCode: code,
          suggestedQuantity: weight,
        );
        return;
      }

      setState(() {
        _barcodeController.text = produto.codigoBarras;
        _quantityController.text = weight.toString();
      });
      return;
    }

    final produto = await repo.getProductByBarcodeOrInternalCode(barcode);

    if (!mounted) {
      return;
    }

    if (produto == null) {
      _showQuickRegisterDialog(
        barcode,
        suggestedQuantity: _currentQuantityOrDefault(),
      );
      return;
    }

    setState(() {
      _barcodeController.text = produto.codigoBarras;
    });
  }

  Future<void> _addCurrentBarcode() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) {
      return;
    }

    final repo = context.read<ProductsRepository>();
    final produto = await repo.getProductByBarcodeOrInternalCode(barcode);

    if (!mounted) {
      return;
    }

    if (produto == null) {
      _showQuickRegisterDialog(
        barcode,
        suggestedQuantity: _currentQuantityOrDefault(),
      );
      return;
    }

    _addCount(
      produto.codigoBarras,
      _currentQuantityOrDefault(),
    );
  }

  double _currentQuantityOrDefault() {
    return double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 1;
  }

  void _showQuickRegisterDialog(
    String barcode, {
    String? suggestedInternalCode,
    double suggestedQuantity = 1,
  }) {
    final nameController = TextEditingController();
    final internalCodeController =
        TextEditingController(text: suggestedInternalCode ?? '');

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Produto nao encontrado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Codigo lido: $barcode'),
            TextField(
              controller: internalCodeController,
              decoration: const InputDecoration(labelText: 'Codigo interno'),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome do produto'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                return;
              }

              final repo = context.read<ProductsRepository>();
              final savedBarcode = suggestedInternalCode ?? barcode;

              await repo.insertProduct(
                Produto(
                  codigoBarras: savedBarcode,
                  codigoInterno: internalCodeController.text.trim().isEmpty
                      ? null
                      : internalCodeController.text.trim(),
                  nome: nameController.text.trim(),
                ),
              );

              if (!mounted) {
                return;
              }

              if (!dialogContext.mounted) {
                return;
              }

              Navigator.of(dialogContext).pop();
              setState(() {
                _barcodeController.text = savedBarcode;
                _quantityController.text = suggestedQuantity.toString();
              });
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _addCount(String barcode, double quantity) {
    setState(() {
      _currentCount.update(
        barcode,
        (existingQty) => existingQty + quantity,
        ifAbsent: () => quantity,
      );
      _barcodeController.clear();
      _quantityController.text = '1';
    });
  }

  Future<void> _finalizeContagem() async {
    if (_currentCount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum item contado.')),
      );
      return;
    }

    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AuditReportPage(currentCount: _currentCount),
      ),
    );

    if (completed == true) {
      setState(() {
        _currentCount.clear();
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoria de Estoque'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _barcodeController,
                            decoration: const InputDecoration(
                              hintText: 'Codigo de barras ou interno',
                              labelText: 'Codigo',
                            ),
                            onSubmitted: (value) async {
                              if (value.isNotEmpty) {
                                await _prepareBarcode(value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _quantityController,
                            decoration: const InputDecoration(labelText: 'QTD'),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _scanBarcode,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Scanner'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              if (_barcodeController.text.isNotEmpty) {
                                await _addCurrentBarcode();
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Adicionar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Itens contados na sessao: ${_currentCount.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _currentCount.isEmpty
                  ? const Center(
                      child:
                          Text('Escaneie ou informe um codigo para iniciar.'),
                    )
                  : ListView.builder(
                      itemCount: _currentCount.length,
                      itemBuilder: (context, index) {
                        final entry = _currentCount.entries.elementAt(index);
                        return FutureBuilder<Produto?>(
                          future: context
                              .read<ProductsRepository>()
                              .getProductByBarcodeOrInternalCode(entry.key),
                          builder: (context, snapshot) {
                            final product = snapshot.data;
                            final productName = product?.nome ?? 'Desconhecido';

                            return Card(
                              child: ListTile(
                                title: Text('$productName (${entry.key})'),
                                subtitle: Text('Contado: ${entry.value}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    setState(() {
                                      _currentCount.remove(entry.key);
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _finalizeContagem,
                child: const Text('Finalizar e auditar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
