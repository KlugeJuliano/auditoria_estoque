import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Configurações'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => {},
                    child: const Text('Importar cadastro'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ultima atualização: ',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Exportar contagem'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ///lastExport.toString(),
                    'Ultima exportação',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              )
            ],
          ),
        ));
  }
}
