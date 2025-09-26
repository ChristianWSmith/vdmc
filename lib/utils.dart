String formatDouble(double value) {
  if (value == value.toInt().toDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}
