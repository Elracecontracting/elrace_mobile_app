part of 'face_id_bloc.dart';

sealed class FaceIdState extends Equatable {
  const FaceIdState();
  @override
  List<Object> get props => [];
}

final class FaceIdInitial extends FaceIdState {}
