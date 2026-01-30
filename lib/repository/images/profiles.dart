import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileImagerepository {
  ProfileImagerepository(this._supabaseClient);
  final SupabaseClient _supabaseClient;

  Future<({String path, String url})> uploadAvatar({
    required String userId,
    required String fileExt,
    required PlatformFile file,
  }) async {
    final storage = _supabaseClient.storage.from('profiles-image');

    final existingImages = await storage.list(path: userId);

    if (existingImages.isNotEmpty) {
      final imagesPaths = existingImages
          .map((item) => '$userId/${item.name}')
          .toList();
      await storage.remove(imagesPaths);
    }

    final dt = DateTime.now();
    final imagePath = '$userId/avatar_$dt.$fileExt';
    final url = storage.getPublicUrl(imagePath);
    String uploadPath = await storage.uploadBinary(imagePath, file.bytes!);
    debugPrint("Upload path: $uploadPath");
    return (path: imagePath, url: url);
  }
}
