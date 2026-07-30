import 'package:rizzexai/theme/app_typography.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import 'final_onboarding_screen.dart';

class PickMediaScreen extends StatefulWidget {
  const PickMediaScreen({super.key});

  @override
  State<PickMediaScreen> createState() => _PickMediaScreenState();
}

class _PickMediaScreenState extends State<PickMediaScreen> {
  final _profileService = ProfileService();
  final _currentUser = Supabase.instance.client.auth.currentUser;
  bool _loading = false;

  final List<File?> _media = List<File?>.filled(6, null);
  bool _showTips = false;
  bool _pressed = false;

  Future<void> _pickAt(int index) async {
    if (_loading) return;
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      setState(() => _media[index] = File(result.path));
    }
  }

  Future<void> _uploadMediaAndContinue() async {
    final hasAtLeastOne = _media.any((f) => f != null);
    if (!hasAtLeastOne || _currentUser == null || _loading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please upload at least 1 image to continue.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final List<String> uploadedUrls = [];
      for (final file in _media) {
        if (file != null) {
          final url = await _profileService.uploadProfileMedia(
            userId: _currentUser!.id,
            file: file,
          );
          uploadedUrls.add(url);
        }
      }

      await _profileService.upsertProfile(
        userId: _currentUser!.id,
        mediaUrls: uploadedUrls,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                FinalOnboardingScreen(uploadedCount: uploadedUrls.length)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload media: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.image_outlined,
                        size: 40, color: Color(0xFF1F1F1F)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pick your photos',
                        style: AppFonts.display(
                          fontSize: 34,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F1F1F),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, i) {
                    final file = _media[i];
                    return GestureDetector(
                      onTap: () => _pickAt(i),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFD6D3D6),
                              style: BorderStyle.solid,
                              width: 2),
                        ),
                        child: file == null
                            ? Stack(
                                children: [
                                  const Center(
                                      child: Icon(Icons.image_outlined,
                                          color: Color(0xFF9A979A))),
                                  Positioned(
                                    right: 8,
                                    bottom: 8,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                          color: Color(0xFF6B46C1),
                                          shape: BoxShape.circle),
                                      padding: const EdgeInsets.all(6),
                                      child: const Icon(Icons.add,
                                          color: Colors.white, size: 16),
                                    ),
                                  )
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(file, fit: BoxFit.cover),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text('Tap to edit; drag to reorder\n6 required',
                    style: AppFonts.geist(color: const Color(0xFF9A979A))),
                const SizedBox(height: 16),
                _showTips
                    ? _TipsPanel(
                        onHide: () => setState(() => _showTips = false))
                    : _ShowTips(onShow: () => setState(() => _showTips = true)),
                const SizedBox(height: 120),
              ],
            ),
            Positioned(
              right: 24,
              bottom: 24,
              child: GestureDetector(
                onTapDown: (_) => setState(() => _pressed = true),
                onTapCancel: () => setState(() => _pressed = false),
                onTapUp: (_) {
                  setState(() => _pressed = false);
                  _uploadMediaAndContinue();
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _pressed
                        ? const Color(0xFF5A3BB1)
                        : const Color(0xFF6B46C1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        // MODIFIED: Fixed deprecated member warning
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(18.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// NEW: Complete implementation of the _ShowTips widget
class _ShowTips extends StatelessWidget {
  const _ShowTips({required this.onShow});
  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E3E7)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Not sure which photos to use?\nSee what works based on research.',
            textAlign: TextAlign.center,
            style: AppFonts.geist(fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onShow,
            child: const Text('See what works'),
          )
        ],
      ),
    );
  }
}

// NEW: Complete implementation of the _TipsPanel widget
class _TipsPanel extends StatelessWidget {
  const _TipsPanel({required this.onHide});
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E3E7)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'A variety of poses and settings work best.',
            textAlign: TextAlign.center,
            style: AppFonts.geist(fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onHide,
            child: const Text('Hide tips'),
          )
        ],
      ),
    );
  }
}
