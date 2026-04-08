import 'package:get_it/get_it.dart';
import 'config/face_recognition_config.dart';
import 'data/services/face_detector_service.dart';
import 'data/services/facenet_service.dart';
import 'data/services/face_embedding_storage_service.dart';
import 'data/services/liveness_service.dart';
import 'data/repositories/face_recognition_repository_impl.dart';
import 'domain/repositories/face_recognition_repository.dart';
import 'domain/usecases/initialize_face_recognition_usecase.dart';
import 'domain/usecases/register_face_usecase.dart';
import 'domain/usecases/verify_face_usecase.dart';
import 'presentation/bloc/face_recognition_bloc.dart';

/// Dependency Injection setup for Face Recognition module
///
/// Call this function in your main.dart to register all dependencies
///
/// Example:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // Initialize face recognition dependencies
///   await FaceRecognitionDI.init();
///
///   runApp(MyApp());
/// }
/// ```
class FaceRecognitionDI {
  static final GetIt _getIt = GetIt.instance;
  static bool _initialized = false;

  static Future<void> init() async {
    // Prevent double initialization
    if (_initialized && _getIt.isRegistered<FaceRecognitionRepository>()) {
      print('ℹ️ Face Recognition already initialized, skipping...');
      return;
    }

    // Reset if partially initialized (e.g., after hot restart)
    if (_getIt.isRegistered<FaceDetectorService>()) {
      print('🔄 Resetting Face Recognition DI for re-initialization...');
      await _resetFaceRecognitionDI();
    }

    // Services (Singletons - created once and reused)
    _getIt.registerLazySingleton<FaceDetectorService>(
      () => FaceDetectorService(),
    );

    _getIt.registerLazySingleton<FaceNetService>(
      () => FaceNetService(),
    );

    _getIt.registerLazySingleton<FaceEmbeddingStorageService>(
      () => FaceEmbeddingStorageService(),
    );

    // Liveness Service (Singleton)
    _getIt.registerLazySingleton<LivenessService>(
      () => LivenessService(_getIt<FaceDetectorService>()),
    );

    // Repository (Singleton) — uses centralized config values
    _getIt.registerLazySingleton<FaceRecognitionRepository>(
      () => FaceRecognitionRepositoryImpl(
        faceDetectorService: _getIt<FaceDetectorService>(),
        faceNetService: _getIt<FaceNetService>(),
        storageService: _getIt<FaceEmbeddingStorageService>(),
        verificationThreshold:
            FaceRecognitionConfig.matchingThreshold,
        useCosineSimilarity: FaceRecognitionConfig.useCosineSimilarity,
        enableLivenessCheck:
            true, // ✅ REQUIRED: Anti-spoofing enabled to prevent photo attacks
      ),
    );

    // Use Cases (Factories - new instance each time)
    _getIt.registerFactory<InitializeFaceRecognitionUseCase>(
      () =>
          InitializeFaceRecognitionUseCase(_getIt<FaceRecognitionRepository>()),
    );

    _getIt.registerFactory<RegisterFaceUseCase>(
      () => RegisterFaceUseCase(_getIt<FaceRecognitionRepository>()),
    );

    _getIt.registerFactory<VerifyFaceUseCase>(
      () => VerifyFaceUseCase(_getIt<FaceRecognitionRepository>()),
    );

    // BLoC (Factory)
    _getIt.registerFactory<FaceRecognitionBloc>(
      () => FaceRecognitionBloc(
        initializeUseCase: _getIt<InitializeFaceRecognitionUseCase>(),
        registerFaceUseCase: _getIt<RegisterFaceUseCase>(),
        verifyFaceUseCase: _getIt<VerifyFaceUseCase>(),
        repository: _getIt<FaceRecognitionRepository>(),
        livenessService: _getIt<LivenessService>(),
      ),
    );

    // Initialize services (with error handling - model file might be missing)
    try {
      await _getIt<FaceDetectorService>().initialize();
      await _getIt<FaceNetService>().initialize();
      _initialized = true;
      print('✅ Face Recognition initialized successfully');
    } catch (e) {
      print('⚠️ Face Recognition initialization failed: $e');
      print(
          'ℹ️ Face recognition features will be disabled until model file is added');
      // Don't throw - allow app to continue without face recognition
    }
  }

  /// Reset Face Recognition DI registrations
  static Future<void> _resetFaceRecognitionDI() async {
    try {
      if (_getIt.isRegistered<FaceRecognitionBloc>()) {
        _getIt.unregister<FaceRecognitionBloc>();
      }
      if (_getIt.isRegistered<VerifyFaceUseCase>()) {
        _getIt.unregister<VerifyFaceUseCase>();
      }
      if (_getIt.isRegistered<RegisterFaceUseCase>()) {
        _getIt.unregister<RegisterFaceUseCase>();
      }
      if (_getIt.isRegistered<InitializeFaceRecognitionUseCase>()) {
        _getIt.unregister<InitializeFaceRecognitionUseCase>();
      }
      if (_getIt.isRegistered<FaceRecognitionRepository>()) {
        _getIt.unregister<FaceRecognitionRepository>();
      }
      if (_getIt.isRegistered<LivenessService>()) {
        _getIt.unregister<LivenessService>();
      }
      if (_getIt.isRegistered<FaceEmbeddingStorageService>()) {
        _getIt.unregister<FaceEmbeddingStorageService>();
      }
      if (_getIt.isRegistered<FaceNetService>()) {
        _getIt.unregister<FaceNetService>();
      }
      if (_getIt.isRegistered<FaceDetectorService>()) {
        _getIt.unregister<FaceDetectorService>();
      }
      _initialized = false;
    } catch (e) {
      print('⚠️ Error resetting Face Recognition DI: $e');
    }
  }

  /// Get instance of a registered dependency
  static T get<T extends Object>() => _getIt<T>();

  /// Reset all dependencies (useful for testing)
  static Future<void> reset() async {
    await _resetFaceRecognitionDI();
  }
}
