import 'package:rizzexai/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_match.dart';
import '../models/compliment.dart';
import '../models/received_super_like.dart';
import '../models/user.dart' as app_user;
import '../services/match_service.dart';
import '../services/compliment_service.dart';
import '../services/super_like_service.dart';
import '../services/feed_service.dart';
import '../services/safety_service.dart';
import '../utils/image_url_utils.dart';
import '../widgets/match_dialog.dart';
import '../widgets/compliment_sheet.dart';
import '../widgets/discover_profile_modal.dart';
import 'conversation_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final MatchService _matchService = MatchService();
  final ComplimentService _complimentService = ComplimentService();
  final SuperLikeService _superLikeService = SuperLikeService();
  final FeedService _feedService = FeedService();
  final SafetyService _safetyService = SafetyService();

  List<UserMatch> _matches = [];
  List<Compliment> _pendingCompliments = [];
  List<ReceivedSuperLike> _receivedSuperLikes = [];
  bool _isLoading = true;
  bool _olderChatsExpanded = false;
  String? _error;

  static const _recentWindowDays = 14;

  /// Reload chats (matches, compliments, super likes).
  void refresh() => _loadAll();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hiddenIds = await _safetyService.getHiddenUserIds();
      final results = await Future.wait([
        _matchService.getMatches(),
        _complimentService.getPendingReceivedCompliments(),
        _superLikeService.getReceivedSuperLikes().catchError((_) => <ReceivedSuperLike>[]),
      ]);

      if (mounted) {
        setState(() {
          _matches = (results[0] as List<UserMatch>)
              .where((m) => !hiddenIds.contains(m.matchedUser.id))
              .toList();
          _pendingCompliments = (results[1] as List<Compliment>)
              .where((c) => !hiddenIds.contains(c.senderId))
              .toList();
          _receivedSuperLikes = (results[2] as List<ReceivedSuperLike>)
              .where((s) => !hiddenIds.contains(s.swiperId))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  DateTime _activityDate(UserMatch match) {
    return match.lastMessageAt ?? match.createdAt;
  }

  bool _isExpired(UserMatch match) {
    final days = DateTime.now().difference(_activityDate(match)).inDays;
    return days >= _recentWindowDays;
  }

  int _expiredDays(UserMatch match) {
    return DateTime.now().difference(_activityDate(match)).inDays;
  }

  List<UserMatch> get _recentMatches =>
      _matches.where((m) => !_isExpired(m)).toList();

  List<UserMatch> get _olderMatches =>
      _matches.where((m) => _isExpired(m)).toList();

  List<ReceivedSuperLike> get _unmatchedSuperLikes {
    final matchedIds = _matches.map((m) => m.matchedUser.id).toSet();
    return _receivedSuperLikes
        .where((item) => !matchedIds.contains(item.swiperId))
        .toList();
  }

  Future<void> _likeBackFromSuperLike(app_user.User user) async {
    try {
      final match = await _feedService.recordSwipe(
        targetUserId: user.id,
        isLike: true,
      );
      await _loadAll();
      if (match != null && mounted) {
        await showMatchDialog(context, match);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  void _openSuperLikeProfile(ReceivedSuperLike superLike) {
    showDiscoverProfileModal(
      context: context,
      user: superLike.swiper,
      onLike: () => _likeBackFromSuperLike(superLike.swiper),
    );
  }

  void _openConversation(UserMatch match) async {
    final blocked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ConversationScreen(match: match),
      ),
    );
    if (mounted) {
      await _loadAll();
      if (blocked == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation removed from your chats')),
        );
      }
    }
  }

  Future<void> _replyToCompliment(Compliment compliment) async {
    final sender = compliment.sender;
    final senderName = sender?.displayName ?? 'Someone';

    await showReplyComplimentSheet(
      context: context,
      compliment: ComplimentDisplay(
        id: compliment.id,
        senderName: senderName,
        message: compliment.message,
      ),
      onReply: (reply) async {
        try {
          final match = await _complimentService.replyToCompliment(
            complimentId: compliment.id,
            reply: reply,
          );
          await _loadAll();
          if (match != null && mounted) {
            await showMatchDialog(context, match);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceFirst('Exception: ', '')),
              ),
            );
          }
        }
      },
    );
  }

  String _subtitleForMatch(UserMatch match) {
    if (_isExpired(match)) {
      final days = _expiredDays(match);
      return 'Conversation expired $days days ago';
    }
    return match.lastMessage ?? 'You matched! Say hello';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: Colors.black,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          _buildChatsSectionHeader(),
          const SizedBox(height: 8),
          if (_matches.isEmpty &&
              _pendingCompliments.isEmpty &&
              _unmatchedSuperLikes.isEmpty)
            _buildEmptyChats()
          else ...[
            if (_unmatchedSuperLikes.isNotEmpty) ...[
              _buildSuperLikesHeader(),
              ..._unmatchedSuperLikes.map(_buildSuperLikeTile),
              const SizedBox(height: 12),
            ],
            ..._pendingCompliments.map(_buildComplimentTile),
            ..._recentMatches.map((m) => _buildChatTile(m, expired: false)),
            if (_olderMatches.isNotEmpty) ...[
              _buildOlderChatsHeader(),
              if (_olderChatsExpanded)
                ..._olderMatches.map((m) => _buildChatTile(m, expired: true)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Chats',
          style: AppFonts.geist(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.search, size: 26, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildChatsSectionHeader() {
    return Row(
      children: [
        Text(
          'Chats',
          style: AppFonts.geist(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const Spacer(),
        Text(
          'Recent',
          style: AppFonts.geist(
            fontSize: 14,
            color: const Color(0xFF6B6B6B),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.sort, size: 22, color: Colors.grey[700]),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  Widget _buildEmptyChats() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.chat_bubble_outline, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: AppFonts.geist(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Match with someone in Discover to start chatting',
            textAlign: TextAlign.center,
            style: AppFonts.geist(
              fontSize: 14,
              color: const Color(0xFF6B6B6B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOlderChatsHeader() {
    return InkWell(
      onTap: () => setState(() => _olderChatsExpanded = !_olderChatsExpanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Text(
              'Older chats (${_olderMatches.length})',
              style: AppFonts.geist(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B6B6B),
              ),
            ),
            const Spacer(),
            Icon(
              _olderChatsExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: const Color(0xFF6B6B6B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuperLikesHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFFFC629),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star, size: 16, color: Colors.black),
          ),
          const SizedBox(width: 8),
          Text(
            'Super Likes',
            style: AppFonts.geist(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuperLikeTile(ReceivedSuperLike superLike) {
    final user = superLike.swiper;
    final photoUrl = _photoUrlForUser(user.avatarUrl, user.profilePhotos);

    return _buildChatRow(
      photoUrl: photoUrl,
      name: user.displayName,
      subtitle: 'Super Liked you',
      expired: false,
      highlight: true,
      onTap: () => _openSuperLikeProfile(superLike),
    );
  }

  Widget _buildComplimentTile(Compliment compliment) {
    final sender = compliment.sender;
    final photoUrl = _photoUrlForUser(sender?.avatarUrl, sender?.profilePhotos);

    return _buildChatRow(
      photoUrl: photoUrl,
      name: sender?.displayName ?? 'Someone',
      subtitle: compliment.message,
      expired: false,
      onTap: () => _replyToCompliment(compliment),
    );
  }

  Widget _buildChatTile(UserMatch match, {required bool expired}) {
    final user = match.matchedUser;
    final photoUrl = _photoUrlForUser(user.avatarUrl, user.profilePhotos);

    return _buildChatRow(
      photoUrl: photoUrl,
      name: user.displayName,
      subtitle: match.hasReceivedSuperLike
          ? 'Super Liked you · ${_subtitleForMatch(match)}'
          : _subtitleForMatch(match),
      expired: expired,
      highlight: match.hasReceivedSuperLike,
      onTap: () => _openConversation(match),
    );
  }

  String? _photoUrlForUser(String? avatarUrl, List<String>? profilePhotos) {
    return firstValidImageUrl([
      avatarUrl,
      ...?profilePhotos,
    ]);
  }

  Widget _buildChatRow({
    required String? photoUrl,
    required String name,
    required String subtitle,
    required bool expired,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: expired ? const EdgeInsets.all(3) : EdgeInsets.zero,
                  decoration: expired
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFBDBDBD),
                            width: 2.5,
                          ),
                        )
                      : null,
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFF0F0F0),
                    backgroundImage: photoUrl != null
                        ? CachedNetworkImageProvider(photoUrl)
                        : null,
                    child: photoUrl == null
                        ? const Icon(Icons.person, color: Color(0xFF9A9A9A))
                        : null,
                  ),
                ),
                if (highlight)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC629),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.star, size: 12, color: Colors.black),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppFonts.geist(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.geist(
                      fontSize: 14,
                      color: const Color(0xFF6B6B6B),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
