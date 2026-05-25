import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SessionExportOverlay extends StatelessWidget {
  final String photoUrl;
  final String displayName;
  final String durationFormatted;
  final String? skillsWorked;

  const SessionExportOverlay({
    super.key,
    required this.photoUrl,
    required this.displayName,
    required this.durationFormatted,
    this.skillsWorked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,
      color: Colors.black,
      child: Stack(
        children: [
          // Background Image
          Image.network(photoUrl, width: 1080, fit: BoxFit.fitWidth),
          
          // Gradient Overlay to ensure text readability
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black26,
                    Colors.black87,
                  ],
                  stops: [0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Content Overlay
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Right Branding (Athlo)
                  Align(
                    alignment: Alignment.topRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fitness_center, color: AppTheme.accentColor, size: 40),
                        const SizedBox(width: 12),
                        const Text(
                          'ATHLO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),

                  // User Info
                  Text(
                    displayName.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Workout Time
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        durationFormatted.split(' ')[0], // Extracts the number (e.g. '45' from '45 min')
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 120,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'MIN',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  // Skills / Message
                  if (skillsWorked != null && skillsWorked!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        skillsWorked!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
