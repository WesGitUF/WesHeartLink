class HeartRateZone {
  final String name;
  final int min;
  final int max;
  final int colorValue;

  HeartRateZone({
    required this.name,
    required this.min,
    required this.max,
    required this.colorValue,
  });
}

/// Computes the heart rate zone based on the current heart rate [hr]
/// and the maximum heart rate [maxHR].
HeartRateZone getZoneForHR(int hr, int maxHR) {
  double percentage = (hr / maxHR) * 100;
  if (percentage <= 60) {
    return HeartRateZone(
      name: 'Zone 1',
      min: 0,
      max: (maxHR * 0.60).round(),
      colorValue: 0xFF0000FF, // Blue
    );
  } else if (percentage <= 70) {
    return HeartRateZone(
      name: 'Zone 2',
      min: ((maxHR * 0.60).round() + 1),
      max: (maxHR * 0.70).round(),
      colorValue: 0xFF00FF00, // Green
    );
  } else if (percentage <= 80) {
    return HeartRateZone(
      name: 'Zone 3',
      min: ((maxHR * 0.70).round() + 1),
      max: (maxHR * 0.80).round(),
      colorValue: 0xFFFFFF00, // Yellow
    );
  } else if (percentage <= 90) {
    return HeartRateZone(
      name: 'Zone 4',
      min: ((maxHR * 0.80).round() + 1),
      max: (maxHR * 0.90).round(),
      colorValue: 0xFFFFA500, // Orange
    );
  } else {
    return HeartRateZone(
      name: 'Zone 5',
      min: ((maxHR * 0.90).round() + 1),
      max: maxHR,
      colorValue: 0xFFFF0000, // Red
    );
  }
}
