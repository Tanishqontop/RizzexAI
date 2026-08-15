import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'sign_up_screen.dart';
// TODO: Re-enable when Google auth is needed
// import 'package:supabase_flutter/supabase_flutter.dart';
import 'reset_password_screen.dart';
import '../../utils/auth_navigation.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }


  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await AuthService.signInWithEmail(
        _emailController.text,
        _passwordController.text,
      );
      if (response.user == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Sign in failed: No user returned';
          _isLoading = false;
        });
        return;
      }
      if (!mounted) return;
      await AuthNavigation.navigateAfterAuth(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // TODO: Re-enable when Google auth is needed
  /*
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.rizzexai.app://login-callback/',
        queryParams: {'prompt': 'select_account'},
      );
      // AuthWrapper will handle navigation based on phone verification status
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google sign-in failed: \$e')));
    }
  }
  */

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Stack(
        children: [
          // Gradient background
          Container(
            height: size.height * 0.38,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6B46C1), Color(0xFF5A3BB1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          // Main content
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    // Top row: back arrow and Get Started
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(
                            width: 48,
                          ), // Placeholder for alignment
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SignUpScreen(),
                                      ),
                                    );
                                  },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6B46C1),
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: const BorderSide(
                                  color: Color(0xFF6B46C1),
                                  width: 2,
                                ),
                              ),
                            ),
                            child: const Text(
                              'Get Started',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6B46C1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // App name
                    const Text(
                      'RizzexAI',
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(7),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Welcome Back',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D2D2D),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Enter your details below',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF8B8B8B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),
                              // Email field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: Color(0xFF6A5AE0),
                                  ),
                                  hintText: 'Email Address',
                                  filled: true,
                                  fillColor: const Color(0xFFF6F7FB),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                    horizontal: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 18),
                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: Color(0xFF6A5AE0),
                                  ),
                                  hintText: 'Password',
                                  filled: true,
                                  fillColor: const Color(0xFFF6F7FB),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                    horizontal: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: const Color(0xFF6A5AE0),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: _validatePassword,
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              const SizedBox(height: 24),
                              // Sign in button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _signIn,
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF6B46C1),
                                          Color(0xFF5A3BB1),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              'Sign in',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Forgot password
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ResetPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Forgot your password?',
                                  style: TextStyle(
                                    color: Color(0xFF6A5AE0),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // TODO: Re-enable when Google auth is needed
                              /*
                              // Divider with text
                              Row(
                                children: [
                                  const Expanded(
                                    child: Divider(
                                      thickness: 1,
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      'Or sign in with',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                  const Expanded(
                                    child: Divider(
                                      thickness: 1,
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Social buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          signInWithGoogle(context),
                                      icon: Image.asset(
                                        'assets/google.png',
                                        height: 22,
                                      ),
                                      label: const Text('Google'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.black,
                                        side: const BorderSide(
                                          color: Color(0xFFE0E0E0),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              */
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
