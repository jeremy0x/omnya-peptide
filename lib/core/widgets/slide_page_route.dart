import 'package:flutter/material.dart';

/// Smooth sliding page route for all non-root transitions.
/// Enforces seamless horizontal slide on entry and exit with cubic deceleration.
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlidePageRoute({required this.page, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Deceleration curve for natural organic deceleration
            const curve = Curves.easeOutCubic;
            const reverseCurve = Curves.easeInCubic;

            // Slide in from right (1.0, 0.0) -> (0.0, 0.0)
            final inTween = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: curve));

            // Parallax slide out to left (0.0, 0.0) -> (-0.25, 0.0) when another page is pushed on top
            final secondaryOutTween = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.25, 0.0),
            ).chain(CurveTween(curve: reverseCurve));

            return SlideTransition(
              position: animation.drive(inTween),
              child: SlideTransition(
                position: secondaryAnimation.drive(secondaryOutTween),
                child: child,
              ),
            );
          },
        );
}
