import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:el_race/ui/presentation/landing_screen/bloc/checkin_in_bloc/check_in_bloc.dart';
import 'package:el_race/ui/presentation/landing_screen/repository/face_id_repo.dart';
import 'package:equatable/equatable.dart';

part 'face_id_event.dart';
part 'face_id_state.dart';

FaceIDRepo _faceIDRepo = FaceIDRepo();

final _checkInBloc = CheckInBloc();

class FaceIdBloc extends Bloc<FaceIdEvent, FaceIdState> {
  FaceIdBloc() : super(FaceIdInitial()) {
    on<FaceIdEvent>((event, emit) {
    });
    on<GetAllBioMetricET>(getAllBioMetricMethod);
  }

  FutureOr<void> getAllBioMetricMethod(
      GetAllBioMetricET event, Emitter<FaceIdState> emit) async {
    var authenticated = await _faceIDRepo.authenticateWithBiometrics();

    log('authenticated $authenticated');

    if (authenticated == true) {
      _checkInBloc.add(CheckInET());
    }
  }
}
