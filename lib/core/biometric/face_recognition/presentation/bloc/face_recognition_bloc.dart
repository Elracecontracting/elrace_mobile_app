import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import '../../domain/usecases/initialize_face_recognition_usecase.dart';
import '../../domain/usecases/register_face_usecase.dart';
import '../../domain/usecases/verify_face_usecase.dart';
import '../../domain/repositories/face_recognition_repository.dart';
import '../../data/services/liveness_service.dart';
import 'face_recognition_event.dart';
import 'face_recognition_state.dart';

/// BLoC for Face Recognition feature
///
/// Handles all business logic and state management for face recognition
///
/// Architecture:
/// UI -> Event -> BLoC -> UseCase -> Repository -> Data Source
/// UI <- State <- BLoC <- Result <- UseCase <- Repository
class FaceRecognitionBloc
    extends Bloc<FaceRecognitionEvent, FaceRecognitionState> {
  final InitializeFaceRecognitionUseCase _initializeUseCase;
  final RegisterFaceUseCase _registerFaceUseCase;
  final VerifyFaceUseCase _verifyFaceUseCase;
  final FaceRecognitionRepository _repository;
  final LivenessService? _livenessService;

  CameraController? _cameraController;

  FaceRecognitionBloc({
    required InitializeFaceRecognitionUseCase initializeUseCase,
    required RegisterFaceUseCase registerFaceUseCase,
    required VerifyFaceUseCase verifyFaceUseCase,
    required FaceRecognitionRepository repository,
    LivenessService? livenessService,
  })  : _initializeUseCase = initializeUseCase,
        _registerFaceUseCase = registerFaceUseCase,
        _verifyFaceUseCase = verifyFaceUseCase,
        _repository = repository,
        _livenessService = livenessService,
        super(FaceRecognitionInitial()) {
    // Register event handlers
    on<InitializeFaceRecognition>(_onInitialize);
    on<InitializeCamera>(_onInitializeCamera);
    on<StartFaceRegistration>(_onRegisterFace);
    on<StartFaceVerification>(_onVerifyFace);
    on<CheckFaceLiveness>(_onCheckLiveness);
    on<StartLivenessChallenge>(_onStartLivenessChallenge);
    on<DeleteStoredEmbeddings>(_onDeleteEmbeddings);
    on<ResetFaceRecognition>(_onReset);
  }

  /// Initialize face recognition system (load models)
  Future<void> _onInitialize(
    InitializeFaceRecognition event,
    Emitter<FaceRecognitionState> emit,
  ) async {
    emit(FaceRecognitionLoading(message: 'Initializing face recognition...'));

    final result = await _initializeUseCase();

    result.fold(
      (failure) {
        emit(FaceRecognitionError(
          message: failure.message,
          errorType: FaceRecognitionErrorType.modelNotLoaded,
        ));
      },
      (_) {
        emit(FaceRecognitionInitial());
      },
    );
  }

  /// Initialize camera
  Future<void> _onInitializeCamera(
    InitializeCamera event,
    Emitter<FaceRecognitionState> emit,
  ) async {
    try {
      emit(FaceRecognitionLoading(message: 'Initializing camera...'));

      _cameraController = CameraController(
        event.camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      emit(FaceRecognitionCameraReady(_cameraController!));
    } catch (e) {
      emit(FaceRecognitionError(
        message: 'Failed to initialize camera: $e',
        errorType: FaceRecognitionErrorType.cameraError,
      ));
    }
  }

  /// Register face with anti-spoofing check
  Future<void> _onRegisterFace(
    StartFaceRegistration event,
    Emitter<FaceRecognitionState> emit,
  ) async {
    emit(FaceRecognitionLoading(message: 'Registering face...'));

    final result = await _registerFaceUseCase(
      image: event.image,
      userId: event.userId,
      label: event.label,
      additionalImages: event.additionalImages, // For anti-spoof
    );

    result.fold(
      (failure) {
        final errorType = _mapFailureToErrorType(failure);
        emit(FaceRecognitionError(
          message: failure.message,
          errorType: errorType,
        ));
      },
      (embedding) {
        emit(FaceRegistrationSuccess(
          message:
              'Face registered successfully! You can now use face authentication.',
        ));
      },
    );
  }

  /// Verify face
  Future<void> _onVerifyFace(
    StartFaceVerification event,
    Emitter<FaceRecognitionState> emit,
  ) async {
    emit(FaceRecognitionLoading(message: 'Verifying face...'));

    final result = await _verifyFaceUseCase(
      image: event.image,
      userId: event.userId,
    );

    result.fold(
      (failure) {
        final errorType = _mapFailureToErrorType(failure);
        emit(FaceRecognitionError(
          message: failure.message,
          errorType: errorType,
        ));
      },
      (verificationResult) {
        emit(FaceVerificationResult(
          isVerified: verificationResult.isVerified,
          confidence: verificationResult.confidence,
          message: verificationResult.message ?? 'Verification complete',
          hasLiveness: verificationResult.hasLiveness,
        ));
      },
    );
  }

  /// Check liveness
  Future<void> _onCheckLiveness(
    CheckFaceLiveness event,
    Emitter<FaceRecognitionState> emit,
  ) async {
    final result = await _repository.checkLiveness(event.image);

    result.fold(
      (failure) {
        emit(FaceDetected(hasLiveness: false, quality: 0.0));
      },
      (hasLiveness) {
        emit(FaceDetected(hasLiveness: hasLiveness, quality: 1.0));
      },
    );
  }

  /// Start active liveness challenge
  Future<void> _onStartLivenessChallenge(
    StartLivenessChallenge event,
    Emitter<FaceRecognitionState> emit,
  ) async {
    if (_livenessService == null) {
      emit(LivenessCheckComplete(
        passed: true,
        message: 'Liveness service not available, skipping check',
      ));
      return;
    }

    emit(FaceRecognitionLoading(message: 'جاري التحقق من الحيوية...'));

    final result = await _livenessService.performActiveChallengeCheck(
      frameStream: event.frameStream,
      challengeTimeout: const Duration(seconds: 10),
    );

    if (result.passed) {
      emit(LivenessCheckComplete(
        passed: true,
        message: '✅ تم التحقق من الحيوية بنجاح',
      ));
    } else {
      // Emit current challenge if available for UI guidance
      if (result.currentChallenge != null) {
        emit(LivenessChallengeInProgress(
          challengeText: result.currentChallenge!.displayText,
          currentChallengeIndex: result.completedChallenges.length,
          totalChallenges: result.completedChallenges.length + 1,
          completedChallenges:
              result.completedChallenges.map((c) => c.displayText).toList(),
        ));
      }

      emit(FaceRecognitionError(
        message: result.message,
        errorType: FaceRecognitionErrorType.livenessCheckFailed,
      ));
    }
  }

  /// Delete stored embeddings
  Future<void> _onDeleteEmbeddings(
    DeleteStoredEmbeddings event,
    Emitter<FaceRecognitionState> emit,
  ) async {
    emit(FaceRecognitionLoading(message: 'Deleting face data...'));

    final result = await _repository.deleteEmbeddings(event.userId);

    result.fold(
      (failure) {
        emit(FaceRecognitionError(
          message: failure.message,
          errorType: FaceRecognitionErrorType.storageError,
        ));
      },
      (_) {
        emit(FaceRecognitionInitial());
      },
    );
  }

  /// Reset to initial state
  Future<void> _onReset(
    ResetFaceRecognition event,
    Emitter<FaceRecognitionState> emit,
  ) async {
    emit(FaceRecognitionInitial());
  }

  /// Map domain failures to UI error types
  FaceRecognitionErrorType _mapFailureToErrorType(
      FaceRecognitionFailure failure) {
    if (failure is NoFaceDetectedFailure) {
      return FaceRecognitionErrorType.noFaceDetected;
    } else if (failure is MultipleFacesDetectedFailure) {
      return FaceRecognitionErrorType.multipleFacesDetected;
    } else if (failure is LivenessCheckFailure) {
      return FaceRecognitionErrorType.livenessCheckFailed;
    } else if (failure is ModelNotLoadedFailure) {
      return FaceRecognitionErrorType.modelNotLoaded;
    } else if (failure is StorageFailure) {
      return FaceRecognitionErrorType.storageError;
    } else if (failure is VerificationFailure) {
      return FaceRecognitionErrorType.verificationFailed;
    } else {
      return FaceRecognitionErrorType.unknown;
    }
  }

  @override
  Future<void> close() {
    _cameraController?.dispose();
    return super.close();
  }
}
