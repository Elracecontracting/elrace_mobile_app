import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:el_race/ui/presentation/Attendace_list/repository/attendance_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  
 static HomeBloc get(BuildContext context) => BlocProvider.of(context);
  HomeBloc() : super(HomeInitial()) {
    on<CheckInET>(checkedInMethod);
    on<FetchLastMonthAttendanceSummary>(_fetchLastMonthAttendanceSummary);
  }

  FutureOr<void> checkedInMethod(CheckInET event, Emitter<HomeState> emit) {
    emit(CheckedInST());
  }

  int attendedDays = 0;

  Future<void> _fetchLastMonthAttendanceSummary(
    FetchLastMonthAttendanceSummary event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(const LastMonthAttendanceSummaryLoading());
      final now = DateTime.now();
      final firstDayOfLastMonth = DateTime(now.year, now.month , 1);
      final lastDayOfLastMonth = DateTime(now.year, now.month+1, 0);

      final summary = await AttendanceRepo().getAttendanceSummary(
        startDate: DateFormat('yyyy-MM-dd').format(firstDayOfLastMonth),
        endDate: DateFormat('yyyy-MM-dd').format(lastDayOfLastMonth),
      );
      attendedDays = summary['working_days'] ?? 0;
      emit(const LastMonthAttendanceSummaryLoaded());
      // No emit here, just set the variable
    } catch (e) {
      emit(LastMonthAttendanceSummaryError(e.toString()));
    }
  }

  int get getAttendedDays => attendedDays;
  
}
