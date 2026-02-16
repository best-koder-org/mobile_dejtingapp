import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Phone Authentication Service
///
/// Handles phone number verification via Firebase Auth.
/// Firebase sends the SMS, verifies the OTP, and issues a Firebase ID Token.
/// The ID token is then exchanged for a Keycloak JWT via token exchange.
///
/// Dev mode: Use Firebase test phone numbers (no real SMS sent).
/// See: https://firebase.google.com/docs/auth/flutter/phone-auth
class FirebasePhoneAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Verification state communicated via callbacks
  static String? _verificationId;
  static int? _forceResendingToken;

  /// Start phone number verification.
  /// Firebase will send an SMS to the given phone number.
  ///
  /// [phoneNumber] Full international format, e.g. "+46701234567"
  /// [onCodeSent] Called when SMS is dispatched — UI should show OTP entry
  /// [onVerificationCompleted] Auto-verification on Android (instant verify)
  /// [onError] Called on failure (invalid number, quota exceeded, etc.)
  /// [onAutoRetrievalTimeout] Called when auto-retrieval times out
  static Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(PhoneAuthCredential credential)
        onVerificationCompleted,
    required void Function(String errorMessage) onError,
    void Function()? onAutoRetrievalTimeout,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: timeout,
        forceResendingToken: _forceResendingToken,

        // Android auto-verification (reads SMS automatically)
        verificationCompleted: (PhoneAuthCredential credential) {
          debugPrint('📱 Phone auto-verified');
          onVerificationCompleted(credential);
        },

        // SMS sent successfully — user needs to enter the code
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('📲 SMS code sent, verificationId=$verificationId');
          _verificationId = verificationId;
          _forceResendingToken = resendToken;
          onCodeSent(verificationId);
        },

        // Verification failed
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Phone verification failed: ${e.code} ${e.message}');
          final message = _mapFirebaseError(e.code);
          onError(message);
        },

        // Auto-retrieval timeout (Android)
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏰ Auto-retrieval timeout');
          _verificationId = verificationId;
          onAutoRetrievalTimeout?.call();
        },
      );
    } catch (e) {
      debugPrint('Phone verification error: $e');
      onError('Failed to send verification code. Please try again.');
    }
  }

  /// Verify the SMS code entered by the user.
  /// Returns the Firebase ID token on success, null on failure.
  ///
  /// [verificationId] From onCodeSent callback
  /// [smsCode] 6-digit code entered by user
  static Future<String?> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _signInWithCredential(credential);
    } catch (e) {
      debugPrint('SMS code verification error: $e');
      return null;
    }
  }

  /// Sign in with auto-verified credential (Android instant verify).
  /// Returns Firebase ID token.
  static Future<String?> signInWithAutoCredential(
    PhoneAuthCredential credential,
  ) async {
    return _signInWithCredential(credential);
  }

  /// Internal: sign in with credential and get Firebase ID token.
  static Future<String?> _signInWithCredential(
    PhoneAuthCredential credential,
  ) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        debugPrint('Firebase sign-in returned null user');
        return null;
      }

      // Get the Firebase ID token for Keycloak exchange
      final idToken = await user.getIdToken();
      debugPrint('🔑 Firebase ID token obtained (${idToken?.length ?? 0} chars)');
      return idToken;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase sign-in error: ${e.code} ${e.message}');
      return null;
    }
  }

  /// Get the current Firebase user's ID token (for token refresh).
  static Future<String?> getCurrentIdToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }

  /// Get the current Firebase user's phone number.
  static String? getCurrentPhoneNumber() {
    return _auth.currentUser?.phoneNumber;
  }

  /// Sign out from Firebase (called during app logout).
  static Future<void> signOut() async {
    await _auth.signOut();
    _verificationId = null;
    _forceResendingToken = null;
  }

  /// Get the last verification ID (for resend scenarios).
  static String? get lastVerificationId => _verificationId;

  /// Map Firebase error codes to user-friendly messages.
  static String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'The phone number is not valid. Please check and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'captcha-check-failed':
        return 'Security check failed. Please try again.';
      case 'missing-phone-number':
        return 'Please enter your phone number.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'operation-not-allowed':
        return 'Phone auth is not enabled. Contact support.';
      default:
        return 'Verification failed ($code). Please try again.';
    }
  }
}
