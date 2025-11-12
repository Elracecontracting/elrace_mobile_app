part of 'face_id_bloc.dart';

sealed class FaceIdEvent extends Equatable {
  const FaceIdEvent();
  @override
  List<Object> get props => [];
}

final class GetAllBioMetricET extends FaceIdEvent {}
