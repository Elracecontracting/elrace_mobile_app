import 'package:el_race/core/services/notification_storage_service.dart';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:el_race/data/services/hive_service.dart';
import 'package:el_race/data/services/prayer_background_service.dart';
import 'package:el_race/providers/announcements_provider.dart';
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
import 'package:el_race/ui/presentation/qr_survey/providers/qr_survey_data_provider.dart';
import 'package:el_race/ui/presentation/qr_survey/services/qr_survey_api_service.dart';
import 'package:el_race/ui/presentation/qr_survey/screens/qr_code_wrapper.dart';
import 'package:el_race/ui/presentation/qr_survey/screens/qr_survey_authenticated_screen.dart';
import 'package:el_race/ui/presentation/tasks/data/tasks_api_service.dart';
import 'package:el_race/ui/presentation/tasks/data/tasks_repository.dart';
import 'package:el_race/ui/presentation/tasks/logic/tasks_provider.dart';
import 'package:el_race/utils/di.dart';
import 'package:el_race/utils/generated_routes.dart';
import 'package:el_race/utils/orientation_helper.dart';
import 'package:el_race/utils/screen_size_util.dart';
import 'package:el_race/core/biometric/ios/face_id_helper.dart';
import 'package:el_race/core/biometric/android/android_biometric_helper.dart';
import 'package:el_race/core/biometric/face_recognition/face_recognition_di.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'core/services/app_config_service.dart';
import 'firebase_service.dart';
import 'report_module/data/provider/reports_provider.dart';
import 'ui/presentation/Email Approval/bloc/approval_bloc.dart';
import 'ui/presentation/home_screen/provider/slider_provider.dart';

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
  //await ScreenProtector.protectDataLeakageOn();

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

  // Initialize Face Recognition System
  await FaceRecognitionDI.init();

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

    // Initialize deep linking
    _initDeepLinking(context);

    return LocalizationProvider(
      state: LocalizationProvider.of(context).state,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SliderProvider()),
          ChangeNotifierProvider(create: (_) => ProfileBoxProvider()),
          ChangeNotifierProvider(create: (_) => ReportProvider()),
          ChangeNotifierProvider(create: (_) => TodoProvider()..initialize()),
          ChangeNotifierProvider(create: (_) => QrSurveyDataProvider()),
          ChangeNotifierProvider(create: (_) => AnnouncementsProvider()),
          ChangeNotifierProvider(
            create: (_) =>
                TasksProvider(TasksRepository(api: TasksApiService()))
                  ..loadTasks(),
          ),
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
bool _deepLinkingInitialized = false;
Uri? _lastHandledDeepLink;
DateTime? _lastHandledAt;
const Duration _deepLinkDedupWindow = Duration(seconds: 2);

// Deep Linking Handler
void _initDeepLinking(BuildContext context) {
  // Prevent multiple initializations on rebuild
  if (_deepLinkingInitialized) {
    return;
  }
  _deepLinkingInitialized = true;

  print(
      '🚀 ==================== INITIALIZING DEEP LINKING ====================');
  final appLinks = AppLinks();

  // Handle incoming links - the app is already started
  print('👂 Listening for incoming deep links...');
  appLinks.uriLinkStream.listen((uri) {
    print('🔗 Deep link received (stream): $uri');
    _handleDeepLink(uri, context);
  }, onError: (err) {
    print('❌ Deep link stream error: $err');
  });

  // Handle initial link - the app was started via a link
  print('🔍 Checking for initial deep link...');
  appLinks.getInitialLink().then((uri) {
    if (uri != null) {
      print('🔗 Initial deep link found: $uri');
      _handleDeepLink(uri, context);
    } else {
      print('ℹ️ No initial deep link found (app opened normally)');
    }
  });
  print(
      '🚀 ==================== DEEP LINKING INITIALIZED ====================');
}

void _handleDeepLink(Uri uri, BuildContext context) async {
  // Drop duplicate events that arrive back-to-back for the same URI
  if (_lastHandledDeepLink == uri) {
    final now = DateTime.now();
    if (_lastHandledAt != null &&
        now.difference(_lastHandledAt!) <= _deepLinkDedupWindow) {
      print('⏩ Skipping duplicate deep link within debounce window: $uri');
      return;
    }
  }

  _lastHandledDeepLink = uri;
  _lastHandledAt = DateTime.now();

  print('🔗 ==================== DEEP LINK HANDLER ====================');
  print('🔗 Received URI: $uri');
  print('🔗 Host: ${uri.host}');
  print('🔗 Path: ${uri.path}');
  print('🔗 Query Parameters: ${uri.queryParameters}');

  // Check if it's a QR code survey link
  // Format: https://elrace.com/RCC4/Requirements/qrcodeapp
  if (uri.host == 'elrace.com' &&
      uri.path.contains('/RCC4/Requirements/qrcodeapp')) {
    print('📱 QR Survey link detected!');
    print('📱 Starting API call to fetch content...');

    // Fetch content from API
    try {
      final content = await QrSurveyApiService().getContentAfterQrCodeScanned();
      print(
          '📦 API Response received: ${content != null ? "Success" : "Null"}');

      if (content != null && context.mounted) {
        print('📦 Content Data: $content');

        // Store in provider
        final effectiveContext = navKey.currentContext ?? context;
        final provider =
            Provider.of<QrSurveyDataProvider>(effectiveContext, listen: false);
        provider.setContentData(content);
        print('✅ Content stored in provider');

        // Check if user is logged in
        print('🔐 Checking login status...');
        final loginData = SharedPref.getLoginData();
        final token = loginData.result?.token;
        final isLoggedIn = token != null && token.isNotEmpty;
        print(
            '🔐 Token: ${token != null ? "Found (${token.substring(0, 10)}...)" : "Not Found"}');
        print('🔐 Is Logged In: $isLoggedIn');

        // Navigate based on login status
        if (isLoggedIn) {
          // Logged in user - show with AppBar and BottomBar
          print(
              '✅ User logged in - showing authenticated screen with AppBar/BottomBar');
          navKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => const QrSurveyAuthenticatedScreen(),
            ),
          );
        } else {
          // Guest user - show without AppBar and BottomBar
          print('👤 Guest user - showing guest screen (no AppBar/BottomBar)');
          navKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => const QrCodeWrapper(),
            ),
          );
        }
        print(
            '🔗 ==================== NAVIGATION COMPLETE ====================');
      } else {
        print(
            '❌ Content is null or context not mounted - using guest fallback');
        final effectiveContext = navKey.currentContext ?? context;
        try {
          final provider = Provider.of<QrSurveyDataProvider>(effectiveContext,
              listen: false);
          provider.clearData();
        } catch (_) {
          print('⚠️ Provider<QrSurveyDataProvider> not found during fallback');
        }
        navKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => const QrCodeWrapper(),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Error handling QR deep link: $e');
      print('❌ Stack trace: $stackTrace');
      // In case of error, still route to guest flow so user sees something
      final effectiveContext = navKey.currentContext ?? context;
      try {
        final provider =
            Provider.of<QrSurveyDataProvider>(effectiveContext, listen: false);
        provider.clearData();
      } catch (_) {
        print(
            '⚠️ Provider<QrSurveyDataProvider> not found during error fallback');
      }
      navKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => const QrCodeWrapper(),
        ),
      );
    }
  } else {
    print('⚠️ URI does not match expected pattern');
    print('⚠️ Expected: https://elrace.com/RCC4/Requirements/qrcodeapp');
  }
  print('🔗 ==================== END DEEP LINK HANDLER ====================');
}
