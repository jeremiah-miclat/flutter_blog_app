import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlogsRepository {
  BlogsRepository(this._supabaseClient);
  final SupabaseClient _supabaseClient;

  User? get currentUser => _supabaseClient.auth.currentUser;
  String? get authorName =>
      currentUser?.userMetadata?['display_name']?.toString();
  String? get userId => currentUser?.id.toString();

  Future<({List<Map<String, dynamic>> blogs, int count})> getBlogs() async {
    final blogsResponse = await _supabaseClient
        .from('blogs')
        .select()
        .order('created_at', ascending: false);

    final count = await _supabaseClient.from('blogs').count(CountOption.exact);

    final storage = _supabaseClient.storage.from('blogs-image');

    final blogs = <Map<String, dynamic>>[];

    for (final blog in blogsResponse) {
      final blogId = blog['id'].toString();

      final files = await storage.list(path: blogId);

      final images = files
          .where(
            (f) =>
                f.name.endsWith('.png') ||
                f.name.endsWith('.jpg') ||
                f.name.endsWith('.jpeg') ||
                f.name.endsWith('.webp'),
          )
          .map((f) => '$blogId/${f.name}')
          .toList();

      blogs.add({...blog, 'images': images});
    }

    return (blogs: blogs, count: count);
  }

  Future<({Map<String, dynamic> blog, List<dynamic> images})> getBlogById(
    String id,
  ) async {
    final blog = await _supabaseClient
        .from('blogs')
        .select()
        .eq('id', id)
        .single();

    final storage = _supabaseClient.storage.from('blogs-image');

    final images = await storage.list(path: id);

    return (blog: blog, images: images);
  }

  Future<void> createBlog({
    required String title,
    required String content,
    required List<dynamic> files,
  }) async {
    final storage = _supabaseClient.storage.from('blogs-image');

    final blogData = {
      'title': title,
      'content': content,
      'author_name': authorName,
      'user_id': userId,
    };

    final response = await _supabaseClient
        .from('blogs')
        .insert(blogData)
        .select()
        .single();

    final blogId = response['id'].toString();
    debugPrint('New blog ID: $blogId');

    for (final file in files) {
      if (file.bytes == null) continue;

      final filePath = '$blogId/${file.name}';

      final res = await storage.uploadBinary(filePath, file.bytes!);

      debugPrint('Upload response: $res');
    }
  }

  Future<Map<String, dynamic>> deleteBlog(String id) async {
    final response = await _supabaseClient
        .from('blogs')
        .delete()
        .eq('id', id)
        .select()
        .single();
    return response;
  }

  Future<List<dynamic>> getBlogImages(String blogId) async {
    final storage = _supabaseClient.storage.from('blogs-image');
    return await storage.list(path: blogId);
  }
}
