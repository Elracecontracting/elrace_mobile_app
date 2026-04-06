import 'dart:io' show Platform;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../domain/usecases/initialize_face_recognition_usecase.dart';
import '../../domain/usecases/register_face_usecase.dart';
import '../../domain/usecases/verify_face_usecase.dart';
import '../../domain/repositories/face_recognition_repository.dart';
import '../../data/services/liveness_service.dart';
import '../../data/services/dual_verification_service.dart';
import '../../data/services/firebase_face_service.dart';
import '../../config/face_recognition_config.dart';
import 'face_recognition_event.dart';
import 'face_recognition_state.dart';

/// BLoC for Face Recognition feature
///
/// Handles all business logic and state management for face recognition
///
/// SECURITY ENHANCED (v2.0):
/// - Dual verification (Local + Firebase)
/// - Device binding enforcement
/// - Anti-fraud detection
/// - Comprehensive audit logging
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
  
  // NEW: Enhanced security services
  late final DualVerificationService _dualVerificationService;
  late final FirebaseFaceService _firebaseFaceService;

  CameraController? _cameraController;

  FaceRecognitionBloc({
    required InitializeFaceRecognitionUseCase initializeUseCase,
    required RegisterFaceUseCase registerFaceUseCase,
    required VerifyFaceUseCase verifyFaceUseCase,
    required FaceRecognitionRepository repository,
    LivenessService? livenessService,
    DualVerificationService? dualVerificationService,
    FirebaseFaceService? firebaseFaceService,
  })  : _initializeUseCase = initializeUseCase,
        _registerFaceUseCase = registerFaceUseCase,
        _verifyFaceUseCase = verifyFaceUseCase,
        _repository = repository,
        _livenessService = livenessService,
        super(FaceRecognitionInitial()) {
    // Initialize enhanced security services
    _dualVerificationService = dualVerificationService ?? DualVerificationService();
    _firebaseFaceService = firebaseFaceService ?? FirebaseFaceService();
    
    // Register event handlers
    on<InitializeFaceRecognition>(_onInitialize);
    on<InitializeCamera>(_onInitializeCamera);
    on<StartFaceRegistration>(_onRegisterFace);
    on<StartFaceVerification>(_onVerifyFace);
    on<StartMultiFrameVerification>(_onMultiFrameVerify); // 🆕 فحص الرمش متعدد الإطارات
    on<StartActiveLivenessVerification>(_onActiveLivenessVerify); // 🆕 فحص التحديات النشطة
    on<VerifySingleChallengeEvent>(_onVerifySingleChallenge); // 🆕 التحقق من تحدي واحد
    on<RequestNextChallengeEvent>(_onRequestNextChallenge); // 🆕 طلب التحدي التالي
    on<ResetChallengesEvent>(_onResetChallenges); // 🆕 إعادة تعيين التحديات
    on<CheckFaceLiveness>(_onCheckLiveness);
    on<StartLivenessChallenge>(_onStartLivenessChallenge);
    on<DeleteStoredEmbeddings>(_onDeleteEmbeddings);
    on<ResetFaceRecognition>(_onReset);
    on<CheckDeviceBindingEvent>(_onCheckDeviceBinding);
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
      (_) async {
        // Also initialize dual verification service
        await _dualVerificationService.initialize();
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
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
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

  /// 🆕 Multi-frame verification with BLINK detection
  Future<void> _onMultiFrameVerify(
    StartMultiFrameVerification event,
    Emitter<FaceRecognitionState> emit,
  ) async {
    emit(FaceRecognitionLoading(message: 'Verifying face...'));

    print('\n🔐 ===== FACE VERIFICATION (MULTI-FRAME ANTI-SPOOF) =====');
    print('📸 Total frames collected: ${event.frames.length}');

    try {
      // Use last frame for embedding, but pass all frames for anti-spoof analysis
      print('🔍 Verifying face match with anti-spoof check...');
      
      final result = await _verifyFaceUseCase(
        image: event.frames.last,
        userId: event.userId,
        allFrames: event.frames, // 🆕 Pass all frames for variation analysis
      );

      result.fold(
        (failure) {
          print('❌ Face verification failed: ${failure.message}');
          final errorType = _mapFailureToErrorType(failure);
          emit(FaceRecognitionError(
            message: failure.message,
            errorType: errorType,
          ));
        },
        (verificationResult) {
          print('✅ Face verification result: ${verificationResult.isVerified}, confidence: ${verificationResult.confidence}');
          emit(FaceVerificationResult(
            isVerified: verificationResult.isVerified,
            confidence: verificationResult.confidence,
            message: verificationResult.isVerified
                ? '✅ Face verified successfully!'
                : 'Face not recognized. Please try again.',
            hasLiveness: true,
          ));
        },
      );
    } catch (e) {
      print('❌ Error in face verification: $e');
      emit(FaceRecognitionError(
        message: 'Error during verification: $e',
        errorType: FaceRecognitionErrorType.unknown,
      ));
    }
  }

  /// 🆕 Active Liveness Verification with Multiple Challenges
  /// التحقق النشط مع التحديات المتعددة (رمش، حركة رأس، حركة عين)
  Future<void> _onActiveLivenessVerify(
    StartActiveLivenessVerification event,
    Emitter<FaceRecognitionState> emit,
  ) async {
    print('\n🔐 ===== ACTIVE LIVENESS VERIFICATION =====');
    print('📸 Total frames: ${event.frames.length}');
    print('👤 User ID: ${event.userId}');
    print('⏭️ Skip challenges: ${event.skipChallenges}');

    if (_livenessService == null) {
      print('⚠️ Liveness service not available');
      emit(FaceRecognitionError(
        message: 'خدمة التحقق من الحيوية غير متاحة',
        errorType: FaceRecognitionErrorType.livenessCheckFailed,
      ));
      return;
    }

    try {
      // إنشاء تسلسل التحديات
      final challenges = _livenessService.generateChallengeSequence();
      print('🎯 Generated ${challenges.length} challenges');

      // إرسال أول تحدي للعرض
      if (challenges.isNotEmpty) {
        final firstChallenge = challenges.first;
        emit(LivenessChallengeInProgress(
          challengeText: firstChallenge.displayText,
          challengeInstruction: firstChallenge.instruction,
          currentChallengeIndex: 0,
          totalChallenges: challenges.length,
          completedChallenges: const [],
          iconCodePoint: firstChallenge.icon.codePoint,
        ));
      }

      // جمع الوجوه من الإطارات
      final faces = <Face>[];
      for (final frame in event.frames) {
        final detectedFaces = await _repository.detectFaces(frame);
        if (detectedFaces.isNotEmpty) {
          faces.add(detectedFaces.first);
        }
      }

      print('👁️ Collected ${faces.length} face frames');

      if (faces.length < 15) {
        emit(FaceRecognitionError(
          message: 'لم يتم جمع إطارات كافية. حاول مرة أخرى.',
          errorType: FaceRecognitionErrorType.livenessCheckFailed,
        ));
        return;
      }

      // التحقق من جميع التحديات
      final livenessResult = await _livenessService.verifyAllChallenges(
        faceSequence: faces,
        minFramesPerChallenge: 5,
      );

      if (!livenessResult.passed) {
        print('❌ Active liveness FAILED: ${livenessResult.message}');
        
        // إظهار التحدي الفاشل
        if (livenessResult.currentChallenge != null) {
          emit(SingleChallengeFailed(
            challengeName: livenessResult.currentChallenge!.displayText,
            challengeIndex: livenessResult.completedChallenges.length,
            totalChallenges: challenges.length,
            message: livenessResult.message,
          ));
        }
        
        emit(FaceVerificationResult(
          isVerified: false,
          confidence: 0.0,
          message: livenessResult.message,
          hasLiveness: false,
        ));
        return;
      }

      print('✅ All challenges passed! Verifying face...');

      // التحقق من الوجه
      final result = await _verifyFaceUseCase(
        image: event.frames.last,
        userId: event.userId,
      );

      result.fold(
        (failure) {
          emit(FaceRecognitionError(
            message: failure.message,
            errorType: _mapFailureToErrorType(failure),
          ));
        },
        (verificationResult) {
          emit(FaceVerificationResult(
            isVerified: verificationResult.isVerified,
            confidence: verificationResult.confidence,
            message: verificationResult.isVerified
                ? '✅ Verification successful! All challenges completed.'
                : 'Face verification failed. Please try again.',
            hasLiveness: true,
          ));
        },
      );
    } catch (e) {
      print('❌ Error in active liveness: $e');
      emit(FaceRecognitionError(
        message: 'Error during verification: $e',
        errorType: FaceRecognitionErrorType.unknown,
      ));
    }
  }

  /// 🆕 Verify single challenge
  Future<void> _onVerifySingleChallenge(
    VerifySingleChallengeEvent event,
    Emitter<FaceRecognitionState> emit,
  ) async {
    if (_livenessService == null) {
      emit(FaceRecognitionError(
        message: 'Verification service not available',
        errorType: FaceRecognitionErrorType.livenessCheckFailed,
      ));
      return;
    }

    try {
      final currentChallenge = _livenessService.getCurrentChallenge();
      if (currentChallenge == null) {
        emit(LivenessCheckComplete(
          passed: true,
          message: 'جميع التحديات مكتملة',
        ));
        return;
      }

      emit(FaceRecognitionLoading(
        message: 'جاري التحقق من ${currentChallenge.displayText}...',
      ));

      // جمع الوجوه
      final faces = <Face>[];
      for (final frame in event.frames) {
        final detectedFaces = await _repository.detectFaces(frame);
        if (detectedFaces.isNotEmpty) {
          faces.add(detectedFaces.first);
        }
      }

      final result = await _livenessService.verifySingleChallenge(
        challenge: currentChallenge,
        faceSequence: faces,
      );

      if (result.passed) {
        emit(SingleChallengeSuccess(
          challengeName: currentChallenge.displayText,
          challengeIndex: event.challengeIndex,
          totalChallenges: _livenessService.getTotalChallenges(),
          message: result.message,
        ));

        // التحقق إذا كانت جميع التحديات مكتملة
        final nextChallenge = _livenessService.getCurrentChallenge();
        if (nextChallenge == null) {
          // جميع التحديات مكتملة - التحقق من الوجه
          emit(LivenessCheckComplete(
            passed: true,
            message: '✅ جميع التحديات مكتملة!',
          ));
        } else {
          // عرض التحدي التالي
          emit(LivenessChallengeInProgress(
            challengeText: nextChallenge.displayText,
            challengeInstruction: nextChallenge.instruction,
            currentChallengeIndex: _livenessService.getCompletedCount(),
            totalChallenges: _livenessService.getTotalChallenges(),
            completedChallenges: _livenessService.completedChallenges
                .map((c) => c.displayText)
                .toList(),
            iconCodePoint: nextChallenge.icon.codePoint,
          ));
        }
      } else {
        emit(SingleChallengeFailed(
          challengeName: currentChallenge.displayText,
          challengeIndex: event.challengeIndex,
          totalChallenges: _livenessService.getTotalChallenges(),
          message: result.message,
        ));
      }
    } catch (e) {
      emit(FaceRecognitionError(
        message: 'Error occurred: $e',
        errorType: FaceRecognitionErrorType.unknown,
      ));
    }
  }

  /// 🆕 Request next challenge
  Future<void> _onRequestNextChallenge(
    RequestNextChallengeEvent event,
    Emitter<FaceRecognitionState> emit,
  ) async {
    if (_livenessService == null) return;

    final nextChallenge = _livenessService.getCurrentChallenge();
    if (nextChallenge != null) {
      emit(LivenessChallengeInProgress(
        challengeText: nextChallenge.displayText,
        challengeInstruction: nextChallenge.instruction,
        currentChallengeIndex: _livenessService.getCompletedCount(),
        totalChallenges: _livenessService.getTotalChallenges(),
        completedChallenges: _livenessService.completedChallenges
            .map((c) => c.displayText)
            .toList(),
        iconCodePoint: nextChallenge.icon.codePoint,
      ));
    }
  }

  /// 🆕 إعادة تعيين التحديات
  Future<void> _onResetChallenges(
    ResetChallengesEvent event,
    Emitter<FaceRecognitionState> emit,
  ) async {
    _livenessService?.resetChallenges();
    emit(FaceRecognitionInitial());
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

    emit(FaceRecognitionLoading(message: 'Verifying liveness...'));

    final result = await _livenessService.performActiveChallengeCheck(
      frameStream: event.frameStream,
      challengeTimeout: const Duration(seconds: 10),
    );

    if (result.passed) {
      emit(LivenessCheckComplete(
        passed: true,
        message: '✅ Liveness verified successfully',
      ));
    } else {
      // Emit current challenge if available for UI guidance
      if (result.currentChallenge != null) {
        emit(LivenessChallengeInProgress(
          challengeText: result.currentChallenge!.displayText,
          challengeInstruction: result.currentChallenge!.instruction,
          currentChallengeIndex: result.completedChallenges.length,
          totalChallenges: result.completedChallenges.length + 1,
          completedChallenges:
              result.completedChallenges.map((c) => c.displayText).toList(),
          iconCodePoint: result.currentChallenge!.icon.codePoint,
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

  /// Check device binding status (NEW - Security Enhancement)
  Future<void> _onCheckDeviceBinding(
    CheckDeviceBindingEvent event,
    Emitter<FaceRecognitionState> emit,
  ) async {
    emit(FaceRecognitionLoading(message: 'Checking device binding...'));

    final deviceStatus = await _firebaseFaceService.checkDeviceBinding(event.userId);

    String message;
    bool isSameDevice = false;

    switch (deviceStatus.status) {
      case DeviceStatus.notRegistered:
        message = 'No face registration found for this user';
        break;
      case DeviceStatus.noDeviceBinding:
        message = 'Face registered without device binding';
        isSameDevice = true;
        break;
      case DeviceStatus.sameDevice:
        message = 'Current device matches registration ✅';
        isSameDevice = true;
        break;
      case DeviceStatus.differentDevice:
        message = 'Face registered on a different device ⚠️';
        isSameDevice = false;
        break;
      case DeviceStatus.error:
        message = 'Device verification error';
        break;
    }

    emit(DeviceBindingCheckResult(
      isSameDevice: isSameDevice,
      registeredDeviceId: deviceStatus.registeredDeviceId,
      currentDeviceId: deviceStatus.currentDeviceId,
      message: message,
    ));
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
