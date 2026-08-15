import 'dart:async';

import 'package:flutter/material.dart';
import 'discover_screen.dart';
import 'feed_screen.dart';
// v2: AI Features tab — uncomment for next release
// import 'ai_features_screen.dart';
import 'chat_screen.dart';
import 'my_profile_screen.dart';
import '../services/unread_messages_service.dart';
import '../widgets/luma_bottom_navigation.dart';

class HomeScreen extends StatefulWidget {
  final int initialTabIndex;

  static const feedTabIndex = 0;
  static const discoverTabIndex = 1;
  static const chatTabIndex = 2;
  // v2: was 4 when AI Features tab existed
  static const profileTabIndex = 3;

  const HomeScreen({super.key, this.initialTabIndex = feedTabIndex});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  bool _showChatBadge = false;
  StreamSubscription<bool>? _unreadSubscription;
  final GlobalKey<DiscoverScreenState> _discoverKey =
      GlobalKey<DiscoverScreenState>();
  final GlobalKey<ChatScreenState> _chatKey = GlobalKey<ChatScreenState>();
  final UnreadMessagesService _unreadMessagesService =
      UnreadMessagesService.instance;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const FeedScreen(),
      DiscoverScreen(key: _discoverKey),
      // v2: AI Features tab
      // const AIFeaturesScreen(),
      ChatScreen(key: _chatKey),
      const MyProfileScreen(),
    ];
    _currentIndex = widget.initialTabIndex.clamp(0, _screens.length - 1);
    _unreadSubscription =
        _unreadMessagesService.watchHasUnreadMessages().listen((hasUnread) {
      if (!mounted) return;
      setState(() => _showChatBadge = hasUnread);
    });
  }

  @override
  void dispose() {
    _unreadSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: LumaBottomNavigation(
        currentIndex: _currentIndex,
        showChatBadge: _showChatBadge,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == HomeScreen.discoverTabIndex) {
            _discoverKey.currentState?.refresh();
          }
          if (index == HomeScreen.chatTabIndex) {
            _chatKey.currentState?.refresh();
          }
        },
      ),
    );
  }
}
