import 'package:flutter/material.dart';
import 'package:vdmc/constants.dart';
import '../models/food.dart';
import '../services/database_service.dart';

class AddFoodScreen extends StatefulWidget {
  @override
  _AddFoodScreenState createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _servingSizeController = TextEditingController();
  final _servingUnitsController = TextEditingController();
  final _caloriesController = TextEditingController();

  bool _overrideCalories = false;
  double _calories = 0;

  void _recalculateCalories() {
    if (_overrideCalories) return;

    final protein = double.tryParse(_proteinController.text) ?? 0;
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final fat = double.tryParse(_fatController.text) ?? 0;

    // precise Atwater factors
    final calc =
        (protein * MacroCalories.protein) +
        (carbs * MacroCalories.carbs) +
        (fat * MacroCalories.fat);

    setState(() {
      _calories = calc;
      _caloriesController.text = _calories.toStringAsFixed(0);
    });
  }

  void _saveFood() async {
    if (_formKey.currentState!.validate()) {
      final food = Food(
        id: 0, // let DB autoincrement
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        protein: double.tryParse(_proteinController.text) ?? 0,
        carbs: double.tryParse(_carbsController.text) ?? 0,
        fat: double.tryParse(_fatController.text) ?? 0,
        calories: double.tryParse(_caloriesController.text) ?? _calories,
        servingSize: double.tryParse(_servingSizeController.text) ?? 0,
        servingUnits: _servingUnitsController.text.trim(),
      );

      await _dbService.insertFood(food);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Food added: ${food.name}")));

      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    _proteinController.addListener(_recalculateCalories);
    _carbsController.addListener(_recalculateCalories);
    _fatController.addListener(_recalculateCalories);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Food")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Food Name"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter a name" : null,
              ),
              TextFormField(
                controller: _brandController,
                decoration: InputDecoration(labelText: "Brand (optional)"),
              ),
              TextFormField(
                controller: _proteinController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Protein (g)"),
              ),
              TextFormField(
                controller: _carbsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Carbs (g)"),
              ),
              TextFormField(
                controller: _fatController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Fat (g)"),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Calories (auto or override)",
                ),
                onTap: () {
                  setState(() {
                    _overrideCalories = true;
                  });
                },
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _servingSizeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "Serving Size"),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _servingUnitsController,
                      decoration: InputDecoration(
                        labelText: "Units (e.g. g, ml)",
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _saveFood, child: Text("Save Food")),
            ],
          ),
        ),
      ),
    );
  }
}
