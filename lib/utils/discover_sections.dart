import '../models/user.dart';

enum DiscoverSectionKind {
  similarInterests,
  sameDatingGoals,
  communitiesInCommon,
}

class DiscoverSectionData {
  final String title;
  final DiscoverSectionKind kind;
  final List<User> users;

  const DiscoverSectionData({
    required this.title,
    required this.kind,
    required this.users,
  });
}

List<DiscoverSectionData> buildDiscoverSections({
  required List<User> allUsers,
  User? currentUser,
}) {
  if (allUsers.isEmpty) return [];

  final assigned = <String>{};

  List<User> takeUnique(List<User> candidates, {int max = 12}) {
    final result = <User>[];
    for (final user in candidates) {
      if (assigned.contains(user.id)) continue;
      result.add(user);
      assigned.add(user.id);
      if (result.length >= max) break;
    }
    return result;
  }

  List<User> fillFromPool(List<User> matched, int slice) {
    if (matched.isNotEmpty) return matched;

    final start = (slice * 4) % allUsers.length;
    final result = <User>[];
    for (var i = 0; i < allUsers.length && result.length < 8; i++) {
      final user = allUsers[(start + i) % allUsers.length];
      if (assigned.contains(user.id)) continue;
      result.add(user);
      assigned.add(user.id);
    }
    return result;
  }

  final similar = takeUnique(
    _pickUsers(
      allUsers,
      (user) => _interestScore(user, currentUser) > 0,
      compare: (a, b) => _interestScore(b, currentUser)
          .compareTo(_interestScore(a, currentUser)),
    ),
  );

  final goals = takeUnique(
    _pickUsers(
      allUsers,
      (user) => _matchesLookingFor(user, currentUser),
    ),
  );

  final communities = takeUnique(
    _pickUsers(
      allUsers,
      (user) => _matchesCommunity(user, currentUser),
    ),
  );

  return [
    DiscoverSectionData(
      title: 'Similar interests',
      kind: DiscoverSectionKind.similarInterests,
      users: fillFromPool(similar, 0),
    ),
    DiscoverSectionData(
      title: 'Same dating goals',
      kind: DiscoverSectionKind.sameDatingGoals,
      users: fillFromPool(goals, 1),
    ),
    DiscoverSectionData(
      title: 'Communities in common',
      kind: DiscoverSectionKind.communitiesInCommon,
      users: fillFromPool(communities, 2),
    ),
  ];
}

List<User> _pickUsers(
  List<User> allUsers,
  bool Function(User user) test, {
  int Function(User a, User b)? compare,
}) {
  final matched = allUsers.where(test).toList();
  if (compare != null) {
    matched.sort(compare);
  }
  return matched;
}

int _interestScore(User user, User? me) {
  if (me == null) return 1;

  var score = 0;
  if (_matchesLookingFor(user, me)) score += 2;
  if (_sameField(user.zodiacSign, me.zodiacSign)) score++;
  if (_sameField(user.drinking, me.drinking)) score++;
  if (_sameField(user.educationLevel, me.educationLevel)) score++;
  if (_sameField(user.religiousBelief, me.religiousBelief)) score++;
  if (_sameField(user.politicalBelief, me.politicalBelief)) score++;
  return score;
}

bool _matchesLookingFor(User user, User? me) {
  if (me == null) return user.lookingFor?.trim().isNotEmpty == true;
  return _sameField(user.lookingFor, me.lookingFor);
}

bool _matchesCommunity(User user, User? me) {
  if (me == null) {
    return user.religiousBelief?.trim().isNotEmpty == true ||
        (user.ethnicity?.isNotEmpty ?? false);
  }

  if (_sameField(user.religiousBelief, me.religiousBelief)) return true;

  final myEthnicity = me.ethnicity ?? const [];
  final theirEthnicity = user.ethnicity ?? const [];
  for (final item in myEthnicity) {
    if (theirEthnicity.any(
      (other) => other.trim().toLowerCase() == item.trim().toLowerCase(),
    )) {
      return true;
    }
  }
  return false;
}

bool _sameField(String? a, String? b) {
  if (a == null || b == null) return false;
  final left = a.trim().toLowerCase();
  final right = b.trim().toLowerCase();
  return left.isNotEmpty && left == right;
}

List<String> discoverHighlightsForSection(
  User user,
  DiscoverSectionKind kind,
) {
  final tags = <String>[];

  void add(String? value, [String emoji = '']) {
    if (value == null) return;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    final label = emoji.isEmpty ? trimmed : '$emoji $trimmed';
    if (!tags.contains(label)) tags.add(label);
  }

  switch (kind) {
    case DiscoverSectionKind.similarInterests:
      add(user.lookingFor, '🔍');
      add(user.zodiacSign, '✨');
      add(user.drinking, '🍷');
      add(user.educationLevel, '🎓');
      add(user.religiousBelief, '🙂');
      break;
    case DiscoverSectionKind.sameDatingGoals:
      add(user.lookingFor, '🔍');
      add(user.wantsChildren, '👶');
      add(user.hasChildren, '🍼');
      break;
    case DiscoverSectionKind.communitiesInCommon:
      add(user.religiousBelief, '🙂');
      if (user.ethnicity != null) {
        for (final item in user.ethnicity!) {
          add(item, '🌍');
        }
      }
      add(user.politicalBelief, '🗳️');
      break;
  }

  if (tags.isEmpty) {
    return discoverHighlightsFor(user);
  }
  return tags.take(4).toList();
}

List<String> discoverHighlightsFor(User user) {
  final tags = <String>[];

  void add(String? value) {
    if (value == null) return;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    if (!tags.contains(trimmed)) tags.add(trimmed);
  }

  add(user.lookingFor);
  add(user.religiousBelief);
  add(user.politicalBelief);
  if (user.ethnicity != null) {
    for (final item in user.ethnicity!) {
      add(item);
    }
  }
  add(user.educationLevel);
  add(user.zodiacSign);

  return tags.take(4).toList();
}
