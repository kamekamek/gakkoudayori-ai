import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SeasonCard extends StatelessWidget {
  final String seasonName;
  final List<Color> colors;
  final bool isSelected;
  final VoidCallback onTap;

  const SeasonCard({
    super.key,
    required this.seasonName,
    required this.colors,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 120,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors[0] : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: colors[0].withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: isSelected ? 8 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getSeasonIcon(),
                  size: 32,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  seasonName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '選択中',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate(target: isSelected ? 1 : 0)
      .scale(
        begin: const Offset(1.0, 1.0),
        end: const Offset(1.05, 1.05),
        duration: const Duration(milliseconds: 200),
      );
  }

  IconData _getSeasonIcon() {
    switch (seasonName) {
      case '春':
        return Icons.local_florist;
      case '夏':
        return Icons.wb_sunny;
      case '秋':
        return Icons.eco;
      case '冬':
        return Icons.ac_unit;
      default:
        return Icons.calendar_today;
    }
  }
}