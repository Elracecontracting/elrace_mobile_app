import 'package:flutter/material.dart';

class CustomPageRoute<T> extends MaterialPageRoute<T> {
  final Widget child;

  CustomPageRoute({required this.child, super.settings})
      : super(builder: (_) => child);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 650);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 500);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final platform = Theme.of(context).platform;
    final isApple =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    // Keep native iOS route transition to preserve interactive swipe-back.
    if (isApple) {
      return super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOut,
    );

    final slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(curved);

    final scaleIn = Tween<double>(
      begin: 0.90,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
    ));

    final fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(curved);

    final isPopping = animation.status == AnimationStatus.reverse;

    return SlideTransition(
      position: slide,
      child: ScaleTransition(
        scale: isPopping ? const AlwaysStoppedAnimation(1.0) : scaleIn,
        child: FadeTransition(
          opacity: fade,
          child: child,
        ),
      ),
    );
  }
}

// Animation خاصة للصفحات الجانبية (Notifications, My Notes)
class SlideRightPageRoute<T> extends MaterialPageRoute<T> {
  final Widget child;

  SlideRightPageRoute({required this.child, super.settings})
      : super(builder: (_) => child);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 500);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final platform = Theme.of(context).platform;
    final isApple =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    // Preserve iOS interactive back gesture.
    if (isApple) {
      return super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }

    final isPopping = animation.status == AnimationStatus.reverse;

    if (isPopping) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );

      final slide = Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(curved);

      final fade = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(curved);

      return SlideTransition(
        position: slide,
        child: FadeTransition(
          opacity: fade,
          child: child,
        ),
      );
    }

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    final slideIn = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(curved);

    final fade = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(curved);

    return SlideTransition(
      position: slideIn,
      child: FadeTransition(
        opacity: fade,
        child: child,
      ),
    );
  }
}
