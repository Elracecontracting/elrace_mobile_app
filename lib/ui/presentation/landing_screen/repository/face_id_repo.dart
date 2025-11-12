import 'package:local_auth/local_auth.dart';

class FaceIDRepo {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticateWithBiometrics() async {
    final LocalAuthentication localAuthentication = LocalAuthentication();
    bool isBiometricSupported = await localAuthentication.isDeviceSupported();
    bool canCheckBiometrics = await localAuthentication.canCheckBiometrics;

    bool isAuthenticated = false;

    isAuthenticated = await _auth.authenticate(
      localizedReason:
          'Scan your fingerprint (or face or whatever) to authenticate',
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: true,
      ),
    );

    return isAuthenticated;
  }
}
