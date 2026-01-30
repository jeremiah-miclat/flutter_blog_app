import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlogPage extends StatefulWidget {
  final Map<String, dynamic> blog;

  const BlogPage({super.key, required this.blog});

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  bool _loading = true;
  bool _isOwner = false;

  Map<String, dynamic>? _blog;
  List<dynamic> _images = [];

  @override
  void initState() {
    super.initState();
    _blog = widget.blog;

    _images = widget.blog['images'];
    _loadImagesAndOwner();
  }

  Future<void> _loadImagesAndOwner() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      final userId = currentUser?.id;

      if (!mounted) return;

      setState(() {
        _isOwner = _blog!['user_id'] == userId;
        debugPrint('Images: $_images');
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load blog extras: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_blog == null) {
      return const Scaffold(body: Center(child: Text('Blog not found')));
    }

    final storage = Supabase.instance.client.storage.from('blogs-image');

    return Scaffold(
      appBar: AppBar(title: Text(_blog!['title'] ?? 'Blog')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isOwner) ...[
            Text('Edit', style: Theme.of(context).textTheme.headlineSmall),
            Text('Delete', style: Theme.of(context).textTheme.headlineSmall),
          ],

          Text(
            _blog!['title'] ?? '',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'By ${_blog!['author_name'] ?? 'Unknown'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),

          Text(
            _blog!['content'] ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 24),

          if (_images.isNotEmpty) ...[
            Text('Images', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            for (final img in _images)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Image.network(
                  storage.getPublicUrl('$img'),
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
