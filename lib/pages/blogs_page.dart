import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blog_app/pages/blog_page.dart';
import 'package:flutter_blog_app/repository/blogs.dart';
import 'package:flutter_blog_app/services/db_realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlogsPage extends StatefulWidget {
  const BlogsPage({super.key});

  @override
  State<BlogsPage> createState() => _BlogsPageState();
}

class _BlogsPageState extends State<BlogsPage> {
  final _blogRepo = BlogsRepository(Supabase.instance.client);

  static const int _pageSize = 5;
  int _currentPage = 0;

  List<dynamic> _blogs = [];
  bool _loading = true;

  StreamSubscription? _realtimeSub;
  bool _hasNewBlogs = false;

  int get _pageCount => (_blogs.length / _pageSize).ceil().clamp(1, 1 << 30);

  void _ensureValidPage() {
    final maxPageIndex = (_pageCount - 1).clamp(0, 1 << 30);
    if (_currentPage > maxPageIndex) _currentPage = maxPageIndex;
    if (_currentPage < 0) _currentPage = 0;
  }

  List<dynamic> get _pagedBlogs {
    if (_blogs.isEmpty) return [];
    _ensureValidPage();

    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _blogs.length);
    return _blogs.sublist(start, end);
  }

  List<int> get _visiblePages {
    const maxButtons = 5;
    final total = _pageCount;

    final current = _currentPage + 1;
    var start = current - (maxButtons ~/ 2);
    var end = start + maxButtons - 1;

    if (start < 1) {
      start = 1;
      end = (start + maxButtons - 1).clamp(1, total);
    }
    if (end > total) {
      end = total;
      start = (end - maxButtons + 1).clamp(1, total);
    }

    return [for (int i = start; i <= end; i++) i];
  }

  Future<void> _fetchBlogs() async {
    setState(() => _loading = true);

    try {
      final result = await _blogRepo.getBlogs();
      debugPrint("Number of blogs: ${result.count}");

      if (!mounted) return;

      setState(() {
        _blogs = result.blogs;
        _ensureValidPage();
      });
    } catch (e) {
      debugPrint("Fetch blogs failed: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();

    _fetchBlogs();

    SupabaseRealtimeService.instance.start();

    _realtimeSub = SupabaseRealtimeService.instance.stream.listen((event) {
      if (!mounted) return;

      if (event['table'] == 'blogs' && event['event'] == 'INSERT') {
        _hasNewBlogs = true;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('New blog posted. Tap to reload.'),
            action: SnackBarAction(
              label: 'Reload',
              onPressed: () {
                _hasNewBlogs = false;
                _fetchBlogs();
              },
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paged = _pagedBlogs;

    return Scaffold(
      appBar: AppBar(title: const Text('Blogs')),
      body: Column(
        children: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            child: const Text('Profiles'),
          ),
          TextButton(onPressed: _fetchBlogs, child: const Text('Fetch blogs')),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/create'),
            child: const Text('Create blog'),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),

          if (!_loading && _blogs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No blogs yet'),
            ),

          Expanded(
            child: ListView.builder(
              itemCount: paged.length,
              itemBuilder: (context, index) {
                final blog = paged[index];
                final title = blog['title'] as String?;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => BlogPage(blog: blog)),
                      );
                    },
                    child: Text(
                      title ?? 'Untitled Blog',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),

          if (!_loading && _blogs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final p in _visiblePages)
                    OutlinedButton(
                      onPressed: () => setState(() => _currentPage = p - 1),
                      child: Text(
                        '$p',
                        style: TextStyle(
                          fontWeight: (_currentPage == p - 1)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
