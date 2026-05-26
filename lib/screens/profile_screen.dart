import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../supabase_client.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/session_export_overlay.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  String _calisthenicsLevel = 'Beginner';
  String _email = '';
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _showSessions = true;
  
  List<dynamic> _userSessions = [];
  List<dynamic> _userPosts = [];
  final ScreenshotController _screenshotController = ScreenshotController();

  final levels = ['Beginner', 'Intermediate', 'Advanced', 'Elite'];

  @override
  void initState() {
    super.initState();
    _fetchProfileAndSessions();
  }

  Future<void> _fetchProfileAndSessions() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    
    _email = user.email ?? '';

    try {
      final profile = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        _usernameController.text = profile['username'] ?? '';
        _fullNameController.text = profile['full_name'] ?? '';
        _calisthenicsLevel = profile['calisthenics_level'] ?? 'Beginner';
      }

      final sessions = await SupabaseConfig.client
          .from('sessions')
          .select('*, likes(user_id), comments(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
          
      _userSessions = sessions;

      final posts = await SupabaseConfig.client
          .from('posts')
          .select('*, profiles(username, full_name, avatar_url, calisthenics_level), sessions(*), likes(user_id), comments(*)')
          .eq('user_id', user.id)
          .isFilter('session_id', null)
          .order('created_at', ascending: false);
          
      _userPosts = posts;

    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    try {
      await SupabaseConfig.client.from('profiles').upsert({
        'id': user.id,
        'username': _usernameController.text,
        'full_name': _fullNameController.text,
        'calisthenics_level': _calisthenicsLevel,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    await SupabaseConfig.client.auth.signOut();
    if (mounted) context.go('/login');
  }

  Future<void> _deletePost(String postId, {String? sessionId}) async {
    try {
      if (sessionId != null) {
        await SupabaseConfig.client.from('sessions').delete().match({'id': sessionId});
      } else {
        await SupabaseConfig.client.from('posts').delete().match({'id': postId});
      }
      _fetchProfileAndSessions();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    try {
      await SupabaseConfig.client.from('sessions').delete().match({'id': sessionId});
      _fetchProfileAndSessions();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _editPostCaption(String postId, String newCaption) async {
    try {
      await SupabaseConfig.client.from('posts').update({'caption': newCaption}).match({'id': postId});
      _fetchProfileAndSessions();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post updated')));
    } catch (e) {
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

  Future<void> _downloadAndShareSession(Map<String, dynamic> session) async {
    if (session['photo_url'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No photo available to export.')));
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating image...')));
      
      final durationStr = _formatDuration(session['duration_seconds'] as int);

      final Uint8List capturedImage = await _screenshotController.captureFromWidget(
        SessionExportOverlay(
          photoUrl: session['photo_url'],
          calisthenicsLevel: _calisthenicsLevel,
          durationFormatted: durationStr,
          skillsWorked: session['skills_worked'],
          sessionDate: DateTime.parse(session['created_at'].toString()),
        ),
        delay: const Duration(seconds: 1), // allow image to load
      );

      final xFile = XFile.fromData(capturedImage, mimeType: 'image/png', name: 'athlo_workout.png');
      await Share.shareXFiles([xFile], text: 'Just completed a $durationStr calisthenics workout on Athlo!');
      
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate image')));
    }
  }
  
  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: AppTheme.gradientBackground(isDark),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: isDark ? Colors.black26 : Colors.white24),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined),
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  // Cancel edit, reset fields
                  _fetchProfileAndSessions(); 
                  _isEditing = false;
                } else {
                  _isEditing = true;
                }
              });
            },
          ),
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.logout_outlined), onPressed: _signOut),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground(isDark),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildProfileCard(isDark),
                      const SizedBox(height: 24),
                      GlassCard(
                        child: SwitchListTile(
                          title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Toggle app appearance'),
                          value: themeProvider.isDarkMode,
                          activeColor: AppTheme.accentColor,
                          onChanged: (value) => themeProvider.toggleTheme(),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _showSessions = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _showSessions ? AppTheme.accentColor : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Center(
                                  child: Text('Sessions', style: TextStyle(
                                    fontWeight: _showSessions ? FontWeight.bold : FontWeight.normal,
                                    color: _showSessions ? AppTheme.accentColor : Colors.grey,
                                  )),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _showSessions = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: !_showSessions ? AppTheme.accentColor : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Center(
                                  child: Text('Posts', style: TextStyle(
                                    fontWeight: !_showSessions ? FontWeight.bold : FontWeight.normal,
                                    color: !_showSessions ? AppTheme.accentColor : Colors.grey,
                                  )),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              
              if (_showSessions && _userSessions.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No sessions recorded yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ),
                  ),
                )
              else if (!_showSessions && _userPosts.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No posts yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _showSessions 
                        ? _buildSessionCard(_userSessions[index])
                        : _buildPostCard(_userPosts[index]),
                    childCount: _showSessions ? _userSessions.length : _userPosts.length,
                  ),
                ),
                
              const SliverToBoxAdapter(child: SizedBox(height: 100)), // padding for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    return GlassCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.accentColor,
            child: Text(
              _fullNameController.text.isNotEmpty ? _fullNameController.text[0].toUpperCase() : 'A',
              style: const TextStyle(fontSize: 32, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(_email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),
          
          _buildFieldLabel('Username'),
          if (_isEditing)
            TextField(
              controller: _usernameController,
              decoration: _inputDecoration(isDark),
            )
          else
            _buildReadOnlyField(_usernameController.text.isEmpty ? 'Not set' : _usernameController.text, isDark),
          const SizedBox(height: 16),
          
          _buildFieldLabel('Full Name'),
          if (_isEditing)
            TextField(
              controller: _fullNameController,
              decoration: _inputDecoration(isDark),
            )
          else
            _buildReadOnlyField(_fullNameController.text.isEmpty ? 'Not set' : _fullNameController.text, isDark),
          const SizedBox(height: 16),

          _buildFieldLabel('Level'),
          if (_isEditing)
            DropdownButtonFormField<String>(
              value: levels.contains(_calisthenicsLevel) ? _calisthenicsLevel : 'Beginner',
              items: levels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (val) => setState(() => _calisthenicsLevel = val!),
              decoration: _inputDecoration(isDark),
            )
          else
            _buildReadOnlyField(_calisthenicsLevel, isDark),
            
          if (_isEditing) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Save Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Align(
        alignment: Alignment.centerLeft, 
        child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))
      ),
    );
  }

  InputDecoration _inputDecoration(bool isDark) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: isDark ? Colors.black26 : Colors.white54,
    );
  }

  Widget _buildReadOnlyField(String text, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black12 : Colors.white24,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final photoUrl = session['photo_url'];
    final likes = List.from(session['likes'] ?? []);
    final comments = List.from(session['comments'] ?? []);
    final isPrivate = session['is_private'] == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(session['created_at'].toString().substring(0, 10), style: const TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPrivate) const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'delete') {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Theme.of(context).cardColor,
                                title: const Text('Delete Session'),
                                content: const Text('Are you sure you want to delete this session?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _deleteSession(session['id']);
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
                  )
                ],
              ),
            ),
            if (photoUrl != null)
              Image.network(photoUrl, height: 250, fit: BoxFit.cover),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Workout Time: ${_formatDuration(session['duration_seconds'])}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (session['skills_worked'] != null && session['skills_worked'].isNotEmpty)
                    Text('Skills: ${session['skills_worked']}'),
                  
                  const Divider(height: 24),
                  
                  Row(
                    children: [
                      const Icon(Icons.favorite_border, size: 20, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${likes.length}'),
                      const SizedBox(width: 16),
                      const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${comments.length}'),
                      const Spacer(),
                      if (photoUrl != null)
                        ElevatedButton.icon(
                          onPressed: () => _downloadAndShareSession(session),
                          icon: const Icon(Icons.download_outlined, size: 16, color: Colors.white),
                          label: const Text('Export', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
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
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final profile = post['profiles'] ?? {};
    final displayName = profile['full_name'] ?? profile['username'] ?? 'Athlete';
    final avatarUrl = profile['avatar_url'];
    final session = post['sessions'];
    final caption = post['caption'];
    final mediaUrl = post['media_url'];

    final likes = List.from(post['likes'] ?? []);
    final comments = List.from(post['comments'] ?? []);
    final currentUserId = SupabaseConfig.client.auth.currentUser?.id;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
                    if (session != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.accentColor),
                        ),
                        child: const Text('TRAINED', style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
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
                          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit')])),
                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
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
              Image.network(mediaUrl, height: 250, fit: BoxFit.cover),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (session != null) ...[
                    Text('Workout Time: ${_formatDuration(session['duration_seconds'])}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (session['skills_worked'] != null && session['skills_worked'].isNotEmpty)
                      Text('Skills: ${session['skills_worked']}'),
                    const Divider(height: 24),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.favorite_border, size: 20, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${likes.length}'),
                      const SizedBox(width: 16),
                      const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${comments.length}'),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
