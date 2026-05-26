import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../supabase_client.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<dynamic> posts = [];
  bool isLoading = true;
  String? currentUserId;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    currentUserId = SupabaseConfig.client.auth.currentUser?.id;
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    try {
      final data = await SupabaseConfig.client
          .from('posts')
          .select('*, profiles(username, full_name, avatar_url, calisthenics_level), sessions(*), likes(user_id), comments(*)')
          .order('created_at', ascending: false);

      setState(() {
        posts = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleLike(String postId, bool isLiked) async {
    if (currentUserId == null) return;
    try {
      if (isLiked) {
        await SupabaseConfig.client.from('likes').delete().match({'post_id': postId, 'user_id': currentUserId!});
      } else {
        await SupabaseConfig.client.from('likes').insert({'post_id': postId, 'user_id': currentUserId!});
      }
      _fetchFeed(); // Refresh
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _addComment(String postId, String content) async {
    if (currentUserId == null || content.isEmpty) return;
    try {
      await SupabaseConfig.client.from('comments').insert({
        'post_id': postId,
        'user_id': currentUserId!,
        'content': content,
      });
      _fetchFeed();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _deletePost(String postId, {String? sessionId}) async {
    try {
      if (sessionId != null) {
        await SupabaseConfig.client.from('sessions').delete().match({'id': sessionId});
      } else {
        await SupabaseConfig.client.from('posts').delete().match({'id': postId});
      }
      _fetchFeed();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post/Session deleted')));
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _editPostCaption(String postId, String newCaption) async {
    try {
      await SupabaseConfig.client.from('posts').update({'caption': newCaption}).match({'id': postId});
      _fetchFeed();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post updated')));
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showEditPostDialog(String postId, String currentCaption) {
    final controller = TextEditingController(text: currentCaption);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Edit Caption'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter new caption...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editPostCaption(postId, controller.text.trim());
            },
            child: const Text('Save', style: TextStyle(color: AppTheme.accentColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAsImage(String postId, String username) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Capturing image...')));
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    return '$m min';
  }

  void _showCreatePostModal() {
    final captionController = TextEditingController();
    XFile? selectedPhoto;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom > 0
                    ? MediaQuery.of(context).viewInsets.bottom + 20
                    : 110,
                left: 20, right: 20, top: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Create Post', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: captionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'What\'s on your mind?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  InkWell(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                      if (picked != null) {
                        setModalState(() => selectedPhoto = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_upload_outlined),
                          const SizedBox(width: 8),
                          Text(selectedPhoto != null ? 'Photo Selected' : 'Upload photo/video'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      if (captionController.text.trim().isEmpty && selectedPhoto == null) return;
                      setModalState(() => isSaving = true);
                      
                      try {
                        String? mediaUrl;
                        if (selectedPhoto != null) {
                          final fileExt = selectedPhoto!.name.split('.').last;
                          final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
                          final bytes = await selectedPhoto!.readAsBytes();
                          await SupabaseConfig.client.storage
                              .from('photos')
                              .uploadBinary(fileName, bytes);
                          mediaUrl = SupabaseConfig.client.storage.from('photos').getPublicUrl(fileName);
                        }

                        await SupabaseConfig.client.from('posts').insert({
                          'user_id': currentUserId,
                          'caption': captionController.text.trim(),
                          'media_url': mediaUrl,
                          'media_type': mediaUrl != null ? 'image' : null,
                        });
                        
                        if (mounted) {
                          Navigator.pop(context);
                          _fetchFeed();
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      } finally {
                        setModalState(() => isSaving = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
                    child: Text(isSaving ? 'Posting...' : 'Post', style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: AppTheme.gradientBackground(isDark),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (posts.isEmpty) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Community Feed', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(color: isDark ? Colors.black26 : Colors.white24),
            ),
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 90.0),
          child: FloatingActionButton(
            onPressed: _showCreatePostModal,
            backgroundColor: AppTheme.accentColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
        body: Container(
          decoration: AppTheme.gradientBackground(isDark),
          child: const Center(child: Text('No posts yet! Be the first.')),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Community Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: isDark ? Colors.black26 : Colors.white24),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          onPressed: _showCreatePostModal,
          backgroundColor: AppTheme.accentColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: Container(
        decoration: AppTheme.gradientBackground(isDark),
        child: RefreshIndicator(
          onRefresh: _fetchFeed,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 100),
            itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final profile = post['profiles'] ?? {};
            final displayName = profile['full_name'] ?? profile['username'] ?? 'Athlete';
            final avatarUrl = profile['avatar_url'];
            
            final likes = List.from(post['likes'] ?? []);
            final hasLiked = likes.any((l) => l['user_id'] == currentUserId);
            
            final comments = List.from(post['comments'] ?? []);
            final mediaUrl = post['media_url'];
            final session = post['sessions'];
            final caption = post['caption'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                          child: avatarUrl == null ? Text(displayName[0].toUpperCase()) : null,
                        ),
                        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(post['created_at'].toString().substring(0, 10)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (post['user_id'] == currentUserId)
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditPostDialog(post['id'], caption ?? '');
                                  } else if (value == 'delete') {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: Theme.of(context).cardColor,
                                        title: const Text('Delete Post'),
                                        content: const Text('Are you sure you want to delete this post?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _deletePost(post['id'], sessionId: post['session_id']);
                                            },
                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    if (caption != null && caption.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Text(caption, style: const TextStyle(fontSize: 16)),
                      ),

                    if (mediaUrl != null)
                      Image.network(mediaUrl, height: 300, fit: BoxFit.cover),
                    
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (session != null) ...[
                            Text('Workout Time: ${_formatDuration(session['duration_seconds'])}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Divider(height: 30),
                          ],
                          
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(hasLiked ? Icons.favorite : Icons.favorite_border, color: hasLiked ? Colors.red : Colors.grey),
                                onPressed: () => _toggleLike(post['id'], hasLiked),
                              ),
                              Text('${likes.length}'),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline),
                                onPressed: () => _showCommentsModal(post['id'], comments),
                              ),
                              Text('${comments.length}'),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.share_outlined),
                                onPressed: () {
                                  Share.share('Check out this post by $displayName on Athlo!');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ));
  }

  void _showCommentsModal(String postId, List<dynamic> comments) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom > 0 
                ? MediaQuery.of(context).viewInsets.bottom + 24 
                : 110, // 110px clears the bottom navigation
            left: 16, right: 16, top: 16
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (c, i) => ListTile(
                    title: Text(comments[i]['content']),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(hintText: 'Add a comment...'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_outlined),
                    onPressed: () {
                      _addComment(postId, controller.text);
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    );
  }
}
