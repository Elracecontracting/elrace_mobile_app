part of 'attendance_bloc.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class GetAttendanceListET extends AttendanceEvent {
  final String? keyword;
  final int? month;

  const GetAttendanceListET({
    this.keyword,
    this.month,
  });
  
  @override
  List<Object?> get props => [keyword, month];
}
