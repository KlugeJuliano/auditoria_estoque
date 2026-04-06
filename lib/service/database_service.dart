import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  Database? _database;

  DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'auditoria.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE produtos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            codigoBarras TEXT UNIQUE,
            codigoInterno TEXT,
            nome TEXT,
            quantidadeEsperada REAL
          )
        ''');
        await db.execute('''
          CREATE TABLE contagens(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data TEXT,
            status INTEGER,
            observacoes TEXT,
            checklistJson TEXT,
            fotosJson TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE itens_contagem(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            contagemId INTEGER,
            produtoId INTEGER,
            codigoBarras TEXT,
            nomeProduto TEXT,
            quantidadeEsperada REAL,
            quantidadeContada REAL,
            diferenca REAL,
            status TEXT,
            FOREIGN KEY (contagemId) REFERENCES contagens (id),
            FOREIGN KEY (produtoId) REFERENCES produtos (id)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _addColumnIfNotExists(db, 'contagens', 'observacoes', 'TEXT');
          await _addColumnIfNotExists(
            db,
            'contagens',
            'checklistJson',
            'TEXT',
          );
          await _addColumnIfNotExists(db, 'contagens', 'fotosJson', 'TEXT');
          await _addColumnIfNotExists(
            db,
            'itens_contagem',
            'codigoBarras',
            'TEXT',
          );
          await _addColumnIfNotExists(
            db,
            'itens_contagem',
            'nomeProduto',
            'TEXT',
          );
          await _addColumnIfNotExists(
            db,
            'itens_contagem',
            'quantidadeEsperada',
            'REAL',
          );
          await _addColumnIfNotExists(db, 'itens_contagem', 'status', 'TEXT');
        }
      },
    );
  }

  Future<void> _addColumnIfNotExists(
    Database db,
    String tableName,
    String columnName,
    String columnType,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final alreadyExists = columns.any((column) => column['name'] == columnName);

    if (!alreadyExists) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnName $columnType',
      );
    }
  }
}
