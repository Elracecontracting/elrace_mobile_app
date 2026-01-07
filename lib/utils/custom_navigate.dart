import 'package:flutter/material.dart';

class CustomPageRoute extends PageRouteBuilder {
  final Widget child;

  CustomPageRoute({required this.child})
      : super(
          transitionDuration: const Duration(milliseconds: 650),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // كيرف واحد نستخدمه للحركتين (forward & reverse)
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeOut, // الخروج (pop)
            );

            // دخول: من تحت لفوق – خروج: من موضعه لأسفل شوي (ما رح تلاحظها كثير)
            final slide = Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved);

            // دخول: تكبير بسيط – خروج: يبقى 1 (ما بيتأثر لأننا نثبّته)
            final scaleIn = Tween<double>(
              begin: 0.90,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ));

            // fade: 0→1 في push, و 1→0 في pop بشكل طبيعي
            final fade = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(curved);

            // لما نكون في حالة pop ما بدنا الـ scale يشتغل، نخليه ثابت على 1
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
          },
        );
}

// Animation خاصة للصفحات الجانبية (Notifications, My Notes)
class SlideRightPageRoute extends PageRouteBuilder {
  final Widget child;

  SlideRightPageRoute({required this.child, super.settings})
      : super(
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final isPopping = animation.status == AnimationStatus.reverse;

            if (isPopping) {
              // خروج: نفس animation الـ CustomPageRoute
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
            } else {
              // دخول: من اليمين
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
          },
        );
}
