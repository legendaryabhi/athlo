import 'package:flutter/material.dart';

class SessionExportOverlay extends StatelessWidget {
  final String photoUrl;
  final String calisthenicsLevel;
  final String durationFormatted;
  final String? skillsWorked;
  final DateTime sessionDate;

  const SessionExportOverlay({
    super.key,
    required this.photoUrl,
    required this.calisthenicsLevel,
    required this.durationFormatted,
    this.skillsWorked,
    required this.sessionDate,
  });

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[date.month - 1];
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '$month ${date.day}, ${date.year} at $hour12:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,
      height: 1920,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [

          // Background Image
          Image.network(
            photoUrl,
            fit: BoxFit.cover,
          ),

          // Dark Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(40, 0, 0, 0),
                    Color.fromARGB(120, 0, 0, 0),
                    Color.fromARGB(220, 0, 0, 0),
                  ],
                  stops: [0.2, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // Main Content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 100,
                bottom: 80,
                left: 40,
                right: 40,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Section
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ATHLO
                      Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 22,
    vertical: 8,
  ),
  decoration: BoxDecoration(
    color: const Color(0xFF1C2826), // darkBgTop
    borderRadius: BorderRadius.circular(10),
    border: Border.all( 
      color: Colors.white.withOpacity(0.08),
      width: 1,
    ),
  ),
  child: const Text(
    'ATHLO',
    textAlign: TextAlign.center,
    style: TextStyle(
      color: Color(0xFFFFFFFF), // darkText
      fontSize: 16,
      fontWeight: FontWeight.w900,
      letterSpacing: 2,
    ),
  ),
),

                      const SizedBox(height: 32),

                      // Level
                      Text(
                        'Calisthenics $calisthenicsLevel',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Skill Name
                      Text(
                        'Skill',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        skillsWorked != null &&
                                skillsWorked!.trim().isNotEmpty
                            ? skillsWorked!
                            : 'Workout Session',
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Time Label
                      Text(
                        'Time',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Time Value
                      Text(
                        durationFormatted,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // Bottom Section (Date)
                  Text(
                    _formatDate(sessionDate),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}