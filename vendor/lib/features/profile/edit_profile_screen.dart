import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../services/upload_service.dart';
import '../auth/auth_cubit.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final _picker = ImagePicker();

  File? _pickedImage;
  bool _uploading = false;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFrom(ImageSource source) async {
    final xfile = await _picker.pickImage(source: source, imageQuality: 85);
    if (xfile == null) return;
    print('IMAGE PICKED: ${xfile.path}');
    setState(() => _pickedImage = File(xfile.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logged-in user found.')),
      );
      return;
    }

    setState(() => _uploading = true);

    try {
      String? uploadedUrl;
      if (_pickedImage != null) {
        print('UPLOAD PROFILE START (pickedImage=${_pickedImage!.path})');
        uploadedUrl = await UploadService.uploadProfileImage(
          imageFile: _pickedImage!,
        );
        if (uploadedUrl == null) {
          throw Exception('Profile image upload failed.');
        }

        // DEBUG: display flow logging
        print('UPLOADED URL: $uploadedUrl');
      }

      final now = FieldValue.serverTimestamp();

      final update = <String, dynamic>{
        'fullName': _fullNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'updatedAt': now,
      };
      if (uploadedUrl != null) {
        update['profileImage'] = uploadedUrl;
      }

      // DEBUG: display flow logging (exact value that will be saved)
      print(
          'FIRESTORE SAVED: users/$uid.profileImage=${update['profileImage']}');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(update);

      print(
          'FIRESTORE UPDATE SUCCESS (profile edit): uid=$uid updateKeys=${update.keys.toList()}');

      if (context.mounted) {
        context.pop();
      }
    } catch (e) {
      print('FIRESTORE/UPLOAD UPDATE FAILED (profile edit): $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Edit Profile'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userDocStream(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();

          // Fill controllers once data arrives.
          if (snapshot.hasData) {
            final fullName = (data?['fullName'] as String?) ?? '';
            final email = (data?['email'] as String?) ?? '';
            final phone = (data?['phoneNumber'] as String?) ?? '';
            final address = (data?['address'] as String?) ?? '';

            // Only set if controllers are empty to avoid clobbering while editing.
            if (_fullNameCtrl.text.isEmpty && fullName.isNotEmpty) {
              _fullNameCtrl.text = fullName;
            }
            if (_emailCtrl.text.isEmpty && email.isNotEmpty) {
              _emailCtrl.text = email;
            }
            if (_phoneCtrl.text.isEmpty && phone.isNotEmpty) {
              _phoneCtrl.text = phone;
            }
            if (_addressCtrl.text.isEmpty && address.isNotEmpty) {
              _addressCtrl.text = address;
            }
          }

          final existingImageUrl = (data?['profileImage'] as String?) ?? '';

          return snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeInUp(
                            child: Center(
                              child: Column(
                                children: [
                                  Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      CircleAvatar(
                                        radius: 52,
                                        backgroundColor: Colors.grey.shade200,
                                        backgroundImage:
                                            _pickedImage != null
                                                ? FileImage(_pickedImage!)
                                                : (existingImageUrl.isNotEmpty
                                                        ? NetworkImage(
                                                            existingImageUrl)
                                                        : null)
                                                    as ImageProvider<Object>?,
                                        onBackgroundImageError: (_, __) {},
                                        child: (_pickedImage == null &&
                                                existingImageUrl.isEmpty)
                                            ? const Icon(Icons.person, size: 40)
                                            : null,
                                      ),
                                      Positioned(
                                        right: 4,
                                        bottom: 4,
                                        child: InkWell(
                                          onTap: () =>
                                              _pickFrom(ImageSource.gallery),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                                Icons.camera_alt_rounded,
                                                size: 18,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Profile image',
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      SizedBox(
                                        width: 150,
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _pickFrom(ImageSource.gallery),
                                          icon: const Icon(
                                              Icons.photo_library_outlined),
                                          label: const Text('Gallery'),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 150,
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _pickFrom(ImageSource.camera),
                                          icon: const Icon(
                                              Icons.camera_alt_outlined),
                                          label: const Text('Camera'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          FadeInUp(
                            delay: const Duration(milliseconds: 150),
                            child: AppTextField(
                              controller: _fullNameCtrl,
                              label: 'Full Name',
                              hint: 'Raj Kumar',
                              prefixIcon: Icons.person_outline_rounded,
                              validator: Validators.fullName,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FadeInUp(
                            delay: const Duration(milliseconds: 200),
                            child: AppTextField(
                              controller: _emailCtrl,
                              label: 'Email',
                              hint: 'you@example.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.email,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FadeInUp(
                            delay: const Duration(milliseconds: 250),
                            child: AppTextField(
                              controller: _phoneCtrl,
                              label: 'Phone Number',
                              hint: '9876543210',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: Validators.phone,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FadeInUp(
                            delay: const Duration(milliseconds: 300),
                            child: AppTextField(
                              controller: _addressCtrl,
                              label: 'Address',
                              hint: 'House / Street / City',
                              prefixIcon: Icons.location_on_outlined,
                              validator: Validators.required,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          BlocListener<AuthCubit, AuthState>(
                            listener: (_, __) {},
                            child: FadeInUp(
                              delay: const Duration(milliseconds: 450),
                              child: AppButton(
                                label:
                                    _uploading ? 'Updating...' : 'Save Changes',
                                onPressed: _uploading ? null : _submit,
                                variant: AppButtonVariant.primary,
                                size: AppButtonSize.fullWidth,
                                isLoading: _uploading,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
        },
      ),
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }
}
