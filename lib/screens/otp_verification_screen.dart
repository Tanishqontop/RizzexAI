import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'basic_info_intro_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  bool _isOtpComplete = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus first box and open keyboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes.first.requestFocus();
      }
    });
  }

  void _checkOtpComplete() {
    bool complete = true;
    for (int i = 0; i < 6; i++) {
      if (_otpControllers[i].text.isEmpty) {
        complete = false;
        break;
      }
    }
    setState(() {
      _isOtpComplete = complete;
    });
  }

  int _firstEmptyIndex() {
    for (int i = 0; i < 6; i++) {
      if (_otpControllers[i].text.isEmpty) return i;
    }
    return 5; // all filled, last index
  }

  @override
  void dispose() {
    for (int i = 0; i < 6; i++) {
      _otpControllers[i].dispose();
      _focusNodes[i].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              
              const SizedBox(height: 32),
              
              // Security icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.security,
                  color: Colors.grey,
                  size: 24,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Enter your verification code',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Phone number info
              Row(
                children: [
                  Text(
                    'Sent to ${widget.phoneNumber}. ',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Edit',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: const Color(0xFF6B46C1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // OTP input fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textInputAction: index < 5 ? TextInputAction.next : TextInputAction.done,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      showCursor: true,
                      cursorColor: Colors.black87,
                      decoration: InputDecoration(
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color(0xFF6B46C1),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      onTap: () {},
                      onChanged: (value) {
                        // Handle paste of multiple digits starting at current index
                        if (value.length > 1) {
                          final digits = value.replaceAll(RegExp(r'\D'), '');
                          int writeIndex = index;
                          for (int i = 0; i < digits.length && writeIndex < 6; i++) {
                            _otpControllers[writeIndex].text = digits[i];
                            writeIndex++;
                          }
                          // Move focus to next empty or stay on last
                          final next = _firstEmptyIndex();
                          _focusNodes[next].requestFocus();
                          _checkOtpComplete();
                          return;
                        }

                        if (value.isEmpty) {
                          // Move back when deleting
                          if (index > 0) {
                            FocusScope.of(context).previousFocus();
                          }
                        } else if (value.length == 1) {
                          if (index < 5) {
                            FocusScope.of(context).nextFocus();
                          } else {
                            _focusNodes[index].unfocus();
                          }
                        }
                        _checkOtpComplete();
                      },
                    ),
                  );
                }),
              ),
              
              const Spacer(),
              
              // Help text
              Text(
                "Didn't get a code?",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B46C1),
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isOtpComplete ? _verifyOtp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isOtpComplete ? const Color(0xFF6B46C1) : Colors.grey[300],
                    foregroundColor: _isOtpComplete ? Colors.white : Colors.grey[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 24), // Spacer
                      Text(
                        'Continue',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: _isOtpComplete ? Colors.white : Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    if (_isOtpComplete) {
      try {
        // In real implementation, you would verify the OTP with your backend
        // For now, we'll just mark the phone as verified locally
        
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          final prefs = await SharedPreferences.getInstance();
          final userId = session.user.id;
          await prefs.setBool('phone_verified_$userId', true);
        }
        
        // Navigate to onboarding intro after OTP
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const BasicInfoIntroScreen(),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error verifying OTP: $e')),
          );
        }
      }
    }
  }
}
