class Food {
  final int id;
  final String name;
  final String brand;
  final double protein;
  final double carbs;
  final double fat;
  final double calories;
  final double servingSize;
  final String servingUnits;

  Food({
    required this.id,
    required this.name,
    required this.brand,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calories,
    required this.servingSize,
    required this.servingUnits,
  });

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      id: map['id'],
      name: map['name'],
      brand: map['brand'],
      protein: map['protein'],
      carbs: map['carbs'],
      fat: map['fat'],
      calories: map['calories'],
      servingSize: map['servingSize'],
      servingUnits: map['servingUnits'],
    );
  }
}
