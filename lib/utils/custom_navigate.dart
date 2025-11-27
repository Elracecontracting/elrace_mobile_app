import 'package:flutter/material.dart';

class CustomPageRoute extends PageRouteBuilder {
  final Widget child;

  CustomPageRoute({required this.child})
      : super(
          transitionDuration: const Duration(milliseconds: 650),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // ANIMATION IN (push)
            final slideIn = Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            final scaleIn = Tween<double>(
              begin: 0.90,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ));

            final fadeIn = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ));

            // ANIMATION OUT (pop)
            final fadeOut = Tween<double>(
              begin: 1.0,
              end: 0.0,
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOut,
            ));

            final slideOut = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(0, 0.10), // نزول بسيط للأسفل
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOut,
            ));

            return SlideTransition(
              position: animation.status == AnimationStatus.reverse
                  ? slideOut
                  : slideIn,
              child: ScaleTransition(
                scale: animation.status == AnimationStatus.reverse
                    ? const AlwaysStoppedAnimation(1.0)
                    : scaleIn,
                child: FadeTransition(
                  opacity: animation.status == AnimationStatus.reverse
                      ? fadeOut
                      : fadeIn,
                  child: child,
                ),
              ),
            );
          },
        );
}
