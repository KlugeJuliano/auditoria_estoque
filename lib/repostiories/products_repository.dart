import 'dart:convert';
import 'dart:io';

import 'package:auditoria/model/produto.dart';
import 'package:auditoria/service/database_service.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

enum ExportFileFormat { csv, txt, xlsx }

class ProductsRepository extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  Future<List<Produto>> getAllProducts() async {
    final db = await _dbService.database;
    final maps = await db.query('produtos', orderBy: 'nome COLLATE NOCASE');
    return List.generate(maps.length, (index) => Produto.fromMap(maps[index]));
  }

  Future<Produto?> getProductByBarcode(String barcode) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'produtos',
      where: 'codigoBarras = ?',
      whereArgs: [barcode],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return Produto.fromMap(maps.first);
  }

  Future<Produto?> getProductByBarcodeOrInternalCode(String code) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'produtos',
      where: 'codigoBarras = ? OR codigoInterno = ?',
      whereArgs: [code, code],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return Produto.fromMap(maps.first);
  }

  Future<void> insertProduct(Produto produto) async {
    final db = await _dbService.database;
    await db.insert(
      'produtos',
      produto.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
  }

  Future<int> importProducts(File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    late final int importedCount;

    switch (extension) {
      case 'csv':
        importedCount = await importFromSeparatedText(
          file,
          _detectDelimiter(await file.readAsString()),
        );
        break;
      case 'txt':
        importedCount = await importFromSeparatedText(
          file,
          _detectDelimiter(await file.readAsString()),
        );
        break;
      case 'xlsx':
        importedCount = await importFromExcel(file);
        break;
      default:
        throw UnsupportedError(
            'Formato .$extension nao suportado para importacao.');
    }

    notifyListeners();
    return importedCount;
  }

  Future<int> importFromSeparatedText(File file, String delimiter) async {
    final content = await file.readAsString();
    final fields = Csv(
      fieldDelimiter: delimiter,
      dynamicTyping: false,
      lineDelimiter: '\n',
    ).decode(
      content,
    );

    return _persistImportedRows(fields);
  }

  Future<int> importFromExcel(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.firstOrNull;

    if (sheet == null) {
      throw StateError('Planilha vazia.');
    }

    final rows = sheet.rows
        .map(
          (row) => row.map((cell) => cell?.value?.toString() ?? '').toList(),
        )
        .toList();

    return _persistImportedRows(rows);
  }

  Future<int> _persistImportedRows(List<List<dynamic>> rows) async {
    if (rows.isEmpty) {
      return 0;
    }

    var importedCount = 0;
    final startIndex = _looksLikeHeader(rows.first) ? 1 : 0;

    for (var index = startIndex; index < rows.length; index++) {
      final row = rows[index];
      if (row.length < 3) {
        continue;
      }

      final barcode = _normalizeCell(row.elementAtOrNull(0));
      final internalCode = _normalizeCell(row.elementAtOrNull(1));
      final name = _normalizeCell(row.elementAtOrNull(2));
      final expectedQty = double.tryParse(
            _normalizeNumberCell(row.elementAtOrNull(3), fallback: '0'),
          ) ??
          0;

      if (barcode.isEmpty || name.isEmpty) {
        continue;
      }

      await _upsertProduct(
        Produto(
          codigoBarras: barcode,
          codigoInterno: internalCode.isEmpty ? null : internalCode,
          nome: name,
          quantidadeEsperada: expectedQty,
        ),
      );
      importedCount++;
    }

    return importedCount;
  }

  Future<void> _upsertProduct(Produto produto) async {
    final db = await _dbService.database;
    await db.insert(
      'produtos',
      produto.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Map<String, dynamic>? parseScaleBarcode(String barcode) {
    if (barcode.length != 13 || !barcode.startsWith(RegExp(r'^2[0-9]'))) {
      return null;
    }

    final productCode = barcode.substring(2, 7);
    final payload = barcode.substring(7, 12);
    final weight = (double.tryParse(payload) ?? 0) / 1000;

    return {
      'productCode': productCode,
      'weight': weight,
      'prefix': barcode.substring(0, 2),
    };
  }

  Future<List<Map<String, dynamic>>> buildReportData(
    Map<String, double> currentCount,
  ) async {
    final products = await getAllProducts();
    final report = <Map<String, dynamic>>[];
    final unmatchedCounts = Map<String, double>.from(currentCount);

    for (final produto in products) {
      final counted = unmatchedCounts.remove(produto.codigoBarras) ?? 0;
      final difference = counted - produto.quantidadeEsperada;

      report.add({
        'barcode': produto.codigoBarras,
        'nome': produto.nome,
        'esperado': produto.quantidadeEsperada,
        'contado': counted,
        'diferenca': difference,
        'status': counted > 0 ? 'Conferido' : 'Pendente',
        'produtoId': produto.id,
      });
    }

    for (final entry in unmatchedCounts.entries) {
      final produto = await getProductByBarcodeOrInternalCode(entry.key);
      final barcode = produto?.codigoBarras ?? entry.key;
      final esperado = produto?.quantidadeEsperada ?? 0;
      final difference = entry.value - esperado;

      report.add({
        'barcode': barcode,
        'nome': produto?.nome ?? 'Desconhecido',
        'esperado': esperado,
        'contado': entry.value,
        'diferenca': difference,
        'status': entry.value > 0 ? 'Conferido' : 'Pendente',
        'produtoId': produto?.id,
      });
    }

    return report;
  }

  Future<int> saveContagem(
    Map<String, double> items, {
    String observacoes = '',
    List<Map<String, String>> checklist = const [],
    List<String> photoPaths = const [],
  }) async {
    final db = await _dbService.database;
    final reportItems = await buildReportData(items);

    final contagemId = await db.transaction((txn) async {
      final id = await txn.insert('contagens', {
        'data': DateTime.now().toIso8601String(),
        'status': 1,
        'observacoes': observacoes,
        'checklistJson': jsonEncode(checklist),
        'fotosJson': jsonEncode(photoPaths),
      });

      for (final item in reportItems) {
        await txn.insert('itens_contagem', {
          'contagemId': id,
          'produtoId': item['produtoId'],
          'codigoBarras': item['barcode'],
          'nomeProduto': item['nome'],
          'quantidadeEsperada': item['esperado'],
          'quantidadeContada': item['contado'],
          'diferenca': item['diferenca'],
          'status': item['status'],
        });
      }

      return id;
    });

    notifyListeners();
    return contagemId;
  }

  Future<String> exportToCsv(
    List<Map<String, dynamic>> items, {
    String delimiter = ',',
  }) async {
    final rows = _buildExportRows(items);
    return Csv(fieldDelimiter: delimiter).encode(rows);
  }

  Future<List<int>> exportToExcel(List<Map<String, dynamic>> items) async {
    final excel = Excel.createExcel();
    final sheet = excel['Relatorio'];
    final rows = _buildExportRows(items);

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      for (var columnIndex = 0; columnIndex < row.length; columnIndex++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: columnIndex,
                rowIndex: rowIndex,
              ),
            )
            .value = TextCellValue(row[columnIndex].toString());
      }
    }

    return excel.encode() ?? <int>[];
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final db = await _dbService.database;
    final history = await db.rawQuery('''
      SELECT
        c.id,
        c.data,
        c.status,
        c.observacoes,
        c.checklistJson,
        c.fotosJson,
        COUNT(i.id) AS totalItens,
        SUM(CASE WHEN i.status = 'Pendente' THEN 1 ELSE 0 END) AS pendentes,
        SUM(CASE WHEN ABS(i.diferenca) > 0 THEN 1 ELSE 0 END) AS divergencias
      FROM contagens c
      LEFT JOIN itens_contagem i ON i.contagemId = c.id
      GROUP BY c.id
      ORDER BY c.data DESC
    ''');

    return history;
  }

  Future<Map<String, dynamic>?> getHistoryEntry(int contagemId) async {
    final db = await _dbService.database;
    final contagens = await db.query(
      'contagens',
      where: 'id = ?',
      whereArgs: [contagemId],
      limit: 1,
    );

    if (contagens.isEmpty) {
      return null;
    }

    final items = await db.query(
      'itens_contagem',
      where: 'contagemId = ?',
      whereArgs: [contagemId],
      orderBy: 'nomeProduto COLLATE NOCASE',
    );

    final contagem = Map<String, dynamic>.from(contagens.first);
    contagem['items'] = items;
    return contagem;
  }

  List<List<dynamic>> _buildExportRows(List<Map<String, dynamic>> items) {
    final rows = <List<dynamic>>[
      ['Codigo', 'Nome', 'Esperado', 'Contado', 'Diferenca', 'Status'],
    ];

    for (final item in items) {
      rows.add([
        item['barcode'],
        item['nome'],
        item['esperado'],
        item['contado'],
        item['diferenca'],
        item['status'],
      ]);
    }

    return rows;
  }

  String _detectDelimiter(String content) {
    final firstLine = content.split('\n').firstOrNull ?? '';
    if (firstLine.contains('\t')) {
      return '\t';
    }
    if (firstLine.contains(';')) {
      return ';';
    }
    return ',';
  }

  String _normalizeCell(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? fallback;
    if (text.endsWith('.0')) {
      return text.substring(0, text.length - 2);
    }
    return text;
  }

  String _normalizeNumberCell(dynamic value, {String fallback = ''}) {
    return _normalizeCell(value, fallback: fallback).replaceAll(',', '.');
  }

  bool _looksLikeHeader(List<dynamic> row) {
    final normalized =
        row.take(4).map((cell) => _normalizeCell(cell).toLowerCase()).toList();

    return normalized.any(
      (cell) =>
          cell.contains('codigo') ||
          cell.contains('barcode') ||
          cell.contains('produto') ||
          cell.contains('nome') ||
          cell.contains('quantidade') ||
          cell.contains('expected'),
    );
  }
}
