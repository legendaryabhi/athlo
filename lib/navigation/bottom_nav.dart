import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavLayout extends StatelessWidget {
  final Widget child;

  const BottomNavLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Important for floating nav bar to sit over background
      body: child,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F2C2A), // Premium dark teal matching the design
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(context, Icons.home, Icons.home_outlined, 'Home', 0, '/home'),
                _buildNavItem(context, Icons.feed, Icons.feed_outlined, 'Feed', 1, '/feed'),
                _buildNavItem(context, Icons.bar_chart, Icons.bar_chart_outlined, 'Stats', 2, ''), // Placeholder
                _buildNavItem(context, Icons.person, Icons.person_outline, 'Profile', 3, '/profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData activeIcon, IconData inactiveIcon, String label, int index, String route) {
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
          color: Colors.white,
          // When symmetric padding is equal, large border radius makes it a perfect circle.
          // When horizontal padding is larger, it becomes a pill shape.
          borderRadius: BorderRadius.circular(50), 
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: Colors.black,
              size: 26,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
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
    if (location.startsWith('/profile')) return 3; // Mapped to index 3 based on UI layout
    return 0;
  }
}
