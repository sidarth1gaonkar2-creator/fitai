import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar, Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/field_manual.dart';
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
          'EDIT PROFILE',
          style: FieldManual.title(color: colors.text),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const CupertinoActivityIndicator()
              : Text(
                  'Save',
                  style: FieldManual.body(fontSize: 16, color: colors.accent)
                      .copyWith(
                    fontVariations: const [FontVariation('wght', 600)],
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        backgroundColor: colors.background.withValues(alpha: 0.82),
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // --- Profile picture (icon-only control, so it is labeled) ---
              Semantics(
                label: 'Change profile photo',
                button: true,
                child: ExcludeSemantics(
                  child: GestureDetector(
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
                          child: Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: colors.onAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- Username ---
              _FMTextField(
                controller: _usernameController,
                placeholder: 'Username',
                maxLength: 20,
                autocorrect: false,
              ),
              const SizedBox(height: 20),

              // --- Bio ---
              _FMTextField(
                controller: _bioController,
                placeholder: 'Bio (optional)',
                maxLength: 150,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // --- Public toggle ---
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Public Account',
                      style: FieldManual.body(fontSize: 15, color: colors.text)
                          .copyWith(
                        fontVariations: const [FontVariation('wght', 600)],
                        fontWeight: FontWeight.w600,
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
            placeholder: (_, _) => const CupertinoActivityIndicator(),
            errorWidget: (_, _, _) => Icon(
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

/// Field Manual text input: field-raised fill, hairline border that shifts to
/// the live accent on focus, no glow (DESIGN.md §Inputs). Purely visual — all
/// behaviour is the inner [CupertinoTextField]'s.
class _FMTextField extends StatefulWidget {
  const _FMTextField({
    required this.controller,
    required this.placeholder,
    this.maxLength,
    this.maxLines = 1,
    this.autocorrect = true,
  });

  final TextEditingController controller;
  final String placeholder;
  final int? maxLength;
  final int maxLines;
  final bool autocorrect;

  @override
  State<_FMTextField> createState() => _FMTextFieldState();
}

class _FMTextFieldState extends State<_FMTextField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final focused = _focusNode.hasFocus;
    return CupertinoTextField(
      controller: widget.controller,
      focusNode: _focusNode,
      placeholder: widget.placeholder,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      autocorrect: widget.autocorrect,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      cursorColor: palette.accent,
      style: FieldManual.body(fontSize: 15, color: palette.text),
      placeholderStyle: FieldManual.body(
        fontSize: 15,
        color: palette.textSecondary,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: focused ? palette.accent : palette.border,
        ),
      ),
    );
  }
}
