import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

class HeartRateZone {
  final String name;
  final int min;
  final int max;
  final Color colorValue;
  final String emojiImg;
  final List<String> messages;

  HeartRateZone({
    required this.name,
    required this.min,
    required this.max,
    required this.colorValue,
    required this.emojiImg,
    required this.messages
  });

  //overload == only check name to account for different min/max values
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeartRateZone && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

/// Computes the heart rate zone based on the current heart rate [hr]
/// and the maximum heart rate [maxHR].
HeartRateZone getZoneForHR(int hr, int maxHR) {
  double percentage = (hr / maxHR) * 100;
  if (hr < 0) { // null value
    return HeartRateZone(
      name: 'N/A',
      min: -100,
      max: 0,
      colorValue: Colors.black,
      emojiImg: "N/A",
      messages: [
        "N/A"
      ]
    );
  }
  if (percentage <= 65) {
    return HeartRateZone(
      name: 'Zone 1',
      min: 0,
      max: (maxHR * 0.65).round(),
      colorValue: Colors.blueGrey,
      emojiImg: "assets/images/emojis/zone1.png",
      messages: [
        "Easy does it — you’re warming up right.",
        "Nice and steady, this is recovery pace.",
        "Save your energy, you’re just getting started."
      ]
    );
  } else if (percentage <= 80) {
    return HeartRateZone(
      name: 'Zone 2',
      min: ((maxHR * 0.65).round() + 1),
      max: (maxHR * 0.8).round(),
      colorValue: Colors.blue,
      emojiImg: "assets/images/emojis/zone2.png",
      messages: [
        "Perfect pace for building endurance.",
        "Keep it steady — this zone trains your engine.",
        "Comfortable effort, you could do this for hours."
      ]
    );
  } else if (percentage <= 89) {
    return HeartRateZone(
      name: 'Zone 3',
      min: ((maxHR * 0.8).round() + 1),
      max: (maxHR * 0.89).round(),
      colorValue: Colors.green,
      emojiImg: "assets/images/emojis/zone3.png",
      messages: [
        "You’re in the sweet spot — challenging but sustainable.",
        "This zone boosts stamina, keep it balanced.",
        "Watch your breathing — you should still be able to chat."
      ]
    );
  } else if (percentage <= 95) {
    return HeartRateZone(
      name: 'Zone 4',
      min: ((maxHR * 0.89).round() + 1),
      max: (maxHR * 0.95).round(),
      colorValue: Colors.orange,
      emojiImg: "assets/images/emojis/zone4.png",
      messages: [
        "You’re pushing hard — great for speed and power.",
        "Almost at your limit, stay controlled.",
        "This is where performance gains happen, dig in."
      ]
    );
  } else {
    return HeartRateZone(
      name: 'Zone 5',
      min: ((maxHR * 0.95).round() + 1),
      max: maxHR,
      colorValue: Colors.red,
      emojiImg: "assets/images/emojis/zone5.png",
      messages: [
        "All-out effort — give it everything.",
        "You’re peaking — this zone builds max capacity.",
        "Short bursts here, then recover strong."
      ]
    );
  }
}
