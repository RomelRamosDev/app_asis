import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'empleado_model.dart';
import 'aistencia_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'empleados.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE empleados(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT,
        apellido TEXT,
        cedula TEXT UNIQUE,
        cargo TEXT,
        facialDataPath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE asistencias(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cedulaEmpleado TEXT,
        horaEntrada TEXT,
        horaSalida TEXT,
        FOREIGN KEY (cedulaEmpleado) REFERENCES empleados(cedula)
      )
    ''');
  }

// Método para manejar la migración de la base de datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE empleados ADD COLUMN facialDataPath TEXT');
    }
  }

  // Métodos para empleados
  Future<int> insertEmpleado(Empleado empleado) async {
    final db = await database;
    return await db.insert('empleados', empleado.toMap());
  }

  Future<List<Empleado>> getEmpleados() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('empleados');
    return List.generate(maps.length, (i) {
      return Empleado.fromMap(maps[i]);
    });
  }

  // Métodos para asistencias
  Future<int> insertAsistencia(Asistencia asistencia) async {
    final db = await database;
    return await db.insert('asistencias', asistencia.toMap());
  }

  Future<List<Asistencia>> getAsistencias() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('asistencias');
    return List.generate(maps.length, (i) {
      return Asistencia.fromMap(maps[i]);
    });
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'empleados.db');
    await databaseFactory
        .deleteDatabase(path); // Usa databaseFactory.deleteDatabase
    print('Base de datos eliminada: $path');
  }
}
