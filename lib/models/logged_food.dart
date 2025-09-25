class LoggedFood {
  final int id;
  final int foodId;
  final double servings;
  final DateTime date;

  LoggedFood({
    required this.id,
    required this.foodId,
    required this.servings,
    required this.date,
  });

  factory LoggedFood.fromMap(Map<String, dynamic> map) {
    return LoggedFood(
      id: map['id'],
      foodId: map['foodId'],
      servings: map['servings'],
      date: DateTime.parse(map['date']),
    );
  }
}
