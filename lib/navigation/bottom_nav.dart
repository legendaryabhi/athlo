import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';

class BottomNavLayout extends StatelessWidget {
  final Widget child;

  const BottomNavLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      extendBody: true, // Important for floating nav bar to sit over background
      body: child,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkGlassBg : AppTheme.lightGlassBg,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: isDark ? AppTheme.darkGlassBorder : AppTheme.lightGlassBorder,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavItem(context, Icons.home, Icons.home_outlined, 'Home', 0, '/home', isDark),
                    _buildNavItem(context, Icons.feed, Icons.feed_outlined, 'Feed', 1, '/feed', isDark),
                    _buildNavItem(context, Icons.person, Icons.person_outline, 'Profile', 2, '/profile', isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData activeIcon, IconData inactiveIcon, String label, int index, String route, bool isDark) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        if (route.isNotEmpty) context.go(route);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 24 : 14, 
          vertical: 14
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(50), 
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              size: 26,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/feed')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }
}
