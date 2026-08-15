import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'match_service.dart';

class UnreadMessagesService {
  UnreadMessagesService._();

  static final UnreadMessagesService instance = UnreadMessagesService._();

  final MatchService _matchService = MatchService();
  final _supabase = Supabase.instance.client;
  final _refreshController = StreamController<void>.broadcast();

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  String _lastReadKey(String matchId) => 'chat_last_read_$matchId';

  Future<DateTime> getLastReadAt(String matchId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastReadKey(matchId));
    if (raw == null) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> markMatchAsRead(String matchId, {DateTime? at}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastReadKey(matchId),
      (at ?? DateTime.now()).toIso8601String(),
    );
    _notifyListeners();
  }

  Future<bool> hasUnreadMessages() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return false;

    final matches = await _matchService.getMatches();
    for (final match in matches) {
      final lastAt = match.lastMessageAt;
      final senderId = match.lastMessageSenderId;
      if (lastAt == null || senderId == null || senderId == currentUserId) {
        continue;
      }

      final lastRead = await getLastReadAt(match.id);
      if (lastAt.isAfter(lastRead)) {
        return true;
      }
    }

    return false;
  }

  Stream<bool> watchHasUnreadMessages() {
    late StreamSubscription<dynamic> messageSub;
    late StreamSubscription<void> refreshSub;

    return Stream<bool>.multi((controller) async {
      Future<void> emit() async {
        if (!controller.isClosed) {
          controller.add(await hasUnreadMessages());
        }
      }

      await emit();

      messageSub = _supabase
          .from('messages')
          .stream(primaryKey: ['id'])
          .listen((_) => emit());
      refreshSub = _refreshController.stream.listen((_) => emit());

      controller.onCancel = () async {
        await messageSub.cancel();
        await refreshSub.cancel();
      };
    });
  }

  void _notifyListeners() {
    if (!_refreshController.isClosed) {
      _refreshController.add(null);
    }
  }
}
