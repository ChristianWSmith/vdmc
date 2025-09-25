import 'package:shared_preferences/shared_preferences.dart';
import '../models/macro_goals.dart';

class PreferencesService {
  Future<void> saveGoals(MacroGoals goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('protein', goals.protein);
    await prefs.setDouble('carbs', goals.carbs);
    await prefs.setDouble('fat', goals.fat);
    await prefs.setDouble('calories', goals.calories);
  }

  Future<MacroGoals?> loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final protein = prefs.getDouble('protein');
    final carbs = prefs.getDouble('carbs');
    final fat = prefs.getDouble('fat');
    final calories = prefs.getDouble('calories');

    if (protein != null && carbs != null && fat != null && calories != null) {
      return MacroGoals(
        protein: protein,
        carbs: carbs,
        fat: fat,
        calories: calories,
      );
    }
    return MacroGoals(protein: 100, carbs: 225, fat: 60, calories: 2000);
  }
}
