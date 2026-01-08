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

  const ApprovalActionButtons({
    super.key,
    required this.requestId,
    required this.type,
    this.onResult,
    this.disabled = false,
    this.selectedAction,
    required this.userIds,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController commentController = TextEditingController();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCircleActionButton(context, "REJECT", const Color(0xFFBA1719),
            Icons.close, commentController,
            isSelected: selectedAction == 'reject'),
        SizedBox(width: 40.w),
        _buildCircleActionButton(context, "APPROVE", const Color(0xFF00D17A),
            Icons.check, commentController,
            isSelected: selectedAction == 'approve'),
      ],
    );
  }

  Widget _buildCircleActionButton(BuildContext context, String label,
      Color color, IconData icon, TextEditingController commentController,
      {bool isSelected = false}) {
    return BlocConsumer<ApprovalBloc, ApprovalState>(
      listener: (ctx, state) {
        if (state is ApprovalSuccess) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          if (onResult != null) {
            onResult!(state.message);
          }
          // Close the screen after successful approval/rejection
          Future.delayed(const Duration(milliseconds: 500), () {
            if (Navigator.of(ctx).canPop()) {
              Navigator.of(ctx).pop(true); // Return true to indicate success
            }
          });
        } else if (state is ApprovalFailure) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.error)),
          );
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
                  String? comment = await _showCommentDialog(context, label);
                  comment ??= '..';
                  if (label == "APPROVE") {
                    context.read<ApprovalBloc>().add(
                          ApproveRequest(
                            requestId: requestId,
                            type: type,
                            token: token,
                            userIds: userIds,
                            comment: comment,
                          ),
                        );
                  } else if (label == "REJECT") {
                    context.read<ApprovalBloc>().add(
                          RejectRequest(
                            requestId: requestId,
                            type: type,
                            token: token,
                            userIds: userIds,
                            comment: comment,
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
      builder: (ctx) {
        return AlertDialog(
          title: Text('$action Comment'),
          content: TextField(
            controller: controller,
            decoration:
                const InputDecoration(hintText: 'Enter your comment...'),
            minLines: 1,
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(
                  controller.text.trim().isEmpty
                      ? null
                      : controller.text.trim()),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // how long to hold
    );

    // when animation completes → trigger action
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.onPressed != null && !widget.isDisabled) {
          widget.onPressed!();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isDisabled && widget.onPressed != null) {
      _controller.forward(from: 0); // restart animation
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_controller.status != AnimationStatus.completed) {
      _controller.reverse(); // released early → cancel
    }
  }

  void _onTapCancel() {
    _controller.reverse();
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
