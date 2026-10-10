import 'package:flutter/material.dart';
import '../../models/template.dart';

class TemplateCard extends StatelessWidget {
  final VideoTemplateModel template;
  final VoidCallback onTap;

  const TemplateCard({
    super.key,
    required this.template,
    required this.onTap,
  });

  LinearGradient _getTemplateGradient() {
    switch (template.tag.toUpperCase()) {
      case 'VLOG':
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFF78350F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case 'TRAVEL':
        return const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0369A1), Color(0xFF0C4A6E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case 'BIRTHDAY':
        return const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFBE185D), Color(0xFF831843)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case 'FOOD':
        return const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669), Color(0xFF064E3B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
    }
  }

  IconData _getTemplateIcon() {
    switch (template.tag.toUpperCase()) {
      case 'VLOG':
        return Icons.face_rounded;
      case 'TRAVEL':
        return Icons.flight_takeoff_rounded;
      case 'BIRTHDAY':
        return Icons.cake_rounded;
      case 'FOOD':
        return Icons.restaurant_rounded;
      default:
        return Icons.movie_creation_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 118,
        height: 154,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _getTemplateGradient(),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Center subtle icon
            Center(
              child: Icon(
                _getTemplateIcon(),
                size: 38,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            // Bottom vignette
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Title and button pill
            Positioned(
              left: 10,
              right: 10,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    template.tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'TEMPLATE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          size: 10,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
