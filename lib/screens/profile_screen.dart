import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import 'auth/sign_in_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _profileService = ProfileService();
  User? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;
  String? _avatarUrl;
  File? _avatarFile;

  @override
  void initState() {
    super.initState();
    _currentUser = Supabase.instance.client.auth.currentUser;
    if (_currentUser != null) {
      _loadProfile();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User not logged in';
      });
    }
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final profile = await _profileService.getProfile(_currentUser!.id);
      if (mounted) {
        setState(() {
          if (profile != null) {
            _usernameController.text = profile['username'] ?? '';
            _bioController.text = profile['bio'] ?? '';
            _avatarUrl = profile['avatar_url'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading profile: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _avatarFile = File(picked.path);
      });
    }
  }

  Future<String?> _uploadAvatar(File file) async {
    try {
      final userId = _currentUser!.id;
      final ext = file.path.split('.').last;
      final fileName =
          'avatars/$userId.${DateTime.now().millisecondsSinceEpoch}.$ext';
      final storage = Supabase.instance.client.storage.from('avatars');
      final res = await storage.upload(fileName, file);
      if (res.isEmpty) {
        print('Upload failed: empty response');
        return null;
      }
      final publicUrl = storage.getPublicUrl(fileName);
      print('Avatar uploaded. Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Upload failed: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) return;
    setState(() => _isLoading = true);
    String? avatarUrl = _avatarUrl;
    try {
      if (_avatarFile != null) {
        avatarUrl = await _uploadAvatar(_avatarFile!);
        if (avatarUrl == null) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload avatar.')),
          );
          return;
        }
      }
      await _profileService.updateProfile(
        userId: _currentUser!.id,
        username: _usernameController.text,
        bio: _bioController.text,
        avatarUrl: avatarUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        setState(() {
          _avatarUrl = avatarUrl;
          _avatarFile = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: _isLoading
              ? Container(
                  alignment: Alignment.center,
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: const CircularProgressIndicator(color: Colors.red),
                )
              : _errorMessage != null
                  ? Container(
                      alignment: Alignment.center,
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 16),
                            child: Column(
                              children: [
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Colors.grey[200],
                                      backgroundImage: _avatarFile != null
                                          ? FileImage(_avatarFile!)
                                          : (_avatarUrl != null &&
                                                  _avatarUrl!.isNotEmpty)
                                              ? NetworkImage(_avatarUrl!)
                                                  as ImageProvider
                                              : null,
                                      child: (_avatarFile == null &&
                                              (_avatarUrl == null ||
                                                  _avatarUrl!.isEmpty))
                                          ? const Icon(Icons.person,
                                              size: 50, color: Colors.grey)
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Material(
                                        color: Colors.red,
                                        shape: const CircleBorder(),
                                        child: IconButton(
                                          icon: const Icon(Icons.camera_alt,
                                              color: Colors.white, size: 20),
                                          onPressed: () async {
                                            final source =
                                                await showModalBottomSheet<
                                                    ImageSource>(
                                              context: context,
                                              shape:
                                                  const RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                        top: Radius.circular(
                                                            20)),
                                              ),
                                              builder: (context) => SafeArea(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    ListTile(
                                                      leading: const Icon(
                                                          Icons.camera_alt),
                                                      title: const Text(
                                                          'Take Photo'),
                                                      onTap: () =>
                                                          Navigator.pop(
                                                              context,
                                                              ImageSource
                                                                  .camera),
                                                    ),
                                                    ListTile(
                                                      leading: const Icon(
                                                          Icons.photo_library),
                                                      title: const Text(
                                                          'Choose from Gallery'),
                                                      onTap: () =>
                                                          Navigator.pop(
                                                              context,
                                                              ImageSource
                                                                  .gallery),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                            if (source != null) {
                                              _pickAvatar(source);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _usernameController,
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    labelStyle:
                                        const TextStyle(color: Colors.red),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: Colors.red),
                                    ),
                                  ),
                                ),
                                if (_usernameController.text.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8.0),
                                    child: Text('No username loaded.',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _bioController,
                                  style: const TextStyle(color: Colors.black),
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    labelText: 'Bio',
                                    labelStyle:
                                        const TextStyle(color: Colors.red),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: Colors.red),
                                    ),
                                  ),
                                ),
                                if (_bioController.text.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8.0),
                                    child: Text('No bio loaded.',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _saveProfile,
                                      icon: const Icon(Icons.save),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                      ),
                                      label: const Text('Save Profile'),
                                    ),
                                    const SizedBox(width: 16),
                                    ElevatedButton.icon(
                                      onPressed: _logout,
                                      icon: const Icon(Icons.logout),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[800],
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                      ),
                                      label: const Text('Log Out'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
        ),
      ),
    );
  }
}
