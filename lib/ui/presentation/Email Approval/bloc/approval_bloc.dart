import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'approval_event.dart';
import 'approval_state.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApprovalBloc extends Bloc<ApprovalEvent, ApprovalState> {
  ApprovalBloc() : super(const ApprovalInitial()) {
    on<ApproveRequest>(_onApproveRequest);
    on<RejectRequest>(_onRejectRequest);
    on<ToggleItemExpansion>(_onToggleItemExpansion);
    on<CollapseItem>(_onCollapseItem);
  }

  Future<http.Response> _sendApprovalRequest({
    required String userId,
    required String requestId,
    required String action,
    required String? comment,
    required String type,
  }) async {
    final token = SharedPref.getLoginData().result?.token;

    // Determine the correct API endpoint based on type
    String apiUrl;
    Map<String, dynamic> params;

    if (type.toUpperCase() == 'HR') {
      // HR requests use the existing endpoint
      apiUrl = 'https://erp.elrace.com/api/approve_reject_hr_request';
      params = {
        "user_id": userId,
        "emp_request_id": int.tryParse(requestId),
        "action": action,
        "comment": comment,
      };
    } else {
      // RFQ, Invoice, Petty Cash, LPO use tier review endpoint
      apiUrl = 'https://erp.elrace.com/api/record/tier_review';

      // Map type to model_name
      String modelName;
      switch (type.toUpperCase()) {
        case 'PETTYCASH':
        case 'PETTY_CASH':
          modelName = 'hr.expense.sheet';
          break;
        case 'RFQ':
          modelName = 'purchase.order';
          break;
        case 'INVOICE':
          modelName = 'account.move';
          break;
        default:
          modelName = type.toLowerCase();
      }

      params = {
        "model_name": modelName,
        "record_id": int.tryParse(requestId),
        "action": action,
        "user_id": userId,
        "comment": comment ?? "",
      };
    }

    final url = Uri.parse(apiUrl);
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };
    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": params,
    });
    debugPrint('Approval API: $apiUrl\nType: $type\nData: \n$body');
    return await http.post(url, headers: headers, body: body);
  }

  Future<void> _onApproveRequest(
      ApproveRequest event, Emitter<ApprovalState> emit) async {
    final currentExpandedItems = state.expandedItems;
    emit(ApprovalLoading(expandedItems: currentExpandedItems));
    try {
      final List<String> userIds = event.userIds;
      List<String> successMessages = [];
      List<String> failureMessages = [];

      for (final userId in userIds) {
        try {
          final response = await _sendApprovalRequest(
            userId: userId,
            requestId: event.requestId,
            action: "accept",
            comment: event.comment ?? "Request approved.",
            type: event.type,
          );

          // Check HTTP status code first
          if (response.statusCode != 200) {
            debugPrint(
                '❌ HTTP Error: ${response.statusCode}\n${response.body}');
            failureMessages
                .add("User $userId: Server error (${response.statusCode})");
            continue; // Continue to next user instead of returning
          }

          // Try to parse JSON, catch FormatException if HTML is returned
          dynamic data;
          try {
            data = jsonDecode(response.body);
          } on FormatException {
            debugPrint(
                '❌ FormatException: Server returned HTML instead of JSON\n${response.body.substring(0, 200)}...');
            failureMessages.add("User $userId: Invalid server response");
            continue; // Continue to next user
          }

          debugPrint('_onApproveRequest:  \n${response.body}');
          if (data["result"] != null && data["result"]["message"] != null) {
            successMessages.add(data["result"]["message"]);
          } else {
            failureMessages.add("User $userId: Unknown response from server");
          }
        } catch (e) {
          debugPrint('❌ Error for user $userId: $e');
          failureMessages.add("User $userId: ${e.toString()}");
        }
      }

      // Determine final state based on results
      if (successMessages.isNotEmpty && failureMessages.isEmpty) {
        // All succeeded
        emit(ApprovalSuccess(successMessages.join("\n"),
            expandedItems: currentExpandedItems));
      } else if (successMessages.isEmpty && failureMessages.isNotEmpty) {
        // All failed
        emit(ApprovalFailure(failureMessages.join("\n"),
            expandedItems: currentExpandedItems));
      } else if (successMessages.isNotEmpty && failureMessages.isNotEmpty) {
        // Partial success - treat as success but show warning
        final message =
            "Partial Success:\n${successMessages.join("\n")}\n\nWarnings:\n${failureMessages.join("\n")}";
        emit(ApprovalSuccess(message, expandedItems: currentExpandedItems));
      } else {
        // No users processed (shouldn't happen)
        emit(ApprovalFailure("No users to process.",
            expandedItems: currentExpandedItems));
      }
    } catch (e) {
      debugPrint('❌ Approval Error: $e');
      // Provide user-friendly error message
      String errorMessage;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        errorMessage = "Network error. Please check your internet connection.";
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = "Request timeout. Please try again.";
      } else {
        errorMessage = "An error occurred: ${e.toString()}";
      }
      emit(ApprovalFailure(errorMessage, expandedItems: currentExpandedItems));
    }
  }

  Future<void> _onRejectRequest(
      RejectRequest event, Emitter<ApprovalState> emit) async {
    final currentExpandedItems = state.expandedItems;
    emit(ApprovalLoading(expandedItems: currentExpandedItems));
    try {
      final List<String> userIds = event.userIds;
      List<String> successMessages = [];
      List<String> failureMessages = [];

      for (final userId in userIds) {
        try {
          final response = await _sendApprovalRequest(
            userId: userId,
            requestId: event.requestId,
            action: "reject",
            comment: event.comment ?? "Request rejected.",
            type: event.type,
          );

          // Check HTTP status code first
          if (response.statusCode != 200) {
            debugPrint(
                '❌ HTTP Error: ${response.statusCode}\n${response.body}');
            failureMessages
                .add("User $userId: Server error (${response.statusCode})");
            continue; // Continue to next user instead of returning
          }

          // Try to parse JSON, catch FormatException if HTML is returned
          dynamic data;
          try {
            data = jsonDecode(response.body);
          } on FormatException {
            debugPrint(
                '❌ FormatException: Server returned HTML instead of JSON\n${response.body.substring(0, 200)}...');
            failureMessages.add("User $userId: Invalid server response");
            continue; // Continue to next user
          }

          debugPrint('_onRejectRequest: ${response.body}');
          if (data["result"] != null && data["result"]["message"] != null) {
            successMessages.add(data["result"]["message"]);
          } else {
            failureMessages.add("User $userId: Unknown response from server");
          }
        } catch (e) {
          debugPrint('❌ Error for user $userId: $e');
          failureMessages.add("User $userId: ${e.toString()}");
        }
      }

      // Determine final state based on results
      if (successMessages.isNotEmpty && failureMessages.isEmpty) {
        // All succeeded
        emit(ApprovalSuccess(successMessages.join("\n"),
            expandedItems: currentExpandedItems));
      } else if (successMessages.isEmpty && failureMessages.isNotEmpty) {
        // All failed
        emit(ApprovalFailure(failureMessages.join("\n"),
            expandedItems: currentExpandedItems));
      } else if (successMessages.isNotEmpty && failureMessages.isNotEmpty) {
        // Partial success - treat as success but show warning
        final message =
            "Partial Success:\n${successMessages.join("\n")}\n\nWarnings:\n${failureMessages.join("\n")}";
        emit(ApprovalSuccess(message, expandedItems: currentExpandedItems));
      } else {
        // No users processed (shouldn't happen)
        emit(ApprovalFailure("No users to process.",
            expandedItems: currentExpandedItems));
      }
    } catch (e) {
      debugPrint('❌ Rejection Error: $e');
      // Provide user-friendly error message
      String errorMessage;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        errorMessage = "Network error. Please check your internet connection.";
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = "Request timeout. Please try again.";
      } else {
        errorMessage = "An error occurred: ${e.toString()}";
      }
      emit(ApprovalFailure(errorMessage, expandedItems: currentExpandedItems));
    }
  }

  void _onToggleItemExpansion(
      ToggleItemExpansion event, Emitter<ApprovalState> emit) {
    final currentExpandedItems = Set<int>.from(state.expandedItems);

    if (currentExpandedItems.contains(event.index)) {
      currentExpandedItems.remove(event.index);
    } else {
      currentExpandedItems.add(event.index);
      // Auto-collapse after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        add(CollapseItem(event.index));
      });
    }

    emit(ApprovalItemsExpanded(expandedItems: currentExpandedItems));
  }

  void _onCollapseItem(CollapseItem event, Emitter<ApprovalState> emit) {
    final currentExpandedItems = Set<int>.from(state.expandedItems);
    currentExpandedItems.remove(event.index);
    emit(ApprovalItemsExpanded(expandedItems: currentExpandedItems));
  }
}
