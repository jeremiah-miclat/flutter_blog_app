import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blog_app/repository/images/profiles.dart';
import 'package:flutter_blog_app/repository/profiles.dart';
import 'package:flutter_blog_app/services/db_realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<StatefulWidget> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _profileRepo = ProfileRepository(Supabase.instance.client);
  final _imageRepo = ProfileImagerepository(Supabase.instance.client);

  bool _loading = true;
  bool _isEditing = false;

  final _displayNameController = TextEditingController();

  String? _avatarUrl;
  PlatformFile? _chosenImg;
  String? _chosenImgExt;

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      final user = _profileRepo.currentUser;
      if (user == null) return;

      final displayName =
          user.userMetadata?['display_name']?.toString() ??
          user.email?.toString() ??
          "";
      final avatarUrl = user.userMetadata?['avatar_url']?.toString();

      _displayNameController.text = displayName;
      _avatarUrl = avatarUrl;
      _chosenImg = null;
      _chosenImgExt = null;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _chooseImg() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null) return;

    final file = result.files.single;
    final ext = (file.extension ?? '').toLowerCase();
    if (!_isvalidExt(ext)) {
      _toast('File not valid (png/jpg/jpeg)');
      return;
    }

    setState(() {
      _chosenImg = file;
      _chosenImgExt = ext;
    });
  }

  bool _isvalidExt(String ext) {
    final e = ext.toLowerCase();
    if (e == 'png') return true;
    if (e == 'jpg' || e == 'jpeg') return true;
    if (e == 'webp') return true;
    return false;
  }

  Future<void> _save() async {
    final user = _profileRepo.currentUser;
    if (user == null) {
      _toast("Not logged in");
      return;
    }

    final displayName = _displayNameController.text.trim();
    if (displayName.isEmpty) {
      _toast("Display name is required");
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      String? avatarUrl;
      String? avatarPath;

      if (_chosenImg != null && _chosenImgExt != null) {
        final uploadResult = await _imageRepo.uploadAvatar(
          userId: user.id,
          fileExt: _chosenImgExt!,
          file: _chosenImg!,
        );
        avatarPath = uploadResult.path;
        avatarUrl = uploadResult.url;
      }

      final updatedProfile = await _profileRepo.updateProfile(
        displayName: displayName,
        avatarPath: avatarPath,
        avatarUrl: avatarUrl,
      );

      final newUrl = updatedProfile.userMetadata?['avatar_url']?.toString();

      if (!mounted) return;
      setState(() {
        _avatarUrl = newUrl;
        _chosenImg = null;
        _chosenImg = null;
        _chosenImgExt = null;
        _isEditing = false;
      });
      _toast('Profile updated!');
    } on AuthException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast("Failed to save. $e");
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _chosenImg = null;
      _chosenImgExt = null;
    });
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    await SupabaseRealtimeService.instance.stop();
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _profileRepo.currentUser;
    final avatarWidget = CircleAvatar(
      radius: 52,
      backgroundImage: _chosenImg != null
          ? MemoryImage(_chosenImg!.bytes!)
          : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
          ? NetworkImage(_avatarUrl!) as ImageProvider
          : null,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [TextButton(onPressed: _logout, child: const Text('Logout'))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : user == null
            ? const Center(child: Text('No user'))
            : Column(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      avatarWidget,
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.email ?? '-',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'ID: ${user.id}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Display Name',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  _isEditing
                      ? TextField(
                          controller: _displayNameController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Your display name',
                          ),
                        )
                      : Text(
                          (user.userMetadata?['display_name'] ??
                                  user.email ??
                                  '(Not set)')
                              .toString(),
                        ),
                  const SizedBox(height: 6),
                  if (_isEditing) ...[
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: _chooseImg,
                          icon: const Icon(Icons.image),
                          label: const Text('Change Photo'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: _cancelEdit,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _save,
                        child: const Text('Save'),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        FilledButton(
                          onPressed: () => setState(() => _isEditing = true),
                          child: const Text('Edit profile'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: _loadProfile,
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
