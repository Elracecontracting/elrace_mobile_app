import 'package:el_race/core/services/notification_storage_service.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/data/services/hive_service.dart';
import 'package:el_race/data/services/prayer_background_service.dart';
import 'package:el_race/providers/profile_box_provider.dart';
import 'package:el_race/ui/presentation/call_screen/bloc/contact_bloc.dart';
import 'package:el_race/ui/presentation/home_screen/bloc/home_bloc.dart';
import 'package:el_race/ui/presentation/home_screen/widgets/profile_box_with_slide_animation.dart';
import 'package:el_race/ui/presentation/media/bloc/media_bloc.dart';
import 'package:el_race/ui/presentation/my_notes/bloc/notes_bloc.dart';
import 'package:el_race/ui/presentation/my_request/bloc/requests_bloc.dart';
import 'package:el_race/ui/presentation/qr_code/bloc/qr_code_bloc.dart';
import 'package:el_race/ui/presentation/signin/bloc/sign_in_bloc.dart';
import 'package:el_race/ui/presentation/splash_screen/splash_screen.dart';
import 'package:el_race/ui/presentation/todo_list/providers/todo_provider.dart';
import 'package:el_race/utils/di.dart';
import 'package:el_race/utils/generated_routes.dart';
import 'package:el_race/utils/orientation_helper.dart';
import 'package:el_race/utils/screen_size_util.dart';
import 'package:el_race/core/biometric/ios/face_id_helper.dart';
import 'package:el_race/core/biometric/android/android_biometric_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/services/app_config_service.dart';
import 'firebase_service.dart';
import 'report_module/data/provider/reports_provider.dart';
import 'ui/presentation/Email Approval/bloc/approval_bloc.dart';
import 'ui/presentation/home_screen/provider/slider_provider.dart';
import 'package:screen_protector/screen_protector.dart';

// Background message handler - يجب أن يكون خارج main()
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp();
  print('📩 Background message received: ${message.notification?.title}');
  print('📩 Message data: ${message.data}');

  // Save notification to storage
  try {
    final notification = message.notification;
    if (notification != null) {
      // Determine category from message data
      String category = 'notification'; // default
      if (message.data.containsKey('category')) {
        category = message.data['category'].toString();
      } else if (message.data.containsKey('type')) {
        category = message.data['type'].toString();
      }

      await NotificationStorageService.saveNotification(
        title: notification.title ?? 'Notification',
        body: notification.body ?? '',
        imageUrl:
            notification.android?.imageUrl ?? notification.apple?.imageUrl,
        data: message.data,
        category: category,
      );
      print('✅ Background notification saved to storage');
    }
  } catch (e) {
    print('❌ Error saving background notification: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // منع Screenshot و Screen Recording
  await ScreenProtector.protectDataLeakageOn();

  await Future.wait([
    SharedPref().instantiatePreferences(),
    initDI(),
    HiveService.setupHive(),
    Firebase.initializeApp(),
  ]);

  // Load remote app configuration (e.g., Test Mode)
  await AppConfigService.instance.load();

  // Initialize platform-specific biometric authentication
  FaceIdHelper.initialize(); // iOS only
  AndroidBiometricHelper.initialize(); // Android only

  // Register background message handler قبل FirebaseService.initialize()
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseService.initialize();

  // طباعة FCM Token عند بدء التطبيق
  try {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      print('');
      print('═══════════════════════════════════════════════════════════');
      print('🔥 FCM TOKEN :');
      print('═══════════════════════════════════════════════════════════');
      print(fcmToken);
      print('═══════════════════════════════════════════════════════════');
      print('');
      print('📋 انسخ الـ token أعلاه واستخدمه في Firebase Console');
      print(
          '🔔 اذهب إلى: Firebase Console > Cloud Messaging > Send test message');
      print('');
    } else {
      print('❌ FCM Token is null');
    }
  } catch (e) {
    print('❌ Error getting FCM token: $e');
  }

  // تهيئة خدمة الأذان في الخلفية
  await PrayerBackgroundService.initialize();

  // debugPrint = (String? message, {int? wrapWidth}) {};
  // Get saved language from SharedPref
  final delegate = await LocalizationDelegate.create(
    fallbackLocale: 'en',
    supportedLocales: ['en', 'ar'],
    basePath: 'assets/i18n',
  );

  if (SharedPref().isArabic()) {
    await delegate.changeLocale(const Locale('ar'));
  }

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
          ChangeNotifierProvider(create: (_) => TodoProvider()..initialize()),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (ctx) => sl<SignInBloc>()),
            BlocProvider(create: (ctx) => sl<HomeBloc>()),
            BlocProvider(create: (ctx) => sl<RequestsBloc>()),
            BlocProvider(create: (ctx) => sl<ApprovalBloc>()),
            // BlocProvider(create: (ctx) => sl<ProjectListBloc>()), // Temporarily disabled for iOS simulator
            BlocProvider(create: (ctx) => sl<ContactBloc>()),
            BlocProvider(create: (ctx) => sl<NotesBloc>()),
            BlocProvider(create: (ctx) => sl<MediaBloc>()),
            BlocProvider(create: (ctx) => QrCodeBloc()),
          ],
          child: ScreenUtilInit(
            designSize: const Size(411.4, 843.4),
            child: MaterialApp(
                debugShowCheckedModeBanner: false,
                builder: (context, child) {
                  ScreenSizeUtil.context = context;
                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          final profileBoxProvider =
                              Provider.of<ProfileBoxProvider>(context,
                                  listen: false);
                          if (profileBoxProvider.isProfileVisible) {
                            profileBoxProvider.hideProfileBox();

                            /// Close the profile box
                          }
                        },
                        child: child!,
                      ),
                      Theme(
                        data: ThemeData(
                          colorScheme: ColorScheme.fromSeed(
                              seedColor: Colors.deepPurple),
                          useMaterial3: true,
                          textTheme: TextTheme(
                            displayLarge: GoogleFonts.koulen(
                                fontSize: 28, fontWeight: FontWeight.w400),
                            titleMedium: GoogleFonts.inter(
                                fontSize: 16, fontWeight: FontWeight.w600),
                            bodyMedium: GoogleFonts.inter(fontSize: 14),
                          ),
                        ),
                        child: const ProfileBoxWithSlideAnimation(),
                      ),
                    ],
                  );
                },
                navigatorKey: navKey,
                title: 'El Race',
                theme: ThemeData(
                  colorScheme:
                      ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                  useMaterial3: true,
                  textTheme: TextTheme(
                    displayLarge: GoogleFonts.koulen(
                        fontSize: 28, fontWeight: FontWeight.w400),
                    titleMedium: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600),
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
                locale: SharedPref().isArabic()
                    ? localizationDelegate.supportedLocales.last
                    : localizationDelegate.supportedLocales.first,
                onGenerateRoute: onGeneratedRoutes.generatedRoutes,
                home: const SplashScreen()),
          ),
        ),
      ),
    );
  }
}

GlobalKey<NavigatorState> navKey = GlobalKey();
final GlobalKey<OverlayState> appOverlayKey = GlobalKey<OverlayState>();
