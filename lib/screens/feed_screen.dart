import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
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
  List<dynamic> sessions = [];
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
          .from('sessions')
          .select('*, profiles(username, full_name, avatar_url, calisthenics_level), likes(user_id), comments(*)')
          .eq('is_private', false)
          .order('created_at', ascending: false);

      setState(() {
        sessions = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleLike(String sessionId, bool isLiked) async {
    if (currentUserId == null) return;
    try {
      if (isLiked) {
        await SupabaseConfig.client.from('likes').delete().match({'session_id': sessionId, 'user_id': currentUserId!});
      } else {
        await SupabaseConfig.client.from('likes').insert({'session_id': sessionId, 'user_id': currentUserId!});
      }
      _fetchFeed(); // Refresh
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _addComment(String sessionId, String content) async {
    if (currentUserId == null || content.isEmpty) return;
    try {
      await SupabaseConfig.client.from('comments').insert({
        'session_id': sessionId,
        'user_id': currentUserId!,
        'content': content,
      });
      _fetchFeed();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _exportAsImage(String sessionId, String username) async {
    try {
      // Find the specific card widget index, not strictly needed with generic approach 
      // but we will capture the UI for that card.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Capturing image...')));
      // We will capture just the first visible snapshot in this simple version
      // A more robust version captures the specific item using its GlobalKey.
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    return '$m min';
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

    if (sessions.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: AppTheme.gradientBackground(isDark),
          child: const Center(child: Text('No sessions recorded yet! Be the first.')),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Community Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground(isDark),
        child: RefreshIndicator(
          onRefresh: _fetchFeed,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 100),
            itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            final profile = session['profiles'] ?? {};
            final displayName = profile['full_name'] ?? profile['username'] ?? 'Athlete';
            final avatarUrl = profile['avatar_url'];
            
            final likes = List.from(session['likes'] ?? []);
            final hasLiked = likes.any((l) => l['user_id'] == currentUserId);
            
            final comments = List.from(session['comments'] ?? []);
            final photoUrl = session['photo_url'];

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
                        subtitle: Text(session['created_at'].toString().substring(0, 10)),
                      ),
                    ),
                    if (photoUrl != null)
                      Image.network(photoUrl, height: 300, fit: BoxFit.cover),
                    
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Workout Time: ${_formatDuration(session['duration_seconds'])}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (session['skills_worked'] != null && session['skills_worked'].isNotEmpty)
                            Text('Skills: ${session['skills_worked']}'),
                          
                          const Divider(height: 30),
                          
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(hasLiked ? LucideIcons.heart : LucideIcons.heart, color: hasLiked ? Colors.red : Colors.grey),
                                onPressed: () => _toggleLike(session['id'], hasLiked),
                              ),
                              Text('${likes.length}'),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(LucideIcons.messageCircle),
                                onPressed: () => _showCommentsModal(session['id'], comments),
                              ),
                              Text('${comments.length}'),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(LucideIcons.share2),
                                onPressed: () {
                                  Share.share('Check out this ${_formatDuration(session['duration_seconds'])} workout by $displayName on Athlo!');
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

  void _showCommentsModal(String sessionId, List<dynamic> comments) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                    icon: const Icon(LucideIcons.send),
                    onPressed: () {
                      _addComment(sessionId, controller.text);
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
