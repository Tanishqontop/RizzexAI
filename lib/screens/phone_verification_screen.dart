import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'otp_verification_screen.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountryCode = '+91';
  String _selectedCountryFlag = '🇮🇳';
  bool _isPhoneValid = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhone);
  }

  void _validatePhone() {
    setState(() {
      final digitsOnly = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      // Enable when there are at least 10 digits
      _isPhoneValid = digitsOnly.length >= 10;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
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
              
              // Phone icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.phone,
                  color: Colors.grey,
                  size: 24,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              Text(
                "What's your phone number?",
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Phone number input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    // Country code selector
                    GestureDetector(
                      onTap: _showCountryPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedCountryFlag,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedCountryCode,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Divider
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.grey[300],
                    ),
                    
                    // Phone number input
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          // Allow only digits, and cap at a reasonable max length
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your phone number',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Info text
              Text(
                'Rizzex will send you a text with a verification code.\nMessage and data rates may apply.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              
              const Spacer(),
              
              // Help text
              Text(
                'What if my number changes?',
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
                  onPressed: _isPhoneValid ? _continueToOTP : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPhoneValid ? const Color(0xFF6B46C1) : Colors.grey[300],
                    foregroundColor: _isPhoneValid ? Colors.white : Colors.grey[600],
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
                        color: _isPhoneValid ? Colors.white : Colors.grey[600],
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

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CountryPickerSheet(),
    ).then((selectedCountry) {
      if (selectedCountry != null) {
        setState(() {
          _selectedCountryCode = selectedCountry['code'] as String;
          _selectedCountryFlag = selectedCountry['flag'] as String;
        });
      }
    });
  }

  void _continueToOTP() {
    if (_isPhoneValid) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            phoneNumber: '$_selectedCountryCode ${_phoneController.text}',
          ),
        ),
      );
    }
  }
}

class CountryPickerSheet extends StatelessWidget {
  const CountryPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                Text(
                  'Select country',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          // Country list
          Expanded(
            child: ListView(
              children: _getCountries().map((country) {
                return ListTile(
                  leading: Text(
                    country['flag'] as String,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    country['name'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  trailing: Text(
                    country['code'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  onTap: () => Navigator.pop(context, country),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getCountries() {
    return [
      {'name': 'India', 'code': '+91', 'flag': '🇮🇳'},
      {'name': 'United States', 'code': '+1', 'flag': '🇺🇸'},
      {'name': 'United Kingdom', 'code': '+44', 'flag': '🇬🇧'},
      {'name': 'Canada', 'code': '+1', 'flag': '🇨🇦'},
      {'name': 'Australia', 'code': '+61', 'flag': '🇦🇺'},
      {'name': 'Germany', 'code': '+49', 'flag': '🇩🇪'},
      {'name': 'France', 'code': '+33', 'flag': '🇫🇷'},
      {'name': 'Spain', 'code': '+34', 'flag': '🇪🇸'},
      {'name': 'Italy', 'code': '+39', 'flag': '🇮🇹'},
      {'name': 'Japan', 'code': '+81', 'flag': '🇯🇵'},
      {'name': 'South Korea', 'code': '+82', 'flag': '🇰🇷'},
      {'name': 'Brazil', 'code': '+55', 'flag': '🇧🇷'},
      {'name': 'Mexico', 'code': '+52', 'flag': '🇲🇽'},
      {'name': 'Argentina', 'code': '+54', 'flag': '🇦🇷'},
      {'name': 'Chile', 'code': '+56', 'flag': '��🇱'},
    ];
  }
}
