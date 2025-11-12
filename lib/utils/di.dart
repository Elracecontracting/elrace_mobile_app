import 'package:el_race/ui/presentation/Email%20Approval/bloc/approval_bloc.dart';
import 'package:el_race/ui/presentation/home_screen/bloc/home_bloc.dart';
import 'package:el_race/ui/presentation/landing_screen/bloc/checkin_in_bloc/check_in_bloc.dart';
import 'package:el_race/ui/presentation/landing_screen/bloc/checkin_out_bloc/check_out_bloc.dart';
import 'package:el_race/ui/presentation/my_notes/bloc/notes_bloc.dart';
import 'package:el_race/ui/presentation/my_notes/repository/i_notes_repository.dart';
import 'package:el_race/ui/presentation/my_notes/repository/notes_repository.dart';
import 'package:el_race/ui/presentation/media/bloc/media_bloc.dart';
import 'package:el_race/ui/presentation/media/repository/i_media_repository.dart';
import 'package:el_race/ui/presentation/media/repository/media_repository.dart';
import 'package:el_race/ui/presentation/my_projects/data/datasources/project_remote_datasource.dart';
import 'package:el_race/ui/presentation/my_projects/data/repositories/project_repository_impl.dart';
import 'package:el_race/ui/presentation/my_projects/domain/repositories/project_repository.dart';
import 'package:el_race/ui/presentation/my_projects/domain/usecases/get_projects_usecase.dart';
import 'package:el_race/ui/presentation/my_projects/presentation/bloc/project_list_bloc.dart';
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
  try {
    // Register Repositories
    sl.registerSingleton<UserRepo>(UserRepo());
    sl.registerSingleton<ContactRepo>(ContactRepo());
    sl.registerSingleton<AttendanceRepo>(AttendanceRepo());
    sl.registerSingleton<LoginResponseModel>(LoginResponseModel());

    // Temporarily comment out problematic dependencies for iOS simulator
    // sl.registerLazySingleton<ProjectRepository>(() => ProjectRepositoryImpl(sl()));
    sl.registerLazySingleton<INotesRepository>(() => NotesRepository());
    sl.registerLazySingleton<IMediaRepository>(() => MediaRepository());

    // Data sources
    // sl.registerLazySingleton<ProjectRemoteDataSource>(() => ProjectRemoteDataSource());

    // Register Blocs
    sl.registerSingleton<SignInBloc>(SignInBloc());
    sl.registerSingleton<ContactBloc>(ContactBloc());
    sl.registerSingleton<CheckInBloc>(CheckInBloc());
    sl.registerSingleton<CheckOutBloc>(CheckOutBloc());
    sl.registerSingleton<AttendanceBloc>(AttendanceBloc());
    sl.registerSingleton<HomeBloc>(HomeBloc());
    sl.registerSingleton<RequestsBloc>(RequestsBloc());
    sl.registerSingleton<ApprovalBloc>(ApprovalBloc());
    sl.registerSingleton<NotesBloc>(NotesBloc(notesRepository: sl()));
    sl.registerSingleton<MediaBloc>(MediaBloc(mediaRepository: sl()));

    // Temporarily comment out problematic bloc for iOS simulator
    // sl.registerFactory(() => ProjectListBloc(
    //   getProjectsUseCase: sl(),
    //   getProjectAttachmentsUseCase: sl()
    // ));

    /// register usecases
    // sl.registerLazySingleton(() => GetProjectsUseCase(repository: sl()));
    // sl.registerLazySingleton(() => GetProjectAttachmentsUseCase(repository: sl()));
  } catch (e) {
    print('Error in DI setup: $e');
    // Continue with basic setup
  }
}
