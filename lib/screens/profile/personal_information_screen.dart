import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  bool _isLoading = false;
  bool _isUploadingAvatar = false;

  /// Maximum avatar file size: 5 MB
  static const int _maxAvatarBytes = 5 * 1024 * 1024;

  /// Supported image extensions
  static const List<String> _allowedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp'
  ];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.contactNumber ?? '');
    _locationController = TextEditingController(text: user?.location ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // ─── Avatar Upload ────────────────────────────────────────────────────

  Future<void> _pickAndUploadAvatar() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return;

      final pickedFile = result.files.single;

      // Validate file size
      if (pickedFile.size > _maxAvatarBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image too large. Maximum size is 5 MB.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Confirm with user
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Update Avatar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: Image.file(
                  File(pickedFile.path!),
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Use this image as your profile picture?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      setState(() => _isUploadingAvatar = true);

      final file = File(pickedFile.path!);
      final auth = context.read<AuthProvider>();
      if (auth.currentUser == null) return;

      // Upload to storage backend
      final newUrl =
          await storageService.uploadUserAvatar(auth.currentUser!.id, file);

      // Save URL to Firestore user profile
      await auth.updateUserProfile({'avatarUrl': newUrl});

      // Evict old cached image so the new one loads immediately
      await CachedNetworkImage.evictFromCache(newUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update avatar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  // ─── Save Profile Fields ──────────────────────────────────────────────

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    final success = await auth.updateUserProfile({
      'name': _nameController.text.trim(),
      'contactNumber': _phoneController.text.trim(),
      'location': _locationController.text.trim(),
    });

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(auth.errorMessage ?? 'Failed to update profile'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information',
            style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppPadding.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Update your personal details below.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: AppPadding.xl),

                // ── Avatar Section ──────────────────────────────────────
                Center(
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.surfaceElevated,
                            backgroundImage: CachedNetworkImageProvider(
                              auth.userAvatar,
                            ),
                          ),
                          if (_isUploadingAvatar)
                            const Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isUploadingAvatar
                                  ? null
                                  : _pickAndUploadAvatar,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.background, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Tap the camera icon to change your photo',
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
                const SizedBox(height: AppPadding.xl),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.person_outline_rounded,
                        color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Name cannot be empty'
                      : null,
                ),
                const SizedBox(height: AppPadding.md),

                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.phone_outlined,
                        color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: AppPadding.md),

                // Location Field
                TextFormField(
                  controller: _locationController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Location / City',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.location_on_outlined,
                        color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Save Changes',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
