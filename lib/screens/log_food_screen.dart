import 'package:flutter/material.dart';
import '../models/food.dart';
import '../models/logged_food.dart';
import '../services/database_service.dart';

class LogFoodScreen extends StatefulWidget {
  @override
  _LogFoodScreenState createState() => _LogFoodScreenState();
}

class _LogFoodScreenState extends State<LogFoodScreen> {
  final _db = DatabaseService();
  int? _selectedFoodId;
  Food? get _selectedFood =>
      _foodsById[_selectedFoodId]; // optional convenience getter
  Map<int, Food> _foodsById = {};

  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Log Food")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            FutureBuilder<List<Food>>(
              future: _db.getAllFoods(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final foods = snapshot.data!;
                for (var f in foods) {
                  _foodsById[f.id] = f;
                }

                return DropdownButton<int>(
                  hint: Text("Select Food"),
                  value: _selectedFoodId,
                  isExpanded: true,
                  items: foods
                      .map(
                        (f) => DropdownMenuItem(
                          value: f.id, // use ID here
                          child: Text(
                            "${f.name} (${f.servingSize}${f.servingUnits})",
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (id) {
                    setState(() {
                      _selectedFoodId = id;
                      _amountController.text = _selectedFood != null
                          ? _selectedFood!.servingSize.toString()
                          : '';
                    });
                  },
                );
              },
            ),
            SizedBox(height: 12),
            if (_selectedFood != null)
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Amount in ${_selectedFood!.servingUnits}",
                ),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectedFood == null ? null : _saveLog,
              child: Text("Log Food"),
            ),
          ],
        ),
      ),
    );
  }

  void _saveLog() async {
    final amount = double.tryParse(_amountController.text) ?? 0;

    // Convert to "servings" based on food's serving size
    final servings = amount / (_selectedFood?.servingSize ?? 1);

    final log = LoggedFood(
      id: 0,
      foodId: _selectedFood!.id,
      servings: servings,
      date: DateTime.now(),
    );

    await _db.insertLoggedFood(log);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Logged ${_selectedFood!.name}")));
    Navigator.pop(context);
  }
}
