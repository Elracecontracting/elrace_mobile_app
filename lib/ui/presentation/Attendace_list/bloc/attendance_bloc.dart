import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';

import 'package:el_race/ui/presentation/Attendace_list/repository/attendance_repository.dart';
import 'package:el_race/ui/presentation/Attendace_list/model/attendance_model.dart';
import '../../../../../../utils/di.dart';

part 'attendance_event.dart';
part 'attendance_state.dart';

final _attendanceRepo = sl.get<AttendanceRepo>();

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  AttendanceBloc() : super(AttendanceInitial()) {
    on<GetAttendanceListET>(_getAttendanceMethod);
  }

  Future<void> _getAttendanceMethod(
      GetAttendanceListET event, Emitter<AttendanceState> emit) async {
    emit(const AttendanceLoadingState(isLoading: true));

    try {
      http.Response response = await _attendanceRepo.getAttendanceList(
        startDate: event.startDate,
        endDate: event.endDate,
      );


      if (response.statusCode == 200) {
        final attendanceModel = attendanceModelFromJson(response.body);
        if (attendanceModel.result.data.isNotEmpty) {
          emit(const AttendanceLoadingState(isLoading: false));
          emit(AttendanceListLoaded(attendanceList: attendanceModel.result.data));
        } else {
          emit(const AttendanceLoadingState(isLoading: false));
          emit(const AttendanceErrorState(message: "No attendance records found."));
        }
      } else {
        emit(const AttendanceLoadingState(isLoading: false));
        emit(AttendanceErrorState(
          message: "Failed to fetch data. HTTP Code: ${response.statusCode}",
        ));
      }
    } catch (e) {
      emit(const AttendanceLoadingState(isLoading: false));
      emit(AttendanceErrorState(message: "Error: $e"));
    }
  }

}
