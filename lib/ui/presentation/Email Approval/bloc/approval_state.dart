import 'package:equatable/equatable.dart';

abstract class ApprovalState extends Equatable {
  const ApprovalState();
  @override
  List<Object?> get props => [];
}

class ApprovalInitial extends ApprovalState {}
class ApprovalLoading extends ApprovalState {}
class ApprovalSuccess extends ApprovalState {
  final String message;
  const ApprovalSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
class ApprovalFailure extends ApprovalState {
  final String error;
  const ApprovalFailure(this.error);
  @override
  List<Object?> get props => [error];
} 