import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';

class LocalAuthService {
  static final _auth = LocalAuthentication();

  /// Check if the device has biometric hardware and it is configured
  static Future<bool> canCheckBiometrics() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('[LocalAuth] canCheckBiometrics error: $e');
      return false;
    }
  }

  /// Authenticate the user with biometrics
  static Future<bool> authenticate() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate to unlock the app',
        biometricOnly: false, // fallback to pin/pattern is okay
        persistAcrossBackgrounding: true,
      );
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('[LocalAuth] authenticate error: $e');
      // In local_auth 3.0.1, specific error handling can use LocalAuthException
      // For now, any error means authentication failed.
      return false;
    }
  }
}
