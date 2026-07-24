import 'package:flutter/material.dart';
import 'app_colors.dart';

class CRMShadows {
  static Color _softBlack(double alpha) =>
      Colors.black.withValues(alpha: alpha);

  static Color _primaryGlow(double alpha) =>
      CRMColors.primary.withValues(alpha: alpha);

  static List<BoxShadow> get soft => small;

  static List<BoxShadow> get small => [
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.35 : 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.15 : 0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.4 : 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.2 : 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get large => [
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.45 : 0.1),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.2 : 0.04),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get floating => [
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.5 : 0.12),
          blurRadius: 40,
          offset: const Offset(0, 16),
        ),
      ];

  static List<BoxShadow> get glass => [
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.3 : 0.05),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get modal => [
        BoxShadow(
          color: _softBlack(CRMColors.isDark ? 0.55 : 0.18),
          blurRadius: 48,
          offset: const Offset(0, 24),
        ),
      ];

  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: _primaryGlow(0.28),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}
