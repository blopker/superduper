String formatOdometerDistance(int meters) {
  if (meters < 0) {
    throw RangeError.value(meters, 'meters', 'Must not be negative.');
  }
  final kilometers = meters / 1000;
  final miles = meters / 1609.344;
  return '${kilometers.toStringAsFixed(1)} km · ${miles.toStringAsFixed(1)} mi';
}
