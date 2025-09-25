import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/food.dart';
import '../models/logged_food.dart';

class DatabaseService {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'macros.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create the foods table
        await db.execute('''
        CREATE TABLE foods(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          brand TEXT,
          protein REAL NOT NULL,
          carbs REAL NOT NULL,
          fat REAL NOT NULL,
          calories REAL NOT NULL,
          servingSize REAL NOT NULL,
          servingUnits TEXT NOT NULL
        )
      ''');

        // Create the logged_foods table
        await db.execute('''
        CREATE TABLE logged_foods(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          foodId INTEGER NOT NULL,
          servings REAL NOT NULL,
          date TEXT NOT NULL,
          FOREIGN KEY(foodId) REFERENCES foods(id)
        )
      ''');
      },
    );
  }

  // === Foods ===
  Future<void> insertFood(Food food) async {
    final db = await database;
    await db.insert('foods', {
      'name': food.name,
      'brand': food.brand,
      'protein': food.protein,
      'carbs': food.carbs,
      'fat': food.fat,
      'calories': food.calories, // <--- include this
      'servingSize': food.servingSize, // <--- include this
      'servingUnits': food.servingUnits, // <--- include this
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteFood(int foodId) async {
    final db = await database;

    // First delete all logs that reference this food
    await db.delete('logged_foods', where: 'foodId = ?', whereArgs: [foodId]);

    // Then delete the food itself
    await db.delete('foods', where: 'id = ?', whereArgs: [foodId]);
  }

  Future<List<Food>> getAllFoods() async {
    final db = await database;
    final result = await db.query('foods');
    return result.map((row) => Food.fromMap(row)).toList();
  }

  // === Logs ===

  Future<void> insertLoggedFood(LoggedFood log) async {
    final db = await database;
    await db.insert('logged_foods', {
      'foodId': log.foodId,
      'servings': log.servings,
      'date': log.date.toIso8601String(),
    });
  }

  // query logs for a specific date
  Future<List<LoggedFood>> getLoggedFoodsByDate(DateTime date) async {
    final db = await database;
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(Duration(days: 1));

    final maps = await db.query(
      'logged_foods',
      where: 'date >= ? AND date < ?',
      whereArgs: [dayStart.toIso8601String(), dayEnd.toIso8601String()],
    );

    return maps.map((m) => LoggedFood.fromMap(m)).toList();
  }

  Future<void> deleteLoggedFood(int id) async {
    final db = await database;
    await db.delete('logged_foods', where: 'id = ?', whereArgs: [id]);
  }
}
