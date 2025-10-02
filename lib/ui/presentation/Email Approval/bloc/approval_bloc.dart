import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'approval_event.dart';
import 'approval_state.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApprovalBloc extends Bloc<ApprovalEvent, ApprovalState> {
  ApprovalBloc() : super(ApprovalInitial()) {
    on<ApproveRequest>(_onApproveRequest);
    on<RejectRequest>(_onRejectRequest);
  }

  Future<http.Response> _sendApprovalRequest({
    required String userId,
    required String requestId,
    required String action,
    required String? comment,
  }) async {
    final url = Uri.parse('https://test.elrace.com/api/approve_reject_hr_request');
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    final body = jsonEncode({
      "jsonrpc": "2.0",
      "params": {
        "user_id": userId,
        "emp_request_id": int.tryParse(requestId),
        "action": action,
        "comment": comment,
      },
    });
    debugPrint('data: \n$body');
    return await http.post(url, headers: headers, body: body);
  }

  Future<void> _onApproveRequest(ApproveRequest event, Emitter<ApprovalState> emit) async {
    emit(ApprovalLoading());
    try {
      final List<String> userIds = event.userIds;
      List<String> messages = [];
      for (final userId in userIds) {
        final response = await _sendApprovalRequest(
          userId: userId,
          requestId: event.requestId,
          action: "accept",
          comment: event.comment ?? "Request approved.",
        );
        final data = jsonDecode(response.body);
        debugPrint('_onApproveRequest:  \n${response.body}');
        if (data["result"] != null && data["result"]["message"] != null) {
          messages.add(data["result"]["message"]);
        } else {
          emit(const ApprovalFailure("Unknown response from server."));
          return;
        }
      }
      emit(ApprovalSuccess(messages.join("\n")));
    } catch (e) {
      emit(ApprovalFailure(e.toString()));
    }
  }

  Future<void> _onRejectRequest(RejectRequest event, Emitter<ApprovalState> emit) async {
    emit(ApprovalLoading());
    try {
      final List<String> userIds = event.userIds;
      List<String> messages = [];
      for (final userId in userIds) {
        final response = await _sendApprovalRequest(
          userId: userId,
          requestId: event.requestId,
          action: "reject",
          comment: event.comment ?? "Request rejected.",
        );
        final data = jsonDecode(response.body);
        debugPrint('_onRejectRequest: ${response.body}');
        if (data["result"] != null && data["result"]["message"] != null) {
          messages.add(data["result"]["message"]);
        } else {
          emit(const ApprovalFailure("Unknown response from server."));
          return;
        }
      }
      emit(ApprovalSuccess(messages.join("\n")));
    } catch (e) {
      emit(ApprovalFailure(e.toString()));
    }
  }
} 