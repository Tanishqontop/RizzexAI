import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'config/supabase_config.dart';
import 'screens/home_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    debug: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RizzexAI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/signin': (context) => const SignInScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;
  Session? _currentSession;
  StreamSubscription? _linkSubscription;
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _currentSession = Supabase.instance.client.auth.currentSession;
    _setupAuthListener();
    _checkCurrentSession();
    _initDeepLinkHandling();
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _currentSession = session;
          });
        }
      } else if (event == AuthChangeEvent.signedOut) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _currentSession = null;
          });
        }
      } else if (event == AuthChangeEvent.initialSession) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _currentSession = session;
          });
        }
      }
    });
  }

  Future<void> _checkCurrentSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;

      if (session != null) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _currentSession = session;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _currentSession = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _currentSession = null;
        });
      }
    }
  }

  void _initDeepLinkHandling() {
    // Handle links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      print('Deep link error: $err');
    });

    // Handle links when app is opened from a link
    _appLinks.getInitialAppLink().then((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });
  }

  void _handleDeepLink(Uri uri) async {
    print('Handling deep link: $uri');
    // Check if this is a password reset link
    if (uri.pathSegments.contains('reset-password') ||
        uri.queryParameters.containsKey('access_token') ||
        uri.queryParameters.containsKey('refresh_token')) {
      // Extract tokens from the URL
      final accessToken = uri.queryParameters['access_token'];
      final refreshToken = uri.queryParameters['refresh_token'];
      print('accessToken: $accessToken');
      print('refreshToken: $refreshToken');
      // Set the session with the tokens
      if (refreshToken != null) {
        await Supabase.instance.client.auth.recoverSession(refreshToken);
        final session = Supabase.instance.client.auth.currentSession;
        print('Session after recover: $session');
        if (mounted && session != null) {
          setState(() {
            _currentSession = session;
          });
          // Only now navigate to reset password screen
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/reset-password',
            (route) => false,
          );
        } else {
          print('Session is still null after recover.');
        }
      } else {
        print('No refresh token found in deep link.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_currentSession != null) {
      return const HomeScreen();
    } else {
      return const SignInScreen();
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }
}
