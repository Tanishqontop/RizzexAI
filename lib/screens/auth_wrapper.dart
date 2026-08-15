import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'basic_info_intro_screen.dart';
import '../services/profile_service.dart';
import '../services/feed_service.dart';
import '../widgets/love_loading_view.dart';
import 'dart:async';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isResolving = true;
  bool _isPreparingFeed = false;
  Session? _currentSession;
  bool _onboardingCompleted = false;
  StreamSubscription<Uri?>? _linkSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _resolveAuthState();
    _initDeepLinkHandling();
  }

  Future<void> _resolveAuthState() async {
    if (mounted) {
      setState(() => _isResolving = true);
    }

    try {
      var session = Supabase.instance.client.auth.currentSession;

      if (session != null && session.isExpired) {
        try {
          final refreshed =
              await Supabase.instance.client.auth.refreshSession();
          session = refreshed.session;
        } catch (_) {
          await Supabase.instance.client.auth.signOut();
          session = null;
        }
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (session == null || user == null) {
        if (mounted) {
          setState(() {
            _currentSession = null;
            _onboardingCompleted = false;
            _isResolving = false;
            _isPreparingFeed = false;
          });
        }
        return;
      }

      final completed =
          await ProfileService().isOnboardingCompleted(session.user.id);

      if (completed) {
        if (mounted) {
          setState(() => _isPreparingFeed = true);
        }
        try {
          await FeedService().getPotentialMatches(limit: 20);
        } catch (_) {
          // Feed can still load on the screen if prefetch fails.
        }
        if (mounted) {
          setState(() => _isPreparingFeed = false);
        }
      }

      if (mounted) {
        setState(() {
          _currentSession = session;
          _onboardingCompleted = completed;
          _isResolving = false;
        });
      }
    } catch (_) {
      final session = Supabase.instance.client.auth.currentSession;
      final user = Supabase.instance.client.auth.currentUser;

      if (session == null || user == null) {
        if (mounted) {
          setState(() {
            _currentSession = null;
            _onboardingCompleted = false;
            _isResolving = false;
            _isPreparingFeed = false;
          });
        }
        return;
      }

      // Keep the signed-in session; default to onboarding if profile check failed.
        if (mounted) {
          setState(() {
            _currentSession = session;
            _onboardingCompleted = false;
            _isResolving = false;
            _isPreparingFeed = false;
          });
        }
    }
  }

  void _setupAuthListener() {
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.userUpdated) {
        _resolveAuthState();
      } else if (event == AuthChangeEvent.signedOut) {
        if (mounted) {
          setState(() {
            _currentSession = null;
            _onboardingCompleted = false;
            _isResolving = false;
            _isPreparingFeed = false;
          });
        }
      }
    });
  }

  void _initDeepLinkHandling() {
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    _appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    if (uri.pathSegments.contains('reset-password') ||
        uri.queryParameters.containsKey('access_token') ||
        uri.queryParameters.containsKey('refresh_token')) {
      final refreshToken = uri.queryParameters['refresh_token'];
      if (refreshToken == null) return;

      await Supabase.instance.client.auth.recoverSession(refreshToken);
      await _resolveAuthState();
      final session = Supabase.instance.client.auth.currentSession;
      if (mounted && session != null) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/reset-password',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isResolving || _isPreparingFeed) {
      return const LoveLoadingView();
    }

    if (_currentSession == null) {
      return const OnboardingScreen();
    }

    return AuthenticatedGate(
      child: _onboardingCompleted
          ? HomeScreen(initialTabIndex: HomeScreen.feedTabIndex)
          : const BasicInfoIntroScreen(),
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Ensures protected screens never render without a valid Supabase session.
class AuthenticatedGate extends StatefulWidget {
  final Widget child;

  const AuthenticatedGate({super.key, required this.child});

  @override
  State<AuthenticatedGate> createState() => _AuthenticatedGateState();
}

class _AuthenticatedGateState extends State<AuthenticatedGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _guard());
  }

  void _guard() {
    final session = Supabase.instance.client.auth.currentSession;
    if (!mounted) return;
    if (session == null || session.isExpired) {
      navigateToAuthRoot(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || session.isExpired) {
      return const LoveLoadingView();
    }
    return widget.child;
  }
}

/// Resets navigation to [AuthWrapper] so auth/onboarding routing stays centralized.
void navigateToAuthRoot(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const AuthWrapper()),
    (route) => false,
  );
}
