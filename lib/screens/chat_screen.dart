import 'package:rizzexai/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_match.dart';
import '../models/compliment.dart';
import '../services/match_service.dart';
import '../services/compliment_service.dart';
import '../services/profile_service.dart';
import '../widgets/match_dialog.dart';
import '../widgets/compliment_sheet.dart';
import '../widgets/spotlight_sheet.dart';
import 'conversation_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MatchService _matchService = MatchService();
  final ComplimentService _complimentService = ComplimentService();
  final ProfileService _profileService = ProfileService();

  List<UserMatch> _matches = [];
  List<Compliment> _pendingCompliments = [];
  String? _currentUserAvatarUrl;
  bool _isLoading = true;
  bool _olderChatsExpanded = false;
  String? _error;

  static const _recentWindowDays = 14;

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
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final results = await Future.wait([
        _matchService.getMatches(),
        _complimentService.getPendingReceivedCompliments(),
        if (userId != null) _profileService.getProfile(userId) else Future.value(null),
      ]);

      if (mounted) {
        final profile = results[2] as Map<String, dynamic>?;
        setState(() {
          _matches = results[0] as List<UserMatch>;
          _pendingCompliments = results[1] as List<Compliment>;
          _currentUserAvatarUrl = _resolveAvatarUrl(profile);
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

  String? _resolveAvatarUrl(Map<String, dynamic>? profile) {
    if (profile == null) return null;
    final avatar = profile['avatar_url']?.toString();
    if (avatar != null && avatar.isNotEmpty) return avatar;
    final media = profile['media_urls'] as List<dynamic>?;
    if (media != null && media.isNotEmpty) {
      return media.first.toString();
    }
    return null;
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

  void _openConversation(UserMatch match) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConversationScreen(match: match),
      ),
    );
    _loadAll();
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
          const SizedBox(height: 20),
          _buildYourMatchesSection(),
          const SizedBox(height: 28),
          _buildChatsSectionHeader(),
          const SizedBox(height: 8),
          if (_matches.isEmpty && _pendingCompliments.isEmpty)
            _buildEmptyChats()
          else ...[
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

  Widget _buildYourMatchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your matches',
          style: AppFonts.geist(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => showSpotlightSheet(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8E8E8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFF0F0F0),
                    backgroundImage: _currentUserAvatarUrl != null
                        ? CachedNetworkImageProvider(_currentUserAvatarUrl!)
                        : null,
                    child: _currentUserAvatarUrl == null
                        ? const Icon(Icons.person, color: Color(0xFF9A9A9A))
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Be seen up to 10x more',
                          style: AppFonts.geist(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Shine a Spotlight and be seen first.',
                          style: AppFonts.geist(
                            fontSize: 14,
                            color: const Color(0xFF6B6B6B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400], size: 28),
                ],
              ),
            ),
          ),
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
      subtitle: _subtitleForMatch(match),
      expired: expired,
      onTap: () => _openConversation(match),
    );
  }

  String? _photoUrlForUser(String? avatarUrl, List<String>? profilePhotos) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) return avatarUrl;
    if (profilePhotos != null && profilePhotos.isNotEmpty) {
      return profilePhotos.first;
    }
    return null;
  }

  Widget _buildChatRow({
    required String? photoUrl,
    required String name,
    required String subtitle,
    required bool expired,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
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
