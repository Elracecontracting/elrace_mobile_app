import 'package:get_it/get_it.dart';
import 'data/services/face_detector_service.dart';
import 'data/services/facenet_service.dart';
import 'data/services/face_embedding_storage_service.dart';
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

  static Future<void> init() async {
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

    // Repository (Singleton)
    _getIt.registerLazySingleton<FaceRecognitionRepository>(
      () => FaceRecognitionRepositoryImpl(
        faceDetectorService: _getIt<FaceDetectorService>(),
        faceNetService: _getIt<FaceNetService>(),
        storageService: _getIt<FaceEmbeddingStorageService>(),
        verificationThreshold:
            0.6, // Stricter matching for check-in/out (lower = more strict)
        useCosineSimilarity: false, // true for cosine, false for Euclidean
        enableLivenessCheck:
            false, // Disabled for easier first-time registration
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
      ),
    );

    // Initialize services (with error handling - model file might be missing)
    try {
      await _getIt<FaceDetectorService>().initialize();
      await _getIt<FaceNetService>().initialize();
      print('✅ Face Recognition initialized successfully');
    } catch (e) {
      print('⚠️ Face Recognition initialization failed: $e');
      print(
          'ℹ️ Face recognition features will be disabled until model file is added');
      // Don't throw - allow app to continue without face recognition
    }
  }

  /// Get instance of a registered dependency
  static T get<T extends Object>() => _getIt<T>();

  /// Reset all dependencies (useful for testing)
  static Future<void> reset() async {
    await _getIt.reset();
  }
}
