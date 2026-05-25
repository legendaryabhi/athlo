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
  
  List<dynamic> _userSessions = [];
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

  Future<void> _downloadAndShareSession(Map<String, dynamic> session) async {
    if (session['photo_url'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No photo available to export.')));
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating image...')));
      
      final m = (session['duration_seconds'] as int) ~/ 60;
      final durationStr = '$m min';

      final Uint8List capturedImage = await _screenshotController.captureFromWidget(
        SessionExportOverlay(
          photoUrl: session['photo_url'],
          displayName: _fullNameController.text.isNotEmpty ? _fullNameController.text : _usernameController.text,
          durationFormatted: durationStr,
          skillsWorked: session['skills_worked'],
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
    final m = seconds ~/ 60;
    return '$m min';
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
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('My Sessions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              
              if (_userSessions.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No sessions recorded yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildSessionCard(_userSessions[index]),
                    childCount: _userSessions.length,
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
                  if (isPrivate) const Icon(Icons.lock_outline, size: 16, color: Colors.grey)
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
}
