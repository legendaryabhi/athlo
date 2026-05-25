import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../supabase_client.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> with SingleTickerProviderStateMixin {
  bool isActive = false;
  int secondsElapsed = 0;
  Timer? timer;
  
  // Modal state
  final _skillsController = TextEditingController();
  XFile? _photo;
  bool _isPrivate = false;
  bool _isSaving = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(_animController);
  }

  @override
  void dispose() {
    timer?.cancel();
    _skillsController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleSession() {
    if (isActive) {
      // Stop session
      setState(() => isActive = false);
      timer?.cancel();
      _animController.reverse();
      _showShareModal();
    } else {
      // Start session
      setState(() {
        isActive = true;
        secondsElapsed = 0;
        _skillsController.clear();
        _photo = null;
        _isPrivate = false;
      });
      _animController.forward();
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() => secondsElapsed++);
      });
    }
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _photo = pickedFile);
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    String? photoUrl;

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      if (_photo != null) {
        final fileExt = _photo!.name.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        
        final bytes = await _photo!.readAsBytes();
        await SupabaseConfig.client.storage
            .from('photos')
            .uploadBinary(fileName, bytes);
            
        photoUrl = SupabaseConfig.client.storage.from('photos').getPublicUrl(fileName);
      }

      final now = DateTime.now();
      final startTime = now.subtract(Duration(seconds: secondsElapsed));

      final sessionRes = await SupabaseConfig.client.from('sessions').insert({
        'user_id': user.id,
        'start_time': startTime.toIso8601String(),
        'end_time': now.toIso8601String(),
        'duration_seconds': secondsElapsed,
        'skills_worked': _skillsController.text.trim(),
        'photo_url': photoUrl,
        'is_private': _isPrivate,
      }).select().single();

      if (!_isPrivate) {
        await SupabaseConfig.client.from('posts').insert({
          'user_id': user.id,
          'caption': _skillsController.text.trim().isNotEmpty 
              ? 'Trained: ${_skillsController.text.trim()}' 
              : 'Completed a new workout session!',
          'media_url': photoUrl,
          'media_type': photoUrl != null ? 'image' : null,
          'session_id': sessionRes['id'],
        });
      }

      if (mounted) {
        Navigator.pop(context); // Close modal
        context.go('/feed'); // Redirect to feed
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showShareModal() {
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
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Share Session', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  const Text('What did you work on?'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _skillsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Planche progressions, front lever holds...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Add a Photo'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      await _pickImage();
                      setModalState(() {});
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_upload_outlined),
                          const SizedBox(width: 8),
                          Text(_photo != null ? 'Photo Selected' : 'Upload photo'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Checkbox(
                        value: _isPrivate,
                        onChanged: (val) {
                          setModalState(() => _isPrivate = val ?? false);
                          setState(() => _isPrivate = val ?? false);
                        },
                      ),
                      const Text('Keep this session private'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isSaving ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                          child: Text(_isSaving ? 'Sharing...' : (_isPrivate ? 'Save Private' : 'Share to Community')),
                        ),
                      ),
                    ],
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground(isDark),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Text(
                  _formatTime(secondsElapsed),
                  style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 60),
              GestureDetector(
                onTap: _toggleSession,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 150, height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? Colors.redAccent : AppTheme.accentColor,
                    boxShadow: [
                      BoxShadow(
                        color: (isActive ? Colors.redAccent : AppTheme.accentColor).withOpacity(0.4),
                        blurRadius: 20, spreadRadius: 5
                      )
                    ]
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isActive ? 'Stop' : 'Start',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
