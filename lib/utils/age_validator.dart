/// Calendar-based 18+ age validation for RizzexAI.
class AgeValidator {
  AgeValidator._();

  static const minimumAge = 18;

  static const underAgeMessage =
      'RizzexAI is available only to users aged 18 and above.';

  static const onboardingNotice =
      'RizzexAI is exclusively for users 18 and older.';

  /// Returns the user's age in whole years on [reference] (default: today).
  static int calculateAge(DateTime dateOfBirth, {DateTime? reference}) {
    final today = _dateOnly(reference ?? DateTime.now());
    final birthDate = _dateOnly(dateOfBirth);

    if (birthDate.isAfter(today)) {
      return -1;
    }

    var age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  static bool isAtLeast18(DateTime dateOfBirth, {DateTime? reference}) {
    return calculateAge(dateOfBirth, reference: reference) >= minimumAge;
  }

  /// Latest birth date that still qualifies as 18+ on [reference].
  static DateTime latestAllowedBirthDate({DateTime? reference}) {
    final today = _dateOnly(reference ?? DateTime.now());
    return DateTime(today.year - minimumAge, today.month, today.day);
  }

  static DateTime defaultBirthDatePickerInitial({DateTime? reference}) {
    final today = _dateOnly(reference ?? DateTime.now());
    return DateTime(today.year - 25, today.month, today.day);
  }

  static DateTime earliestAllowedBirthDate({DateTime? reference}) {
    final today = _dateOnly(reference ?? DateTime.now());
    return DateTime(today.year - 100, today.month, today.day);
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
