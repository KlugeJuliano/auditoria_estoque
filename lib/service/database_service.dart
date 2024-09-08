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
    if (_database != null) return database!;
    _database = await _initDatabase();

    return database;
  }
}

Future<Database> _initDatabase() async {
  String path = join(await getDatabasesPath(), 'produtos.db');
  return await openDatabase(path, version: 1, onCreate: (db, version) async {
    await db.execute(
      'CREATE TABLE produtos(codigo TEXT PRIMARY KEY, descricao TEXT, complemento TEXT, marca TEXT)',
    );
  });
}
