import 'package:flutter/material.dart';
import 'package:vdmc/utils.dart';
import '../models/food.dart';
import '../models/logged_food.dart';
import '../services/database_service.dart';

class LogFoodScreen extends StatefulWidget {
  @override
  _LogFoodScreenState createState() => _LogFoodScreenState();
}

class _LogFoodScreenState extends State<LogFoodScreen> {
  final _db = DatabaseService();
  List<Food> _allFoods = [];
  Map<int, Food> _foodsById = {};
  int? _selectedFoodId;
  Food? get _selectedFood => _foodsById[_selectedFoodId];

  final _amountController = TextEditingController();
  double _currentProtein = 0;
  double _currentCarbs = 0;
  double _currentFat = 0;
  double _currentCalories = 0;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadFoods();
    _amountController.addListener(_updateMacros);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _loadFoods() async {
    final foods = await _db.getAllFoods();
    setState(() {
      _allFoods = foods;
      _foodsById = {for (var f in foods) f.id: f};
    });
  }

  void _updateMacros() {
    if (_selectedFood == null) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    final servings = amount / (_selectedFood?.servingSize ?? 1);

    setState(() {
      _currentProtein = (_selectedFood?.protein ?? 0) * servings;
      _currentCarbs = (_selectedFood?.carbs ?? 0) * servings;
      _currentFat = (_selectedFood?.fat ?? 0) * servings;
      _currentCalories = (_selectedFood?.calories ?? 0) * servings;
    });
  }

  void _saveLog() async {
    if (_selectedFood == null) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    final servings = amount / (_selectedFood?.servingSize ?? 1);

    final log = LoggedFood(
      id: 0,
      foodId: _selectedFood!.id,
      servings: servings,
      date: DateTime.now(),
    );

    await _db.insertLoggedFood(log);

    if (!mounted) return; // <-- Prevents the crash if screen was closed

    Navigator.pop(context);
  }

  Future<void> _deleteFood(Food food) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete ${food.name}?"),
        content: Text(
          "Are you sure you want to permanently delete this food from your database?",
        ),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteFood(food.id);
      setState(() {
        _allFoods.removeWhere((f) => f.id == food.id);
        _foodsById.remove(food.id);
        if (_selectedFoodId == food.id) {
          _selectedFoodId = null;
          _amountController.clear();
          _currentProtein = 0;
          _currentCarbs = 0;
          _currentFat = 0;
          _currentCalories = 0;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFoods = _allFoods
        .where(
          (f) =>
              f.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              f.brand.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text("Log Food")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              decoration: InputDecoration(
                labelText: "Search Foods",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            SizedBox(height: 12),

            // Scrollable list of foods
            Expanded(
              child: ListView.builder(
                itemCount: filteredFoods.length,
                itemBuilder: (context, index) {
                  final food = filteredFoods[index];
                  final isSelected = food.id == _selectedFoodId;
                  return Card(
                    color: isSelected ? Colors.blue.shade50 : null,
                    child: ListTile(
                      title: Text(
                        food.name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Brand: ${food.brand}\nServing: ${formatDouble(food.servingSize)} ${food.servingUnits}\nCalories: ${formatDouble(food.calories)} kcal, Carbs: ${formatDouble(food.carbs)} g, Protein: ${formatDouble(food.protein)} g, Fat: ${formatDouble(food.fat)} g",
                      ),
                      onTap: () {
                        setState(() {
                          _selectedFoodId = food.id;
                          _amountController.text = formatDouble(
                            food.servingSize,
                          );
                          _updateMacros();
                        });
                      },
                      leading: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteFood(food),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Amount entry + macros
            if (_selectedFood != null) ...[
              SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Amount (${_selectedFood!.servingUnits})",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Protein: ${formatDouble(_currentProtein)} g, "
                    "Carbs: ${formatDouble(_currentCarbs)} g, "
                    "Fat: ${formatDouble(_currentFat)} g, "
                    "Calories: ${formatDouble(_currentCalories)} kcal",
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _saveLog, child: Text("Log Food")),
            ],
          ],
        ),
      ),
    );
  }
}
