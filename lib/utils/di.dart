import 'package:el_race/ui/presentation/Email%20Approval/bloc/approval_bloc.dart';
import 'package:el_race/ui/presentation/home_screen/bloc/home_bloc.dart';
import 'package:el_race/ui/presentation/landing_screen/bloc/checkin_in_bloc/check_in_bloc.dart';
import 'package:el_race/ui/presentation/landing_screen/bloc/checkin_out_bloc/check_out_bloc.dart';
import 'package:el_race/ui/presentation/my_request/bloc/requests_bloc.dart';
import 'package:el_race/ui/presentation/signin/bloc/sign_in_bloc.dart';
import 'package:el_race/ui/presentation/signin/data/model.dart';
import 'package:el_race/ui/presentation/signin/data/repository.dart';
import 'package:get_it/get_it.dart';
import 'package:el_race/ui/presentation/Attendace_list/bloc/attendance_bloc.dart';
import 'package:el_race/ui/presentation/Attendace_list/repository/attendance_repository.dart';

import '../ui/presentation/call_screen/bloc/contact_bloc.dart';
import '../ui/presentation/call_screen/data/repository.dart';

final sl = GetIt.instance;

Future<void> initDI() async {
  // Register Repositories
  sl.registerSingleton<UserRepo>(UserRepo());
  sl.registerSingleton<ContactRepo>(ContactRepo());
  sl.registerSingleton<AttendanceRepo>(AttendanceRepo());
  sl.registerSingleton<LoginResponseModel>(LoginResponseModel());


  // Register Blocs
  sl.registerSingleton<SignInBloc>(SignInBloc());
  sl.registerSingleton<ContactBloc>(ContactBloc());
  sl.registerSingleton<CheckInBloc>(CheckInBloc());
  sl.registerSingleton<CheckOutBloc>(CheckOutBloc());
  sl.registerSingleton<AttendanceBloc>(AttendanceBloc());
  sl.registerSingleton<HomeBloc>(HomeBloc());
  sl.registerSingleton<RequestsBloc>(RequestsBloc());
  sl.registerSingleton<ApprovalBloc>(ApprovalBloc());
  
}
