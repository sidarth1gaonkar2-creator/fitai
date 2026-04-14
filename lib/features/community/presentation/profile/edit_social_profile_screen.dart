import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar, Colors, Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/community_providers.dart';
import '../../../../providers/firestore_provider.dart';
import '../../data/user_repository.dart';

class EditSocialProfileScreen extends ConsumerStatefulWidget {
  const EditSocialProfileScreen({super.key});

  @override
  ConsumerState<EditSocialProfileScreen> createState() =>
      _EditSocialProfileScreenState();
}

class _EditSocialProfileScreenState
    extends ConsumerState<EditSocialProfileScreen> {
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  File? _newImageFile;
  bool _isPublic = true;
  bool _isSaving = false;
  bool _didInit = false;
  String? _originalUsername;
  String? _existingPhotoUrl;

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _initFromUser() {
    final userAsync = ref.read(firestoreUserProvider);
    final user = userAsync.valueOrNull;
    if (user == null || _didInit) return;
    _didInit = true;
    _usernameController.text = user.username;
    _bioController.text = user.bio;
    _isPublic = user.isPublic;
    _originalUsername = user.username;
    _existingPhotoUrl = user.profilePictureUrl;
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
    setState(() => _newImageFile = File(xFile.path));
  }

  Future<void> _save() async {
    final user = ref.read(firestoreUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final fields = <String, dynamic>{};

      final newUsername = _usernameController.text.trim().toLowerCase();
      if (newUsername != _originalUsername && newUsername.length >= 3) {
        final taken =
            await ref.read(userRepositoryProvider).isUsernameTaken(newUsername);
        if (taken) {
          _showError('Username is already taken.');
          setState(() => _isSaving = false);
          return;
        }
        fields['username'] = newUsername;
      }

      final newBio = _bioController.text.trim();
      if (newBio != user.bio) {
        fields['bio'] = newBio;
      }

      if (_isPublic != user.isPublic) {
        fields['isPublic'] = _isPublic;
      }

      if (_newImageFile != null) {
        final url = await ref
            .read(storageServiceProvider)
            .uploadProfilePicture(user.userId, _newImageFile!);
        fields['profilePictureUrl'] = url;
      }

      if (fields.isNotEmpty) {
        await ref.read(userRepositoryProvider).updateUser(user.userId, fields);
        ref.invalidate(firestoreUserProvider);
        ref.invalidate(userByIdProvider(user.userId));
      }

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      _showError('Save failed. Please try again.');
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

    // Wait for the user data to load and then initialise controllers.
    ref.watch(firestoreUserProvider);
    _initFromUser();

    return CupertinoPageScaffold(
      backgroundColor: colors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: colors.text,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const CupertinoActivityIndicator()
              : Text(
                  'Save',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: colors.accent,
                    fontSize: 16,
                  ),
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
                    _buildAvatar(colors),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Palette colors) {
    // Prefer newly picked local file, then existing network URL, then
    // letter placeholder.
    if (_newImageFile != null) {
      return CircleAvatar(
        radius: 80,
        backgroundColor: colors.surfaceElevated,
        backgroundImage: FileImage(_newImageFile!),
      );
    }

    if (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 80,
        backgroundColor: colors.surfaceElevated,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: _existingPhotoUrl!,
            width: 160,
            height: 160,
            fit: BoxFit.cover,
            placeholder: (_, __) => const CupertinoActivityIndicator(),
            errorWidget: (_, __, ___) => Icon(
              Icons.person,
              size: 64,
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 80,
      backgroundColor: colors.surfaceElevated,
      child: Icon(
        Icons.person,
        size: 64,
        color: colors.textSecondary,
      ),
    );
  }
}
