import 'package:flutter_test/flutter_test.dart';

/// Test assumptions:
///
/// Formula: Keytel et al. (2005) HR-based calorie expenditure.
///   Male:   cal/min = (0.6309*HR + 0.09036*W_kg + 0.2017*A − 55.0969) / 4.184
///   Female: cal/min = (0.4472*HR − 0.05741*W_kg + 0.074*A  − 20.4022) / 4.184
///
/// Current app logic stores weight in lbs and converts inside formula:
///   W_kg = W_lbs * 0.45359237
///
/// Sanity-check reference using the app's current coefficients:
///   190 lb, male, age 30, avg HR 150, duration 120 min => 1531 kcal.

int _calculateCaloriesCurrent({
  required int avgHr,
  required int age,
  required double weightLbs,
  required String gender,
  required Duration duration,
}) {
  final minutes = duration.inSeconds / 60.0;
  final weightKg = weightLbs * 0.45359237;

  double perMin;
  if (gender == 'female') {
    perMin =
        ((0.4472 * avgHr) - (0.05741 * weightKg) + (0.074 * age) - 20.4022) /
            4.184;
  } else {
    perMin =
        ((0.6309 * avgHr) + (0.09036 * weightKg) + (0.2017 * age) - 55.0969) /
            4.184;
  }

  if (perMin < 0) perMin = 0;
  return (perMin * minutes).round();
}

double _calculateCaloriesCurrentExact({
  required double avgHr,
  required int age,
  required double weightLbs,
  required String gender,
  required Duration duration,
}) {
  final minutes = duration.inSeconds / 60.0;
  final weightKg = weightLbs * 0.45359237;
  final normalizedGender = gender.toLowerCase();

  double perMin;
  if (normalizedGender == 'female') {
    perMin =
        ((0.4472 * avgHr) - (0.05741 * weightKg) + (0.074 * age) - 20.4022) /
            4.184;
  } else {
    perMin =
        ((0.6309 * avgHr) + (0.09036 * weightKg) + (0.2017 * age) - 55.0969) /
            4.184;
  }

  if (perMin < 0) perMin = 0;
  return perMin * minutes;
}

int _calculateCaloriesOldBug({
  required int avgHr,
  required int age,
  required double weightLbsTreatedAsKg,
  required String gender,
  required Duration duration,
}) {
  final minutes = duration.inSeconds / 60.0;

  double perMin;
  if (gender == 'female') {
    perMin =
        ((0.4472 * avgHr) -
            (0.05741 * weightLbsTreatedAsKg) +
            (0.074 * age) -
            20.4022) /
        4.184;
  } else {
    perMin =
        ((0.6309 * avgHr) +
            (0.09036 * weightLbsTreatedAsKg) +
            (0.2017 * age) -
            55.0969) /
        4.184;
  }

  if (perMin < 0) perMin = 0;
  return (perMin * minutes).round();
}

void main() {
  group('Calories (lbs storage + in-formula lbs→kg conversion)', () {
    const int avgHr = 150;
    const int age = 30;
    const Duration duration = Duration(minutes: 120);

    test('190 lbs male lands in expected non-inflated range', () {
      final calories = _calculateCaloriesCurrent(
        avgHr: avgHr,
        age: age,
        weightLbs: 190,
        gender: 'male',
        duration: duration,
      );

      expect(calories, greaterThan(1400));
      expect(calories, lessThan(2200));
    });

    test('200 lbs male > 190 lbs male (same HR/age/duration)', () {
      final c190 = _calculateCaloriesCurrent(
        avgHr: avgHr,
        age: age,
        weightLbs: 190,
        gender: 'male',
        duration: duration,
      );
      final c200 = _calculateCaloriesCurrent(
        avgHr: avgHr,
        age: age,
        weightLbs: 200,
        gender: 'male',
        duration: duration,
      );

      expect(c200, greaterThan(c190));
    });

    test('old bug (lbs treated as kg) inflates calories vs current logic', () {
      final current = _calculateCaloriesCurrent(
        avgHr: avgHr,
        age: age,
        weightLbs: 190,
        gender: 'male',
        duration: duration,
      );
      final bugged = _calculateCaloriesOldBug(
        avgHr: avgHr,
        age: age,
        weightLbsTreatedAsKg: 190,
        gender: 'male',
        duration: duration,
      );

      expect(bugged, greaterThan(current));
    });

    test('female calculation remains positive and reasonable', () {
      final calories = _calculateCaloriesCurrent(
        avgHr: avgHr,
        age: age,
        weightLbs: 190,
        gender: 'female',
        duration: duration,
      );

      expect(calories, greaterThan(0));
      expect(calories, lessThan(2200));
    });
  });

  group('Current formula reference values', () {
    const int expectedMaleCalories = 1531;
    const int expectedFemaleCalories = 1261;
    const double expectedOneHourExactCalories = 589.21;

    test('male reference scenario matches expected total calories', () {
      final calories = _calculateCaloriesCurrent(
        avgHr: 150,
        age: 30,
        weightLbs: 190,
        gender: 'male',
        duration: const Duration(minutes: 120),
      );

      expect(calories, expectedMaleCalories);
    });

    test('female reference scenario matches expected total calories', () {
      final calories = _calculateCaloriesCurrent(
        avgHr: 150,
        age: 30,
        weightLbs: 190,
        gender: 'female',
        duration: const Duration(minutes: 120),
      );

      expect(calories, expectedFemaleCalories);
    });

    test('sample male one-hour workout matches expected exact total', () {
      final calories = _calculateCaloriesCurrentExact(
        avgHr: 127.0,
        age: 40,
        weightLbs: 195.0,
        gender: 'male',
        duration: const Duration(hours: 1),
      );

      expect(calories, closeTo(expectedOneHourExactCalories, 0.01));
    });
  });
}
