import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/common/widgets/custom_appbar.dart';
import 'package:frontend/features/account/services/account_service.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';

class EditProfileScreen extends StatefulWidget {
  static const String routeName = '/edit-profile';
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillController = TextEditingController();

  final AccountService accountService = AccountService();
  List<String> skills = [];
  dynamic selectedAvatar;
  bool isLoading = false;
  bool isProcessingImage = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    _nameController.text = user.name;
    _bioController.text = user.bio ?? '';
    skills = List.from(user.skills ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  void _selectAvatar() async {
    try {
      setState(() => isProcessingImage = true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          if (kIsWeb) {
            selectedAvatar = result.files.first.bytes;
          } else {
            selectedAvatar = File(result.files.single.path!);
          }
        });
      }
    } catch (e) {
      showSnackBar(
        context,
        tr('error_selecting_image').replaceAll('{error}', e.toString()),
      );
    } finally {
      setState(() => isProcessingImage = false);
    }
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !skills.contains(skill)) {
      setState(() {
        skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      skills.remove(skill);
    });
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await accountService.updateProfile(
        context: context,
        name: _nameController.text,
        bio: _bioController.text,
        skills: skills,
        avatar: selectedAvatar,
      );

      Navigator.pop(context);
      showSnackBar(context, tr('success_profile_updated'));
    } catch (e) {
      showSnackBar(context, tr('error').replaceAll('{error}', e.toString()));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: tr('edit_profile_title'),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _saveProfile,
            child: Text(
              tr('save'),
              style: TextStyle(
                color: GlobalVariables.primaryBlue,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar section
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 64,
                                  backgroundColor:
                                      user.avatarColor?.toColor() ??
                                      GlobalVariables.blueAvatar,
                                  backgroundImage: _getAvatarImage(),
                                  child: _getAvatarImage() == null
                                      ? Text(
                                          user.name.isNotEmpty
                                              ? user.name
                                                    .substring(0, 1)
                                                    .toUpperCase()
                                              : "U",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 60,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        )
                                      : null,
                                ),

                                // Loading overlay khi đang xử lý ảnh
                                if (isProcessingImage)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.42,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: GlobalVariables.white,
                                          strokeWidth: 3,
                                        ),
                                      ),
                                    ),
                                  ),

                                Positioned(
                                  bottom: 0,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: isProcessingImage
                                        ? null
                                        : _selectAvatar,
                                    child: Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: GlobalVariables.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 32),

                      // Name field
                      _buildSection(
                        context,
                        title: tr('full_name'),
                        child: TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration(
                            context,
                            tr('enter_full_name'),
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return tr('validation_enter_full_name');
                            }
                            return null;
                          },
                        ),
                      ),

                      SizedBox(height: 24),

                      // Bio field
                      _buildSection(
                        context,
                        title: tr('bio'),
                        child: TextFormField(
                          controller: _bioController,
                          decoration: _inputDecoration(
                            context,
                            tr('write_about_yourself'),
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 4,
                          maxLength: 300,
                        ),
                      ),

                      SizedBox(height: 24),

                      // Skills section
                      _buildSection(
                        context,
                        title: tr('skills'),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _skillController,
                                    decoration: _inputDecoration(
                                      context,
                                      tr('add_skill'),
                                    ),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                    onSubmitted: (_) => _addSkill(),
                                  ),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _addSkill,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    foregroundColor: GlobalVariables.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Icon(Icons.add),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            if (skills.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDarkMode
                                        ? GlobalVariables.darkBorderPrimary
                                        : GlobalVariables.borderPrimary,
                                  ),
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: skills
                                      .map(
                                        (skill) => _buildEditableSkillTag(
                                          context,
                                          skill,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                      ),

                      SizedBox(height: 100), // Bottom spacing
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  ImageProvider? _getAvatarImage() {
    if (selectedAvatar != null) {
      if (kIsWeb) {
        return MemoryImage(selectedAvatar as Uint8List);
      } else {
        return FileImage(selectedAvatar as File);
      }
    } else if (Provider.of<UserProvider>(context).user.avatar != null &&
        Provider.of<UserProvider>(context).user.avatar!.isNotEmpty) {
      return NetworkImage(Provider.of<UserProvider>(context).user.avatar!);
    }
    return null;
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDarkMode
              ? GlobalVariables.darkBorderPrimary
              : GlobalVariables.borderPrimary,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDarkMode
              ? GlobalVariables.darkBorderPrimary
              : GlobalVariables.borderPrimary,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildEditableSkillTag(BuildContext context, String skill) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            skill,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(width: 4),
          GestureDetector(
            onTap: () => _removeSkill(skill),
            child: Icon(
              Icons.close,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
