import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar, Colors, Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/community_providers.dart';
import '../../../../providers/firestore_provider.dart';
import '../../../../providers/user_profile_provider.dart';
import '../../data/user_repository.dart';
import '../../domain/firestore_user.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  File? _imageFile;
  bool _isPublic = true;
  bool _isSaving = false;
  String _usernameStatus = ''; // '', 'checking', 'available', 'taken', 'short', 'invalid'
  Timer? _debounce;

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _debounce?.cancel();

    if (value.isEmpty) {
      setState(() => _usernameStatus = '');
      return;
    }

    final valid = RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value);
    if (!valid) {
      setState(() => _usernameStatus = 'invalid');
      return;
    }

    if (value.length < 3) {
      setState(() => _usernameStatus = 'short');
      return;
    }

    setState(() => _usernameStatus = 'checking');

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final taken =
          await ref.read(userRepositoryProvider).isUsernameTaken(value);
      if (!mounted || _usernameController.text != value) return;
      setState(() => _usernameStatus = taken ? 'taken' : 'available');
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (xFile == null) return;
    setState(() => _imageFile = File(xFile.path));
  }

  bool get _canContinue =>
      !_isSaving &&
      _usernameStatus == 'available' &&
      _usernameController.text.length >= 3;

  Future<void> _onContinue() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      String? profilePictureUrl;

      if (_imageFile != null) {
        profilePictureUrl = await ref
            .read(storageServiceProvider)
            .uploadProfilePicture(userId, _imageFile!);
      }

      // Use the Isar user profile display name if available.
      final localProfile = await ref.read(userProfileProvider.future);
      final displayName = localProfile?.name ?? _usernameController.text;

      final user = FirestoreUser(
        userId: userId,
        username: _usernameController.text.toLowerCase(),
        displayName: displayName,
        bio: _bioController.text.trim(),
        profilePictureUrl: profilePictureUrl,
        isPublic: _isPublic,
      );

      await ref.read(userRepositoryProvider).createUser(user);

      // Refresh the Firestore user provider so downstream widgets see
      // the newly created document.
      ref.invalidate(firestoreUserProvider);

      if (!mounted) return;
      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to create profile. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Set Up Profile',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: colors.text,
          ),
        ),
        backgroundColor: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // --- Profile picture ---
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 80,
                      backgroundColor: colors.surfaceElevated,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : null,
                      child: _imageFile == null
                          ? Icon(
                              Icons.person,
                              size: 64,
                              color: colors.textSecondary,
                            )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- Username ---
              CupertinoTextField(
                controller: _usernameController,
                placeholder: 'Username',
                maxLength: 20,
                autocorrect: false,
                onChanged: _onUsernameChanged,
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  color: colors.text,
                ),
                placeholderStyle: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  color: colors.textSecondary,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
              ),
              const SizedBox(height: 8),
              _buildUsernameStatus(colors),
              const SizedBox(height: 20),

              // --- Bio ---
              CupertinoTextField(
                controller: _bioController,
                placeholder: 'Bio (optional)',
                maxLength: 150,
                maxLines: 3,
                style: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  color: colors.text,
                ),
                placeholderStyle: TextStyle(
                  fontFamily: 'LeagueSpartan',
                  color: colors.textSecondary,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
              ),
              const SizedBox(height: 24),

              // --- Public toggle ---
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Public Account',
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 16,
                        color: colors.text,
                      ),
                    ),
                    CupertinoSwitch(
                      value: _isPublic,
                      activeTrackColor: colors.accent,
                      onChanged: (v) => setState(() => _isPublic = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- Continue button ---
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: colors.accent,
                  disabledColor: colors.accent.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  onPressed: _canContinue ? _onContinue : null,
                  child: _isSaving
                      ? const CupertinoActivityIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 17,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameStatus(Palette colors) {
    String text;
    Color color;

    switch (_usernameStatus) {
      case 'checking':
        text = 'Checking...';
        color = colors.textSecondary;
      case 'available':
        text = 'Available';
        color = colors.success;
      case 'taken':
        text = 'Taken';
        color = colors.destructive;
      case 'short':
        text = 'Too short';
        color = colors.textSecondary;
      case 'invalid':
        text = 'Letters, numbers, and underscores only';
        color = colors.warning;
      default:
        return const SizedBox(height: 18);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'LeagueSpartan',
          fontSize: 13,
          color: color,
        ),
      ),
    );
  }
}
