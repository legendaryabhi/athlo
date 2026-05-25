import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../supabase_client.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String displayName = 'Athlete';
  int currentStreak = 0;
  int totalSessions = 0;
  int todayDurationMinutes = 0;
  List<Map<String, dynamic>> todaySessions = [];
  List<Map<String, dynamic>> milestones = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await SupabaseConfig.client
          .from('profiles')
          .select('full_name, username')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        displayName = profile['full_name'] ?? profile['username'] ?? 'Athlete';
      }

      final sessions = await SupabaseConfig.client
          .from('sessions')
          .select('created_at, duration_seconds')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      totalSessions = sessions.length;
      final totalSecs = sessions.fold<int>(0, (sum, s) => sum + (s['duration_seconds'] as int? ?? 0));

      currentStreak = _calculateStreak(sessions);

      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      todaySessions = sessions.where((s) => (s['created_at'] as String).startsWith(todayStr)).toList();
      final todaySecs = todaySessions.fold<int>(0, (sum, s) => sum + (s['duration_seconds'] as int? ?? 0));
      todayDurationMinutes = todaySecs ~/ 60;

      milestones = [];
      if (totalSessions >= 1) milestones.add({'title': "First Step", 'desc': "Completed your first workout", 'icon': Icons.track_changes, 'active': true});
      if (totalSessions >= 5) milestones.add({'title': "Consistent", 'desc': "Completed 5 workouts", 'icon': Icons.show_chart, 'active': true});
      if (totalSessions >= 10) milestones.add({'title': "Dedicated", 'desc': "Completed 10 workouts", 'icon': Icons.local_fire_department_outlined, 'active': true});
      if (totalSecs >= 3600) milestones.add({'title': "Hour of Power", 'desc': "Trained for over 1 hour total", 'icon': Icons.access_time, 'active': true});
      
      if (totalSessions < 10 && totalSessions >= 1) {
        milestones.add({'title': "Dedicated", 'desc': "Complete 10 workouts", 'icon': Icons.track_changes, 'active': false});
      }

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint(e.toString());
      setState(() => isLoading = false);
    }
  }

  int _calculateStreak(List<dynamic> sessions) {
    if (sessions.isEmpty) return 0;
    
    final uniqueDates = sessions.map((s) => (s['created_at'] as String).substring(0, 10)).toSet().toList();
    uniqueDates.sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final todayStr = today.toIso8601String().substring(0, 10);
    final yesterdayStr = yesterday.toIso8601String().substring(0, 10);

    int streak = 0;
    if (uniqueDates.isNotEmpty && (uniqueDates[0] == todayStr || uniqueDates[0] == yesterdayStr)) {
      streak = 1;
      DateTime expectedDate = DateTime.parse(uniqueDates[0]).subtract(const Duration(days: 1));
      
      for (int i = 1; i < uniqueDates.length; i++) {
        if (uniqueDates[i] == expectedDate.toIso8601String().substring(0, 10)) {
          streak++;
          expectedDate = expectedDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }
    return streak;
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

    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground(isDark),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), // padding for bottom nav
            children: [
              // Header matching design
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.show_chart, size: 32),
                  Row(
                    children: [
                      GlassCard(
                        padding: const EdgeInsets.all(8),
                        borderRadius: 12,
                        child: Icon(Icons.bar_chart, size: 20),
                      ),
                      const SizedBox(width: 12),
                      GlassCard(
                        padding: const EdgeInsets.all(8),
                        borderRadius: 12,
                        child: Icon(Icons.notifications_none, size: 20),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 32),
              
              Text.rich(
                TextSpan(
                  text: 'Welcome, ',
                  style: const TextStyle(fontSize: 28),
                  children: [
                    TextSpan(text: displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: '!'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Today is ${DateTime.now().toString().substring(0, 10)}', 
                   style: const TextStyle(fontSize: 14, color: Colors.grey)),
              
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Today's stats", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("View more", style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(child: _buildStatCard('Active Time', '$todayDurationMinutes min', Icons.access_time)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Streak', '$currentStreak days', Icons.local_fire_department_outlined)),
                ],
              ),
              
              const SizedBox(height: 32),
              const Text("Milestones", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              ...milestones.map((m) => _buildMilestoneCard(m)),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Above bottom nav
        child: FloatingActionButton(
          onPressed: () => context.push('/session'),
          backgroundColor: AppTheme.accentColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          FittedBox(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Good', style: TextStyle(fontSize: 12, color: Colors.white)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.accentColor, width: 2),
                  ),
                  child: Icon(icon, color: AppTheme.accentColor, size: 20),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(Map<String, dynamic> m) {
    return Opacity(
      opacity: m['active'] ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GlassCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: m['active'] ? AppTheme.accentColor.withOpacity(0.2) : Colors.black12,
                shape: BoxShape.circle,
              ),
              child: Icon(m['icon'], color: m['active'] ? AppTheme.accentColor : Colors.grey),
            ),
            title: Text(m['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(m['desc']),
            trailing: m['active'] ? const Icon(Icons.emoji_events_outlined, color: AppTheme.accentColor) : null,
          ),
        ),
      ),
    );
  }
}
