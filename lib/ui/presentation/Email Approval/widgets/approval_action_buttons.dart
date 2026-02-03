import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../bloc/approval_bloc.dart';
import '../bloc/approval_event.dart';
import '../bloc/approval_state.dart';
import 'package:el_race/core/utils/shared_pref.dart';

class ApprovalActionButtons extends StatelessWidget {
  final String requestId;
  final String type;
  final void Function(String result)? onResult;
  final bool disabled;
  final String? selectedAction;
  final List<String> userIds;
  final ApprovalActionButtonsVariant variant;
  final double? pillWidth;

  const ApprovalActionButtons({
    super.key,
    required this.requestId,
    required this.type,
    this.onResult,
    this.disabled = false,
    this.selectedAction,
    required this.userIds,
    this.variant = ApprovalActionButtonsVariant.holdCircle,
    this.pillWidth,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController commentController = TextEditingController();
    if (variant == ApprovalActionButtonsVariant.rectangle) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _buildRectangleActionButton(
              context,
              label: 'REJECT',
              color: const Color(0xFFBA1719),
              commentController: commentController,
              isSelected: selectedAction == 'reject',
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildRectangleActionButton(
              context,
              label: 'APPROVE',
              color: const Color(0xFF009859),
              commentController: commentController,
              isSelected: selectedAction == 'approve',
            ),
          ),
        ],
      );
    }
    if (variant == ApprovalActionButtonsVariant.pill) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPillActionButton(
            context,
            label: 'REJECT',
            color: const Color(0xFFBA1719),
            commentController: commentController,
            isSelected: selectedAction == 'reject',
          ),
          SizedBox(width: 16.w),
          _buildPillActionButton(
            context,
            label: 'APPROVE',
            color: const Color(0xFF009859),
            commentController: commentController,
            isSelected: selectedAction == 'approve',
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCircleActionButton(context, "REJECT", const Color(0xFFBA1719),
            Icons.close, commentController,
            isSelected: selectedAction == 'reject'),
        SizedBox(width: 40.w),
        _buildCircleActionButton(context, "APPROVE", const Color(0xFF009859),
            Icons.check, commentController,
            isSelected: selectedAction == 'approve'),
      ],
    );
  }

  Widget _buildRectangleActionButton(
    BuildContext context, {
    required String label,
    required Color color,
    required TextEditingController commentController,
    bool isSelected = false,
  }) {
    return BlocConsumer<ApprovalBloc, ApprovalState>(
      listenWhen: (previous, current) {
        if (current is ApprovalSuccess && previous is! ApprovalSuccess) {
          return true;
        }
        if (current is ApprovalFailure && previous is! ApprovalFailure) {
          return true;
        }
        return false;
      },
      listener: (ctx, state) {
        if (state is ApprovalSuccess) {
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          if (onResult != null) {
            onResult!(state.message);
          }

          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context, true);
            Future.delayed(const Duration(milliseconds: 100), () {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            });
          }
        } else if (state is ApprovalFailure) {
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                duration: const Duration(seconds: 4),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is ApprovalLoading;
        final isButtonDisabled = disabled || isLoading;

        return SizedBox(
          width: double.infinity,
          height: 52.w,
          child: ElevatedButton(
            onPressed: isButtonDisabled
                ? null
                : () async {
                    final token =
                        SharedPref.getLoginData().result?.token ?? '';
                    final String? comment =
                        await _showCommentDialog(context, label);

                    if (!context.mounted) return;
                    final finalComment = comment ?? '..';

                    if (context.mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        barrierColor: Colors.black54,
                        builder: (BuildContext dialogContext) {
                          return PopScope(
                            canPop: false,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text(
                                      'Processing...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }

                    if (label == 'APPROVE') {
                      context.read<ApprovalBloc>().add(
                            ApproveRequest(
                              requestId: requestId,
                              type: type,
                              token: token,
                              userIds: userIds,
                              comment: finalComment,
                            ),
                          );
                    } else {
                      context.read<ApprovalBloc>().add(
                            RejectRequest(
                              requestId: requestId,
                              type: type,
                              token: token,
                              userIds: userIds,
                              comment: finalComment,
                            ),
                          );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              disabledBackgroundColor: color.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              elevation: isSelected ? 6 : 2,
            ),
            child: Text(
              label,
              style: GoogleFonts.koulen(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPillActionButton(
    BuildContext context, {
    required String label,
    required Color color,
    required TextEditingController commentController,
    bool isSelected = false,
  }) {
    return BlocConsumer<ApprovalBloc, ApprovalState>(
      listenWhen: (previous, current) {
        if (current is ApprovalSuccess && previous is! ApprovalSuccess) {
          return true;
        }
        if (current is ApprovalFailure && previous is! ApprovalFailure) {
          return true;
        }
        return false;
      },
      listener: (ctx, state) {
        if (state is ApprovalSuccess) {
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          if (onResult != null) {
            onResult!(state.message);
          }

          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context, true);
            Future.delayed(const Duration(milliseconds: 100), () {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            });
          }
        } else if (state is ApprovalFailure) {
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                duration: const Duration(seconds: 4),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is ApprovalLoading;
        final isButtonDisabled = disabled || isLoading;

        return SizedBox(
          width: pillWidth ?? 150.w,
          height: 52.w,
          child: ElevatedButton(
            onPressed: isButtonDisabled
                ? null
                : () async {
                    final token =
                        SharedPref.getLoginData().result?.token ?? '';
                    final String? comment =
                        await _showCommentDialog(context, label);

                    if (!context.mounted) return;
                    final finalComment = comment ?? '..';

                    if (context.mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        barrierColor: Colors.black54,
                        builder: (BuildContext dialogContext) {
                          return PopScope(
                            canPop: false,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text(
                                      'Processing...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }

                    if (label == 'APPROVE') {
                      context.read<ApprovalBloc>().add(
                            ApproveRequest(
                              requestId: requestId,
                              type: type,
                              token: token,
                              userIds: userIds,
                              comment: finalComment,
                            ),
                          );
                    } else {
                      context.read<ApprovalBloc>().add(
                            RejectRequest(
                              requestId: requestId,
                              type: type,
                              token: token,
                              userIds: userIds,
                              comment: finalComment,
                            ),
                          );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              disabledBackgroundColor: color.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: isSelected ? 6 : 2,
            ),
            child: Text(
              label,
              style: GoogleFonts.koulen(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircleActionButton(BuildContext context, String label,
      Color color, IconData icon, TextEditingController commentController,
      {bool isSelected = false}) {
    return BlocConsumer<ApprovalBloc, ApprovalState>(
      // Only listen when the state actually changes to prevent duplicate calls
      listenWhen: (previous, current) {
        // Only trigger listener when transitioning to a new success/failure state
        if (current is ApprovalSuccess && previous is! ApprovalSuccess) {
          return true;
        }
        if (current is ApprovalFailure && previous is! ApprovalFailure) {
          return true;
        }
        return false;
      },
      listener: (ctx, state) {
        if (state is ApprovalSuccess) {
          // Close loading overlay first
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context); // Close loading overlay
          }

          // Call the onResult callback if provided
          if (onResult != null) {
            onResult!(state.message);
          }

          // Close main dialog - parent screen will handle refresh and count update
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context, true);

            // Show success message after dialog closes
            Future.delayed(const Duration(milliseconds: 100), () {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            });
          }
        } else if (state is ApprovalFailure) {
          // Close loading overlay first
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context); // Close loading overlay
          }

          // For failures, show error but don't close main dialog
          // User needs to see the error and decide what to do
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                duration: const Duration(seconds: 4),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is ApprovalLoading;
        final isButtonDisabled = disabled || isLoading;

        return AnimatedCircleButton(
          onPressed: isButtonDisabled
              ? null
              : () async {
                  final token = SharedPref.getLoginData().result?.token ?? '';
                  final String? comment =
                      await _showCommentDialog(context, label);

                  // If user cancelled the dialog or context is no longer valid, don't proceed
                  if (!context.mounted) return;

                  // Use comment if provided, otherwise use default
                  final finalComment = comment ?? '..';

                  // Show loading immediately after comment is submitted
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      barrierColor: Colors.black54,
                      builder: (BuildContext dialogContext) {
                        return PopScope(
                          canPop: false,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text(
                                    'Processing...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  if (label == "APPROVE") {
                    context.read<ApprovalBloc>().add(
                          ApproveRequest(
                            requestId: requestId,
                            type: type,
                            token: token,
                            userIds: userIds,
                            comment: finalComment,
                          ),
                        );
                  } else if (label == "REJECT") {
                    context.read<ApprovalBloc>().add(
                          RejectRequest(
                            requestId: requestId,
                            type: type,
                            token: token,
                            userIds: userIds,
                            comment: finalComment,
                          ),
                        );
                  }
                },
          color: color,
          icon: icon,
          label: label,
          isLoading: isLoading,
          isDisabled: isButtonDisabled,
        );
      },
    );
  }

  Future<String?> _showCommentDialog(
      BuildContext context, String action) async {
    final TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible:
          false, // Prevent accidental dismissal by tapping outside
      builder: (ctx) {
        return AlertDialog(
          title: Text('$action Comment'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter your comment...',
              border: OutlineInputBorder(),
            ),
            minLines: 1,
            maxLines: 3,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(), // Return null on cancel
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                Navigator.of(ctx).pop(text.isEmpty ? '..' : text);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      // Dispose controller after a frame to ensure Flutter is done with it
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    });
  }
}

enum ApprovalActionButtonsVariant {
  holdCircle,
  pill,
  rectangle,
}

class AnimatedCircleButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Color color;
  final IconData icon;
  final String label;
  final bool isLoading;
  final bool isDisabled;

  const AnimatedCircleButton({
    super.key,
    required this.onPressed,
    required this.color,
    required this.icon,
    required this.label,
    required this.isLoading,
    required this.isDisabled,
  });

  @override
  State<AnimatedCircleButton> createState() => _AnimatedCircleButtonState();
}

class _AnimatedCircleButtonState extends State<AnimatedCircleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hasTriggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // how long to hold
    );

    // when animation completes → trigger action
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hasTriggered) {
        if (widget.onPressed != null && !widget.isDisabled) {
          _hasTriggered = true;
          widget.onPressed!();
        }
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedCircleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset trigger flag when widget becomes enabled (e.g., after loading completes)
    if (oldWidget.isDisabled && !widget.isDisabled) {
      _hasTriggered = false;
    }
    // If widget becomes disabled while animation is running, stop it
    if (!oldWidget.isDisabled && widget.isDisabled) {
      if (_controller.isAnimating) {
        _controller.reverse();
        _hasTriggered = false;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isDisabled && widget.onPressed != null && !_hasTriggered) {
      _controller.forward(from: 0); // restart animation
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_controller.status != AnimationStatus.completed) {
      _controller.reverse(); // released early → cancel
      _hasTriggered = false; // Reset flag if cancelled
    }
  }

  void _onTapCancel() {
    _controller.reverse();
    _hasTriggered = false; // Reset flag if cancelled
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color,
                    width: 3.w,
                  ),
                  color:
                      widget.color.withValues(alpha: _controller.value * 0.8),
                ),
                child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const SizedBox.shrink()),
              );
            },
          ),
        ),
        SizedBox(height: 8.w),
        Text(
          "HOLD TO ${widget.label}",
          style: GoogleFonts.koulen(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
            color: widget.isDisabled
                ? widget.color.withValues(alpha: 0.5)
                : widget.color,
          ),
        ),
      ],
    );
  }
}

class CircleFillPainter extends CustomPainter {
  final double fillProgress;
  final Color fillColor;

  CircleFillPainter({
    required this.fillProgress,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillProgress <= 0) return;

    final paint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    final fillHeight = size.height * fillProgress;
    final startY = size.height - fillHeight;

    final rect = Rect.fromLTWH(0, startY, size.width, fillHeight);

    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    canvas.clipPath(path);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is CircleFillPainter &&
        (oldDelegate.fillProgress != fillProgress ||
            oldDelegate.fillColor != fillColor);
  }
}
