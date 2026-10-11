import 'package:flutter/material.dart';

class AppColors {
  // Brand Gradients and Primaries
  static const Color primary = Color(0xFF7C3AED); // Vibrant Purple
  static const Color primaryLight = Color(0xFF8B5CF6);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color secondary = Color(0xFF6366F1); // Indigo
  static const Color accent = Color(0xFF06B6D4); // Cyan

  // Track Colors
  static const Color videoTrackBorder = Color(0xFF38BDF8);
  static const Color textTrack = Color(0xFF8B5CF6);
  static const Color textTrackBorder = Color(0xFFA78BFA);
  static const Color audioTrack = Color(0xFF10B981);
  static const Color audioTrackBorder = Color(0xFF34D399);
  static const Color audioTrackWaveform = Color(0xFF34D399);

  // Dark Theme Editor Canvas Colors
  static const Color editorBg = Color(0xFF0D0F17);
  static const Color editorSurface = Color(0xFF161924);
  static const Color editorSurfaceLight = Color(0xFF22283A);
  static const Color editorBorder = Color(0xFF2E364A);
  static const Color playhead = Colors.white;

  // Home Screen Light/Adaptive Palette
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Quick Action Pastel Backgrounds
  static const Color autoEditBg = Color(0xFFFFECE8);
  static const Color autoEditIcon = Color(0xFFF43F5E);

  static const Color aiToolsBg = Color(0xFFF3E8FF);
  static const Color aiToolsIcon = Color(0xFF8B5CF6);

  static const Color templatesBg = Color(0xFFE0F2FE);
  static const Color templatesIcon = Color(0xFF0284C7);

  static const Color moreBg = Color(0xFFFEF3C7);
  static const Color moreIcon = Color(0xFFD97706);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9), Color(0xFF4F46E5)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
