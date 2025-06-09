import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/home_screen.dart';
import 'screens/auth/sign_in_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _currentSession = Supabase.instance.client.auth.currentSession;
    _setupAuthListener();
    _checkCurrentSession();
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

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Use the cached session first, then fall back to the stream
    if (_currentSession != null) {
      return const HomeScreen();
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SignInScreen();
        }

        final session = snapshot.data?.session;

        if (session != null) {
          return const HomeScreen();
        }

        return const SignInScreen();
      },
    );
  }
}
