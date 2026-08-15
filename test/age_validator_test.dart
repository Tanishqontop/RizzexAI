import 'package:flutter_test/flutter_test.dart';
import 'package:rizzexai/utils/age_validator.dart';

void main() {
  group('AgeValidator', () {
    test('DOB exactly 18 years ago passes', () {
      final reference = DateTime(2026, 8, 15);
      final dob = DateTime(2008, 8, 15);

      expect(AgeValidator.calculateAge(dob, reference: reference), 18);
      expect(AgeValidator.isAtLeast18(dob, reference: reference), isTrue);
    });

    test('DOB one day younger than 18 fails', () {
      final reference = DateTime(2026, 8, 15);
      final dob = DateTime(2008, 8, 16);

      expect(AgeValidator.calculateAge(dob, reference: reference), 17);
      expect(AgeValidator.isAtLeast18(dob, reference: reference), isFalse);
    });

    test('DOB one day older than 18 passes', () {
      final reference = DateTime(2026, 8, 15);
      final dob = DateTime(2008, 8, 14);

      expect(AgeValidator.calculateAge(dob, reference: reference), 18);
      expect(AgeValidator.isAtLeast18(dob, reference: reference), isTrue);
    });

    test('leap-year birthday is calculated correctly', () {
      final reference = DateTime(2025, 3, 1);
      final dob = DateTime(2004, 2, 29);

      expect(AgeValidator.calculateAge(dob, reference: reference), 21);
      expect(AgeValidator.isAtLeast18(dob, reference: reference), isTrue);
    });

    test('future DOB fails', () {
      final reference = DateTime(2026, 8, 15);
      final dob = DateTime(2027, 1, 1);

      expect(AgeValidator.calculateAge(dob, reference: reference), lessThan(0));
      expect(AgeValidator.isAtLeast18(dob, reference: reference), isFalse);
    });

    test('latestAllowedBirthDate matches 18-year boundary', () {
      final reference = DateTime(2026, 8, 15);
      final latest = AgeValidator.latestAllowedBirthDate(reference: reference);

      expect(latest, DateTime(2008, 8, 15));
      expect(AgeValidator.isAtLeast18(latest, reference: reference), isTrue);
    });
  });
}
