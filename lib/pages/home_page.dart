import 'package:auditoria/pages/settings.dart';
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Map<String, int> _stockData = {};
  String _barcode = '';
  int _quantity = 0;

  Future<void> _scanBarcode() async {
    var result = await BarcodeScanner.scan();
    setState(() {
      _barcode = result.rawContent;
    });
  }

  void _addProduct() {
    if (_barcode.isNotEmpty && _quantity > 0) {
      setState(() {
        _stockData.update(_barcode, (existingQty) => existingQty + _quantity,
            ifAbsent: () => _quantity);
        _barcode = '';
        _quantity = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoria de Estoques'),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
              icon: const Icon(Icons.settings))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: _stockData.entries.map((entry) {
                  return ListTile(
                    title: Text('Código: ${entry.key}'),
                    subtitle: Text('Quantidade: ${entry.value}'),
                  );
                }).toList(),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 48,
                  width: MediaQuery.sizeOf(context).width / 1.4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: _barcode.isEmpty
                          ? 'Leia ou digite o código de barras'
                          : _barcode,
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'QTD'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _quantity = int.tryParse(value) ?? 0;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _scanBarcode,
                  child: const Text('Ler Código de Barras'),
                ),
                ElevatedButton(
                  onPressed: _addProduct,
                  child: const Text('Adicionar Produto'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
