import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/data/services/hive_service.dart';
import 'package:el_race/ui/presentation/home_screen/bloc/home_bloc.dart';
import 'package:el_race/ui/presentation/home_screen/provider/slider_provider.dart';
import 'package:el_race/ui/presentation/my_request/bloc/requests_bloc.dart';
import 'package:el_race/ui/presentation/signin/bloc/sign_in_bloc.dart';
import 'package:el_race/ui/presentation/signin/sign_in_screen.dart';
import 'package:el_race/ui/presentation/splash_screen/splash_screen.dart';
import 'package:el_race/utils/di.dart';
import 'package:el_race/utils/generated_routes.dart';
import 'package:el_race/utils/orientation_helper.dart';
import 'package:el_race/utils/screen_size_util.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:el_race/providers/profile_box_provider.dart';
import 'firebase_service.dart';
import 'report_module/data/provider/reports_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'ui/presentation/Email Approval/bloc/approval_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    SharedPref().instantiatePreferences(),
    initDI(),
    HiveService.setupHive(),
    Firebase.initializeApp(),
  ]);
  await FirebaseService.initialize();
  // debugPrint = (String? message, {int? wrapWidth}) {};
  // Get saved language from SharedPref
  final delegate = await LocalizationDelegate.create(
    fallbackLocale: 'en',
    supportedLocales: ['en', 'ar'],
    basePath: 'assets/i18n',
  );

  runApp(
    BlocProvider(
      create: (_) => ApprovalBloc(),
      child: LocalizedApp(delegate, const MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationDelegate = LocalizedApp.of(context).delegate;
    SizeConfig().init(context);
    OnGeneratedRoutes onGeneratedRoutes = OnGeneratedRoutes();
    return LocalizationProvider(
      state: LocalizationProvider.of(context).state,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SliderProvider()),
          ChangeNotifierProvider(create: (_) => ProfileBoxProvider()),
          ChangeNotifierProvider(create: (_) => ReportProvider()),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (ctx) => sl<SignInBloc>()),
            BlocProvider(create: (ctx) => sl<HomeBloc>()),
            BlocProvider(create: (ctx) => sl<RequestsBloc>()),
            BlocProvider(create: (ctx) => sl<ApprovalBloc>()),
          ],
          child: ScreenUtilInit(
            designSize: const Size(411.4, 843.4),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                ScreenSizeUtil.context = context;
                return child!;
              },
              navigatorKey: navKey,
              title: 'El Race',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                useMaterial3: true,
                textTheme: TextTheme(
                  displayLarge: GoogleFonts.koulen(fontSize: 28, fontWeight: FontWeight.w400),
                  titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                  bodyMedium: GoogleFonts.inter(fontSize: 14),
                ),
              ),
              localizationsDelegates: [
                localizationDelegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: localizationDelegate.supportedLocales,
              locale:SharedPref().isArabic()? localizationDelegate.supportedLocales.last:localizationDelegate.supportedLocales.first,
              onGenerateRoute: onGeneratedRoutes.generatedRoutes,
              home:  const SplashScreen()
                  // : const SignInScreen(),
            ),
          ),
        ),
      ),
    );
  }
}

GlobalKey<NavigatorState> navKey = GlobalKey();
