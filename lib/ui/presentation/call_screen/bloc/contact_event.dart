part of 'contact_bloc.dart';

sealed class ContactEvent extends Equatable {
  const ContactEvent();
  @override
  List<Object> get props => [];
}

final class GetEmployeeLisET extends ContactEvent {}
