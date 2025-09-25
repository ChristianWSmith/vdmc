import 'package:flutter/material.dart';
import 'models/macro_goals.dart';
import 'services/preferences_service.dart';
import 'screens/set_goals_screen.dart';

void main() {
  runApp(MacroCounterApp());
}

class MacroCounterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Macro Counter',
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

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  void _loadGoals() async {
    final loaded = await _prefs.loadGoals();
    setState(() {
      goals = loaded;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Macro Counter")),
      body: Center(
        child: goals == null
            ? Text("No goals set yet")
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Protein: ${goals!.protein} g"),
                  Text("Carbs: ${goals!.carbs} g"),
                  Text("Fat: ${goals!.fat} g"),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openSetGoals,
        child: Icon(Icons.edit),
      ),
    );
  }
}
