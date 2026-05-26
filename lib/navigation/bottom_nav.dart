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
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive outer padding to handle narrow screens gracefully
    final double horizontalPadding = screenWidth < 360 ? 12.0 : 24.0;
    final double verticalPadding = screenWidth < 360 ? 8.0 : 16.0;

    return Scaffold(
      extendBody: true, // Important for floating nav bar to sit over background
      body: child,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.all(screenWidth < 360 ? 6.0 : 8.0),
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
                    _buildNavItem(context, Icons.home, Icons.home_outlined, 'Home', 0, '/home', isDark, screenWidth),
                    _buildNavItem(context, Icons.feed, Icons.feed_outlined, 'Feed', 1, '/feed', isDark, screenWidth),
                    _buildNavItem(context, Icons.person, Icons.person_outline, 'Profile', 2, '/profile', isDark, screenWidth),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData activeIcon, IconData inactiveIcon, String label, int index, String route, bool isDark, double screenWidth) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isSelected = selectedIndex == index;

    // Responsive padding and sizes
    final isSmallScreen = screenWidth < 360;
    final double horizontalItemPadding = isSelected 
        ? (isSmallScreen ? 14.0 : 24.0) 
        : (isSmallScreen ? 10.0 : 14.0);
    final double verticalItemPadding = isSmallScreen ? 10.0 : 14.0;
    final double iconSize = isSmallScreen ? 20.0 : 26.0;
    
    // Hide text on extremely small screens (e.g. width < 320) to prevent overflow
    final showText = isSelected && screenWidth >= 320;

    return GestureDetector(
      onTap: () {
        if (route.isNotEmpty) context.go(route);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalItemPadding, 
          vertical: verticalItemPadding
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
              size: iconSize,
            ),
            if (showText) ...[
              SizedBox(width: isSmallScreen ? 6 : 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: isSmallScreen ? 13 : 16,
                    letterSpacing: 0.5,
                  ),
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
