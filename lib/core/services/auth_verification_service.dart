import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum representing available authentication methods
enum AuthMethod {
  faceRecognition,
  fingerprint,
  password,
  none,
}

/// Result of authentication attempt
class AuthResult {
  final bool success;
  final AuthMethod method;
  final String? message;

  AuthResult({
    required this.success,
    required this.method,
    this.message,
  });
}

/// Service to handle multiple authentication methods with fallback
class AuthVerificationService {
  static final AuthVerificationService _instance =
      AuthVerificationService._internal();
  factory AuthVerificationService() => _instance;
  AuthVerificationService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  // Keys for SharedPreferences
  static const String _userPinKey = 'user_verification_pin';
  static const String _preferredAuthMethodKey = 'preferred_auth_method';

  /// Check if device supports biometric authentication (fingerprint/face)
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if fingerprint is available
  Future<bool> isFingerprintAvailable() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint) ||
        biometrics.contains(BiometricType.strong) ||
        biometrics.contains(BiometricType.weak);
  }

  /// Check if device face recognition (Face ID) is available
  Future<bool> isDeviceFaceIdAvailable() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  /// Check if front camera is available for face recognition
  Future<bool> isFrontCameraAvailable() async {
    try {
      final cameras = await availableCameras();
      return cameras
          .any((camera) => camera.lensDirection == CameraLensDirection.front);
    } catch (e) {
      debugPrint('Error checking front camera availability: $e');
      return false;
    }
  }

  /// Authenticate using device biometrics (fingerprint or Face ID)
  Future<AuthResult> authenticateWithBiometrics({
    String localizedReason = 'الرجاء التحقق من هويتك للمتابعة',
    bool biometricOnly = false,
  }) async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
        ),
      );

      final biometrics = await getAvailableBiometrics();
      AuthMethod usedMethod = AuthMethod.fingerprint;
      if (biometrics.contains(BiometricType.face)) {
        usedMethod = AuthMethod.faceRecognition;
      }

      return AuthResult(
        success: didAuthenticate,
        method: usedMethod,
        message: didAuthenticate ? 'تم التحقق بنجاح' : 'فشل التحقق',
      );
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: $e');
      return AuthResult(
        success: false,
        method: AuthMethod.none,
        message: _handleBiometricError(e),
      );
    }
  }

  /// Authenticate using fingerprint only
  Future<AuthResult> authenticateWithFingerprint() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'ضع إصبعك على الماسح للتحقق',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );

      return AuthResult(
        success: didAuthenticate,
        method: AuthMethod.fingerprint,
        message: didAuthenticate ? 'تم التحقق بنجاح' : 'فشل التحقق بالبصمة',
      );
    } on PlatformException catch (e) {
      debugPrint('Fingerprint authentication error: $e');
      return AuthResult(
        success: false,
        method: AuthMethod.fingerprint,
        message: _handleBiometricError(e),
      );
    }
  }

  /// Handle biometric errors and return user-friendly message
  String _handleBiometricError(PlatformException e) {
    switch (e.code) {
      case 'NotEnrolled':
        return 'لم يتم تسجيل أي بصمة على هذا الجهاز';
      case 'LockedOut':
        return 'تم تعطيل البصمة مؤقتاً بسبب المحاولات الكثيرة';
      case 'PermanentlyLockedOut':
        return 'تم تعطيل البصمة. الرجاء استخدام كلمة المرور';
      case 'NotAvailable':
        return 'البصمة غير متاحة على هذا الجهاز';
      default:
        return 'حدث خطأ أثناء التحقق: ${e.message}';
    }
  }

  /// Save user PIN for password authentication
  Future<void> setUserPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userPinKey, pin);
  }

  /// Check if user has set a PIN
  Future<bool> hasUserPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userPinKey);
  }

  /// Verify user PIN
  Future<AuthResult> verifyPin(String enteredPin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString(_userPinKey);

    if (storedPin == null) {
      return AuthResult(
        success: false,
        method: AuthMethod.password,
        message: 'لم يتم تعيين رمز PIN',
      );
    }

    final isValid = storedPin == enteredPin;
    return AuthResult(
      success: isValid,
      method: AuthMethod.password,
      message: isValid ? 'تم التحقق بنجاح' : 'رمز PIN غير صحيح',
    );
  }

  /// Get the best available authentication method for this device
  Future<AuthMethod> getBestAvailableMethod() async {
    // First priority: device biometrics (fingerprint/Face ID)
    if (await isBiometricAvailable()) {
      final biometrics = await getAvailableBiometrics();
      if (biometrics.contains(BiometricType.fingerprint) ||
          biometrics.contains(BiometricType.strong) ||
          biometrics.contains(BiometricType.weak)) {
        return AuthMethod.fingerprint;
      }
      if (biometrics.contains(BiometricType.face)) {
        return AuthMethod.faceRecognition;
      }
    }

    // Fallback: password/PIN
    return AuthMethod.password;
  }

  /// Get all available authentication methods based on device capabilities
  Future<List<AuthMethod>> getAvailableMethods() async {
    final methods = <AuthMethod>[];

    // Add face recognition only if front camera is available
    if (await isFrontCameraAvailable()) {
      methods.add(AuthMethod.faceRecognition);
    }

    // Check device biometrics
    if (await isBiometricAvailable()) {
      final biometrics = await getAvailableBiometrics();

      // Check for fingerprint
      if (biometrics.contains(BiometricType.fingerprint) ||
          biometrics.contains(BiometricType.strong) ||
          biometrics.contains(BiometricType.weak)) {
        methods.add(AuthMethod.fingerprint);
      }
    }

    // Always add password/PIN as fallback
    methods.add(AuthMethod.password);

    return methods;
  }

  /// Save preferred authentication method
  Future<void> setPreferredMethod(AuthMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferredAuthMethodKey, method.name);
  }

  /// Get preferred authentication method
  Future<AuthMethod?> getPreferredMethod() async {
    final prefs = await SharedPreferences.getInstance();
    final methodName = prefs.getString(_preferredAuthMethodKey);
    if (methodName == null) return null;

    try {
      return AuthMethod.values.firstWhere((m) => m.name == methodName);
    } catch (_) {
      return null;
    }
  }

  /// Show authentication options dialog and return result
  Future<AuthResult?> showAuthOptionsDialog(BuildContext context) async {
    final availableMethods = await getAvailableMethods();

    return showDialog<AuthResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AuthOptionsDialog(
        availableMethods: availableMethods,
        authService: this,
      ),
    );
  }
}

/// Dialog to show available authentication options
class AuthOptionsDialog extends StatefulWidget {
  final List<AuthMethod> availableMethods;
  final AuthVerificationService authService;

  const AuthOptionsDialog({
    super.key,
    required this.availableMethods,
    required this.authService,
  });

  @override
  State<AuthOptionsDialog> createState() => _AuthOptionsDialogState();
}

class _AuthOptionsDialogState extends State<AuthOptionsDialog> {
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _showPinInput = false;
  bool _isSettingNewPin = false;
  bool? _hasExistingPin;

  @override
  void initState() {
    super.initState();
    _checkExistingPin();
  }

  Future<void> _checkExistingPin() async {
    final hasPin = await widget.authService.hasUserPin();
    setState(() => _hasExistingPin = hasPin);
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _authenticateWithFingerprint() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.authService.authenticateWithBiometrics(
      localizedReason: 'التحقق من الهوية للحضور',
      biometricOnly: true,
    );

    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.of(context).pop(result);
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  Future<void> _authenticateWithPin() async {
    if (_pinController.text.isEmpty) {
      setState(() => _errorMessage = 'الرجاء إدخال رمز PIN');
      return;
    }

    if (_pinController.text.length < 4) {
      setState(() => _errorMessage = 'رمز PIN يجب أن يكون 4 أرقام على الأقل');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // If setting new PIN
    if (_isSettingNewPin) {
      if (_confirmPinController.text.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'الرجاء تأكيد رمز PIN';
        });
        return;
      }

      if (_pinController.text != _confirmPinController.text) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'رمز PIN غير متطابق';
        });
        return;
      }

      // Save new PIN
      await widget.authService.setUserPin(_pinController.text);
      setState(() => _isLoading = false);

      Navigator.of(context).pop(AuthResult(
        success: true,
        method: AuthMethod.password,
        message: 'تم تعيين رمز PIN بنجاح',
      ));
    } else {
      // Verify existing PIN
      final result = await widget.authService.verifyPin(_pinController.text);

      setState(() => _isLoading = false);

      if (result.success) {
        Navigator.of(context).pop(result);
      } else {
        setState(() => _errorMessage = result.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'اختر طريقة التحقق',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )
            else if (_showPinInput)
              _buildPinInput()
            else
              _buildAuthOptions(),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('إلغاء'),
        ),
        if (_showPinInput)
          ElevatedButton(
            onPressed: _authenticateWithPin,
            child: const Text('تأكيد'),
          ),
      ],
    );
  }

  Widget _buildAuthOptions() {
    return Column(
      children: [
        // Face Recognition option (app-level camera face recognition)
        if (widget.availableMethods.contains(AuthMethod.faceRecognition))
          _buildAuthOption(
            icon: Icons.face,
            title: 'التعرف على الوجه',
            subtitle: 'استخدم الكاميرا للتحقق من الوجه',
            onTap: _selectCameraFaceRecognition,
            color: const Color(0xFF1A1A53),
          ),

        // Fingerprint option (device biometric)
        if (widget.availableMethods.contains(AuthMethod.fingerprint))
          _buildAuthOption(
            icon: Icons.fingerprint,
            title: 'بصمة الإصبع',
            subtitle: 'استخدم بصمة الإصبع للتحقق',
            onTap: _authenticateWithFingerprint,
            color: const Color(0xFF28A745),
          ),

        // Password/PIN option (fallback)
        if (widget.availableMethods.contains(AuthMethod.password))
          _buildAuthOption(
            icon: Icons.lock,
            title: _hasExistingPin == true ? 'رمز PIN' : 'تعيين رمز PIN',
            subtitle: _hasExistingPin == true
                ? 'أدخل رمز PIN للتحقق'
                : 'قم بإنشاء رمز PIN جديد',
            onTap: () => setState(() {
              _showPinInput = true;
              _isSettingNewPin = _hasExistingPin != true;
            }),
            color: const Color(0xFF6C757D),
          ),
      ],
    );
  }

  /// Select camera face recognition - returns to the original face verification flow
  void _selectCameraFaceRecognition() {
    Navigator.of(context).pop(AuthResult(
      success: false,
      method: AuthMethod.faceRecognition,
      message: 'use_face_recognition',
    ));
  }

  Widget _buildAuthOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinInput() {
    final isNewPin = _hasExistingPin == false;

    return Column(
      children: [
        IconButton(
          onPressed: () => setState(() {
            _showPinInput = false;
            _isSettingNewPin = false;
            _pinController.clear();
            _confirmPinController.clear();
            _errorMessage = null;
          }),
          icon: const Icon(Icons.arrow_back),
        ),
        const SizedBox(height: 16),
        const Icon(Icons.lock, size: 48, color: Color(0xFF6C757D)),
        const SizedBox(height: 16),
        Text(
          isNewPin ? 'تعيين رمز PIN جديد' : 'أدخل رمز PIN',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        if (isNewPin)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'لم يتم تعيين رمز PIN بعد. الرجاء إنشاء رمز جديد.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          textAlign: TextAlign.center,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: '****',
            labelText: isNewPin ? 'رمز PIN الجديد' : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            counterText: '',
          ),
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
        ),
        if (isNewPin) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            textAlign: TextAlign.center,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: '****',
              labelText: 'تأكيد رمز PIN',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              counterText: '',
            ),
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
          ),
        ],
      ],
    );
  }
}
