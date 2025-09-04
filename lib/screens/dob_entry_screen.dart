import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notification_prompt_screen.dart';

class DobEntryScreen extends StatefulWidget {
  const DobEntryScreen({super.key});

  @override
  State<DobEntryScreen> createState() => _DobEntryScreenState();
}

class _DobEntryScreenState extends State<DobEntryScreen> {
  DateTime? _selectedDate;
  int? _calculatedAge;
  bool _pressed = false;

  bool get _hasValidDate => _selectedDate != null;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime.now().subtract(const Duration(days: 36500)), // 100 years ago
      lastDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6B46C1),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _calculatedAge = DateTime.now().year - picked.year - 
          ((DateTime.now().month < picked.month || 
            (DateTime.now().month == picked.month && DateTime.now().day < picked.day)) ? 1 : 0);
      });
    }
  }

  void _showAgeConfirmation() {
    if (_selectedDate == null || _calculatedAge == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("You're $_calculatedAge", style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        content: Text('Born ${_selectedDate!.day} ${_getMonthName(_selectedDate!.month)} ${_selectedDate!.year}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationPromptScreen()),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                // Main content centered
                Expanded(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "What's your date of birth?",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Date display or selection prompt
                    if (_selectedDate == null) ...[
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Select your date of birth',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Icon(Icons.calendar_today, color: Colors.grey[600]),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF6B46C1)),
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFF8F9FA),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_selectedDate!.day} ${_getMonthName(_selectedDate!.month)} ${_selectedDate!.year}',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6B46C1),
                                  ),
                                ),
                                Text(
                                  'Age: $_calculatedAge years',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () => _selectDate(context),
                              icon: const Icon(Icons.edit, color: Color(0xFF6B46C1)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'We use this to calculate the age on your profile.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
                ],
              ),
            ),
            Positioned(
              right: 24,
              bottom: 24,
              child: GestureDetector(
                onTapDown: (_) => setState(() => _pressed = true),
                onTapCancel: () => setState(() => _pressed = false),
                onTapUp: (_) {
                  setState(() => _pressed = false);
                  if (_hasValidDate) {
                    _showAgeConfirmation();
                  }
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _hasValidDate 
                        ? (_pressed ? const Color(0xFF5A3BB1) : const Color(0xFF6B46C1))
                        : (_pressed ? const Color(0xFFF0EDF2) : Colors.white),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE7E3E7)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: _hasValidDate ? Colors.white : const Color(0xFF1F1F1F),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

