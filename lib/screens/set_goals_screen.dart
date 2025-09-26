import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vdmc/constants.dart';
import 'package:vdmc/utils.dart';
import '../models/macro_goals.dart';
import '../services/preferences_service.dart';

class SetGoalsScreen extends StatefulWidget {
  @override
  _SetGoalsScreenState createState() => _SetGoalsScreenState();
}

class _SetGoalsScreenState extends State<SetGoalsScreen> {
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  double _calories = 0; // label value

  final _prefs = PreferencesService();

  @override
  void initState() {
    super.initState();

    // Add listeners to recalc when inputs change
    _proteinController.addListener(_recalculateCalories);
    _carbsController.addListener(_recalculateCalories);
    _fatController.addListener(_recalculateCalories);
  }

  @override
  void dispose() {
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _recalculateCalories() {
    final protein = double.tryParse(_proteinController.text) ?? 0;
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final fat = double.tryParse(_fatController.text) ?? 0;

    // Using the precise Atwater factors
    final calories =
        (protein * MacroCalories.protein) +
        (carbs * MacroCalories.carbs) +
        (fat * MacroCalories.fat);

    setState(() {
      _calories = calories;
    });
  }

  void _saveGoals() async {
    final goals = MacroGoals(
      protein: double.tryParse(_proteinController.text) ?? 0,
      carbs: double.tryParse(_carbsController.text) ?? 0,
      fat: double.tryParse(_fatController.text) ?? 0,
      calories: _calories,
    );

    await _prefs.saveGoals(goals);
    Navigator.pop(context, goals); // send goals back to home screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Set Macro Goals")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Calories: ${formatDouble(_calories)}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _carbsController,
              decoration: InputDecoration(labelText: "Carbs (g)"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _proteinController,
              decoration: InputDecoration(labelText: "Protein (g)"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _fatController,
              decoration: InputDecoration(labelText: "Fat (g)"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _saveGoals, child: Text("Save Goals")),
          ],
        ),
      ),
    );
  }
}
