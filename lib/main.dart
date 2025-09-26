import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vdmc/constants.dart';
import 'package:vdmc/utils.dart';

import 'models/macro_goals.dart';
import 'services/preferences_service.dart';
import 'screens/set_goals_screen.dart';
import 'screens/add_food_screen.dart';
import 'models/food.dart';
import 'models/logged_food.dart';
import 'services/database_service.dart';
import 'screens/log_food_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

void main() {
  // Initialize FFI for desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(MacroCounterApp());
}

class MacroCounterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Very Dumb Macro Counter',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MacroGoals? goals;
  final _prefs = PreferencesService();
  final _db = DatabaseService();
  List<LoggedFood> _todayLogs = [];
  Map<int, Food> _foodsById = {};
  double _totalProtein = 0;
  double _totalCarbs = 0;
  double _totalFat = 0;
  double _totalCalories = 0;

  @override
  void initState() {
    super.initState();
    _loadGoals();
    _loadTodayLogs();
  }

  void _loadTodayLogs() async {
    final logs = await _db.getLoggedFoodsByDate(DateTime.now());
    final foods = await _db.getAllFoods();
    final foodMap = {for (var f in foods) f.id: f};

    double protein = 0, carbs = 0, fat = 0, calories = 0;

    for (var log in logs) {
      final food = foodMap[log.foodId]!;
      protein += food.protein * log.servings;
      carbs += food.carbs * log.servings;
      fat += food.fat * log.servings;
      calories += food.calories * log.servings;
    }

    setState(() {
      _todayLogs = logs;
      _foodsById = foodMap;
      _totalProtein = protein;
      _totalCarbs = carbs;
      _totalFat = fat;
      _totalCalories = calories;
    });
  }

  double _calculateCalories(MacroGoals g) {
    return (g.protein * MacroCalories.protein) +
        (g.carbs * MacroCalories.carbs) +
        (g.fat * MacroCalories.fat);
  }

  void _loadGoals() async {
    final loaded = await _prefs.loadGoals();
    setState(() {
      goals = loaded;
    });
  }

  void _openLogFood() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LogFoodScreen()),
    );
    _loadTodayLogs(); // refresh after returning
  }

  void _openSetGoals() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SetGoalsScreen()),
    );
    if (result != null) {
      setState(() => goals = result);
    }
  }

  void _openAddFood() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddFoodScreen()),
    );
  }

  void _deleteLog(LoggedFood log) async {
    await _db.deleteLoggedFood(log.id);
    setState(() {
      _todayLogs.remove(log);
      // Recalculate totals
      _totalProtein -= (_foodsById[log.foodId]?.protein ?? 0) * log.servings;
      _totalCarbs -= (_foodsById[log.foodId]?.carbs ?? 0) * log.servings;
      _totalFat -= (_foodsById[log.foodId]?.fat ?? 0) * log.servings;
      _totalCalories -= (_foodsById[log.foodId]?.calories ?? 0) * log.servings;
    });
  }

  Widget _buildMacroProgress(
    String label,
    double current,
    double goal, {
    bool horizontal = false,
  }) {
    final percent = (goal > 0) ? (current / goal).clamp(0.0, 1.0) : 0.0;

    if (horizontal) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 12)),
          SizedBox(height: 4),
          LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            color: current > goal ? Colors.red : _getMacroColor(label),
          ),
          SizedBox(height: 2),
          Text(
            "${formatDouble(current)} / ${formatDouble(goal)} ${_getMacroUnit(label)}",
            style: TextStyle(fontSize: 10),
          ),
        ],
      );
    } else {
      // Original vertical layout
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "$label: ${formatDouble(current)} / ${formatDouble(goal)} ${_getMacroUnit(label)}",
            ),
            SizedBox(height: 4),
            LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              color: current > goal ? Colors.red : _getMacroColor(label),
            ),
          ],
        ),
      );
    }
  }

  Color _getMacroColor(String macro) {
    switch (macro) {
      case "Protein":
        return Colors.blue;
      case "Carbs":
        return Colors.pink;
      case "Fat":
        return Colors.yellow;
      case "Calories":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getMacroUnit(String macro) {
    switch (macro) {
      case "Protein":
        return "g";
      case "Carbs":
        return "g";
      case "Fat":
        return "g";
      case "Calories":
        return "kcal";
      default:
        return "unit";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Very Dumb Macro Counter"),
        actions: [
          IconButton(
            icon: Icon(Icons.flag),
            tooltip: "Set Goals",
            onPressed: _openSetGoals,
          ),
          IconButton(
            icon: Icon(Icons.post_add),
            tooltip: "Add Food",
            onPressed: _openAddFood,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openLogFood,
        tooltip: 'Log Food',
        child: Icon(Icons.add),
      ),

      body: Center(
        child: goals == null
            ? Text("No goals set yet")
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildMacroProgress(
                    "Calories",
                    _totalCalories,
                    _calculateCalories(goals!),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                    ), // match your column padding
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMacroProgress(
                            "Carbs",
                            _totalCarbs,
                            goals!.carbs,
                            horizontal: true,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildMacroProgress(
                            "Protein",
                            _totalProtein,
                            goals!.protein,
                            horizontal: true,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildMacroProgress(
                            "Fat",
                            _totalFat,
                            goals!.fat,
                            horizontal: true,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12),
                  if (_todayLogs.isNotEmpty)
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: _todayLogs.map((log) {
                            final food = _foodsById[log.foodId]!;
                            return ListTile(
                              title: Text(
                                "${food.name}: ${formatDouble(log.servings * food.servingSize)} ${food.servingUnits}",
                              ),
                              subtitle: Text(
                                "Brand: ${food.brand}\nCalories: ${formatDouble(food.calories * log.servings)} kcal, Carbs: ${formatDouble(food.carbs * log.servings)} g, Protein: ${formatDouble(food.protein * log.servings)} g, Fat: ${formatDouble(food.fat * log.servings)} g",
                              ),
                              leading: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteLog(log),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
