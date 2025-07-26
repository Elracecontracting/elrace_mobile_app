import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/approval_bloc.dart';
import '../bloc/approval_event.dart';
import '../bloc/approval_state.dart';
import 'package:el_race/core/utils/shared_pref.dart';

class ApprovalActionButtons extends StatelessWidget {
  final String requestId;
  final String type;
  final void Function(String result)? onResult;
  final bool disabled;
  final String? selectedAction; // 'approve' or 'reject'
  final List<String> userIds; // New parameter for user IDs

  const ApprovalActionButtons({
    Key? key,
    required this.requestId,
    required this.type,
    this.onResult,
    this.disabled = false,
    this.selectedAction,
    required this.userIds,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController commentController = TextEditingController();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(context, "REJECT", const Color(0xFFBA1719), Icons.close, commentController, isSelected: selectedAction == 'reject'),
        const SizedBox(width: 20,),
        _buildActionButton(context, "APPROVE", const Color(0xFF00D17A), Icons.check, commentController, isSelected: selectedAction == 'approve'),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, String label, Color color, IconData icon, TextEditingController commentController, {bool isSelected = false}) {
    return BlocConsumer<ApprovalBloc, ApprovalState>(
      listener: (ctx, state) {
        if (state is ApprovalSuccess) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          if (onResult != null) {
            onResult!(state.message);
          }
        } else if (state is ApprovalFailure) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.error)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is ApprovalLoading;
        final isButtonDisabled = disabled || isLoading;
        return ElevatedButton.icon(
          onPressed: isButtonDisabled
              ? null
              : () async {
                  final token = SharedPref.getLoginData().result?.token ?? '';
                  String? comment = await _showCommentDialog(context, label);
                  if (comment == null) comment = '..';
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
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(icon, size: 16, color: Colors.white),
          label: Text(
            label,
            style: GoogleFonts.koulen(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? color.withOpacity(0.7) : color,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        );
      },
    );
  }

  Future<String?> _showCommentDialog(BuildContext context, String action) async {
    final TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('$action Comment'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter your comment...'),
            minLines: 1,
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim().isEmpty ? null : controller.text.trim()),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
} 