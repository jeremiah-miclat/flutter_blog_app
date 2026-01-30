import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  ProfileRepository(this._supabaseClient);
  final SupabaseClient _supabaseClient;

  User? get currentUser => _supabaseClient.auth.currentUser;
  String? get displayName =>
      currentUser?.userMetadata?['display_name']?.toString();
  String? get avatarUrl => currentUser?.userMetadata?['avatar_url']?.toString();
  String? get avatarPath =>
      currentUser?.userMetadata?['avatar_path']?.toString();

  Future<User> updateProfile({
    required String displayName,
    String? avatarPath,
    String? avatarUrl,
  }) async {
    final userData = UserAttributes(
      data: {
        'display_name': displayName,
        if (avatarPath != null) 'avatar_path': avatarPath,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      },
    );
    final result = await _supabaseClient.auth.updateUser(userData);
    final user = result.user;
    if (user == null) {
      throw Exception('Failed to update user data');
    }

    return user;
  }
}
