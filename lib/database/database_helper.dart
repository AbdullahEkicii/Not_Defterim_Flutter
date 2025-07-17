import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';
import '../models/weekly_task.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String documentsPath = await getDatabasesPath();
    String path = join(documentsPath, 'notes.db'); // Veritabanı dosyası adı

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Veritabanı oluşturulurken tabloları oluştur
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        content TEXT,
        date TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE weekly_tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dayOfWeek TEXT,
        taskDescription TEXT,
        isCompleted INTEGER
      )
    ''');
  }

  // Veritabanı güncellenirken (versiyon artınca) yeni tabloları ekle
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE weekly_tasks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          dayOfWeek TEXT,
          taskDescription TEXT,
          isCompleted INTEGER
        ) 
      ''');
    }
  }

  // Not ekleme
  Future<int> insertNote(Note note) async {
    Database db = await database;
    return await db.insert('notes', note.toMap());
  }

  // Tüm notları listeleme
  Future<List<Note>> getNotes() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'notes',
      orderBy: 'id DESC',
    ); // En son eklenen üste gelsin
    return List.generate(maps.length, (i) {
      return Note.fromMap(maps[i]);
    });
  }

  // Not güncelleme
  Future<int> updateNote(Note note) async {
    Database db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // Not silme
  Future<int> deleteNote(int id) async {
    Database db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // Haftalık görev ekleme
  Future<int> insertWeeklyTask(WeeklyTask task) async {
    Database db = await database;
    return await db.insert('weekly_tasks', task.toMap());
  }

  // Belirli bir güne ait haftalık görevleri getirme
  Future<List<WeeklyTask>> getWeeklyTasksByDay(String dayOfWeek) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'weekly_tasks',
      where: 'dayOfWeek = ?',
      whereArgs: [dayOfWeek],
      orderBy: 'id ASC',
    );
    return List.generate(maps.length, (i) {
      return WeeklyTask.fromMap(maps[i]);
    });
  }

  // Haftalık görevi güncelleme
  Future<int> updateWeeklyTask(WeeklyTask task) async {
    Database db = await database;
    return await db.update(
      'weekly_tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // Haftalık görevi silme
  Future<int> deleteWeeklyTask(int id) async {
    Database db = await database;
    return await db.delete('weekly_tasks', where: 'id = ?', whereArgs: [id]);
  }
}
