
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

final List<HeartRateZone> zones = [
  HeartRateZone(name: 'Blue', min: 0,   max: 100, colorValue: 0xFF0000FF),
  HeartRateZone(name: 'Green', min: 101, max: 120, colorValue: 0xFF00FF00),
  HeartRateZone(name: 'Yellow', min: 121, max: 140, colorValue: 0xFFFFFF00),
  HeartRateZone(name: 'Orange', min: 141, max: 160, colorValue: 0xFFFFA500),
  HeartRateZone(name: 'Red', min: 161, max: 220, colorValue: 0xFFFF0000),
];

HeartRateZone getZoneForHR(int hr) {
  return zones.firstWhere((zone) => hr >= zone.min && hr <= zone.max, orElse: () => zones.last);
}
