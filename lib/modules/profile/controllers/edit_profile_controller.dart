import 'dart:io';

import 'package:dio/dio.dart' show FormData, MultipartFile;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';

import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_utils.dart';

/// Edit profil (FR-08.3): `PUT /api/user/profile` (API.md §7.8) +
/// `POST /api/user/avatar` (API.md §7.9, multipart field `avatar` ≤2MB).
class EditProfileController extends GetxController {
  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final provinceController = TextEditingController();
  final fishTypesController = TextEditingController();

  final isLoading = false.obs;
  final bioLength = 0.obs;

  final avatarPicked = Rxn<File>();
  final nameError = Rxn<String>();
  final bioError = Rxn<String>();
  final provinceError = Rxn<String>();
  final fishTypesError = Rxn<String>();

  /// Server validation (422) messages without a dedicated field above.
  final formError = Rxn<String>();

  /// API.md §7.8 validation: `bio` max 300, `name` min 3.
  static const int bioMax = 300;

  @override
  void onInit() {
    super.onInit();
    final user = AuthService.currentUser.value;
    if (user != null) {
      nameController.text = user.name;
      bioController.text = user.bio ?? '';
      provinceController.text = user.province ?? '';
      fishTypesController.text = user.fishTypes.join(', ');
    }
    bioLength.value = bioController.text.length;
    bioController.addListener(() {
      bioLength.value = bioController.text.length;
      bioError.value = null;
    });
    nameController.addListener(() => nameError.value = null);
    provinceController.addListener(() => provinceError.value = null);
    fishTypesController.addListener(() => fishTypesError.value = null);
  }

  Future<void> pickAvatar() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        imageQuality: 90,
      );
      if (picked == null) return;
      avatarPicked.value =
          await compressImage(File(picked.path), maxBytes: 2 * 1024 * 1024);
    } catch (_) {
      AppTheme.error('Gagal', 'Foto profil tidak dapat dipilih. Coba lagi.');
    }
  }

  List<String> get _fishTypes => fishTypesController.text
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> save() async {
    if (isLoading.value) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final name = nameController.text.trim();
    var invalid = false;
    if (name.length < 3) {
      nameError.value = 'Nama minimal 3 karakter.';
      invalid = true;
    }
    if (bioController.text.trim().length > bioMax) {
      bioError.value = 'Bio maksimal $bioMax karakter.';
      invalid = true;
    }
    if (invalid) return;

    formError.value = null;
    isLoading.value = true;

    final res = await ApiClient.put<dynamic>(
      '/user/profile',
      data: {
        'name': name,
        'bio': bioController.text.trim(),
        'province': provinceController.text.trim(),
        'fish_types': _fishTypes,
      },
    );

    if (!res.success) {
      isLoading.value = false;
      nameError.value = res.fieldError('name');
      bioError.value = res.fieldError('bio');
      provinceError.value = res.fieldError('province');
      fishTypesError.value = res.fieldError('fish_types');
      if (!res.hasFieldErrors) formError.value = res.errorText;
      return;
    }

    if (res.data is Map<String, dynamic>) {
      await AuthService.updateUser(User.fromJson(res.data));
    }

    final avatar = avatarPicked.value;
    if (avatar != null) {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          avatar.path,
          filename: avatar.path.split(RegExp(r'[/\\]')).last,
        ),
      });
      final avatarRes =
          await ApiClient.postMultipart<dynamic>('/user/avatar', formData: formData);
      if (!avatarRes.success) {
        isLoading.value = false;
        AppTheme.error('Gagal', 'Foto profil gagal diunggah. ${avatarRes.errorText}');
        return;
      }
      final avatarUrl = avatarRes.data is Map<String, dynamic>
          ? (avatarRes.data as Map<String, dynamic>)['avatar_url'] as String?
          : null;
      final current = AuthService.currentUser.value;
      if (current != null && avatarUrl != null) {
        await AuthService.updateUser(User(
          id: current.id,
          name: current.name,
          username: current.username,
          email: current.email,
          phone: current.phone,
          avatarUrl: avatarUrl,
          bio: current.bio,
          province: current.province,
          fishTypes: current.fishTypes,
          reputationPoints: current.reputationPoints,
          reputationLevel: current.reputationLevel,
          role: current.role,
          emailVerifiedAt: current.emailVerifiedAt,
          createdAt: current.createdAt,
        ));
      }
    }

    isLoading.value = false;
    AppTheme.success('Berhasil', 'Profil berhasil diperbarui');
    Get.back();
  }

  @override
  void onClose() {
    nameController.dispose();
    bioController.dispose();
    provinceController.dispose();
    fishTypesController.dispose();
    super.onClose();
  }
}
