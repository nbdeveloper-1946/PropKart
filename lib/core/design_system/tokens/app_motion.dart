import 'package:flutter/animation.dart';

/// Animation duration and curve tokens — Apple-inspired, subtle motion.
class CRMMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 420);

  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounce = Curves.easeOutBack;

  static const SpringDescription spring = SpringDescription(
    mass: 1,
    stiffness: 180,
    damping: 20,
  );

  static const SpringDescription interactiveSpring = SpringDescription(
    mass: 0.8,
    stiffness: 300,
    damping: 22,
  );

  static const Duration pageTransition = Duration(milliseconds: 320);
  static const Duration tabSwitch = Duration(milliseconds: 220);
  static const Duration dialog = Duration(milliseconds: 240);
  static const Duration sheet = Duration(milliseconds: 300);
  static const Duration skeleton = Duration(milliseconds: 1400);
  static const Duration press = Duration(milliseconds: 100);
}
