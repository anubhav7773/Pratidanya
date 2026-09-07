import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    firebaseAuth: fb_auth.FirebaseAuth.instance,
    googleSignIn: GoogleSignIn(scopes: ['email']),
    supabaseClient: supa.Supabase.instance.client,
  );
});

class AuthRepository {
  final fb_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final supa.SupabaseClient _supabaseClient;

  AuthRepository({
    required fb_auth.FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required supa.SupabaseClient supabaseClient,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn,
        _supabaseClient = supabaseClient {
    _ensureSupabaseAnonHeaders();
    _firebaseAuth.authStateChanges().listen((user) {
      if (user != null && user.uid.isNotEmpty) {
        _supabaseClient.rest.headers['x-advocate-id'] = user.uid;
      } else {
        _supabaseClient.rest.headers.remove('x-advocate-id');
      }
    });
  }

  fb_auth.User? get currentFirebaseUser => _firebaseAuth.currentUser;
  Stream<fb_auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  void _ensureSupabaseAnonHeaders() {
    _supabaseClient.rest.headers['Authorization'] = 'Bearer ${AppEnvironment.supabaseAnonKey}';
    _supabaseClient.rest.headers['apikey'] = AppEnvironment.supabaseAnonKey;
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      _supabaseClient.rest.headers['x-advocate-id'] = uid;
    } else {
      _supabaseClient.rest.headers.remove('x-advocate-id');
    }
  }

  Future<void> _injectFirebaseTokenToSupabase(fb_auth.User user) async {
    _supabaseClient.rest.headers['Authorization'] = 'Bearer ${AppEnvironment.supabaseAnonKey}';
    _supabaseClient.rest.headers['apikey'] = AppEnvironment.supabaseAnonKey;
    _supabaseClient.rest.headers['x-advocate-id'] = user.uid;
  }

  Future<fb_auth.UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        throw PratidnyaAuthException(message: 'Google लॉगिन प्रक्रिया रद्द कर दी गई।');
      }

      final GoogleSignInAuthentication googleAuth = await googleAccount.authentication;
      final fb_auth.OAuthCredential credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _injectFirebaseTokenToSupabase(userCredential.user!);
      }
      return userCredential;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw PratidnyaAuthException(message: _mapFirebaseAuthError(e.code));
    } catch (e) {
      throw PratidnyaAuthException(message: 'Google प्रमाणीकरण त्रुटि: $e');
    }
  }

  Future<fb_auth.UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        await _injectFirebaseTokenToSupabase(credential.user!);
      }
      return credential;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw PratidnyaAuthException(message: _mapFirebaseAuthError(e.code));
    }
  }

  Future<fb_auth.UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        await _injectFirebaseTokenToSupabase(credential.user!);
      }
      return credential;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw PratidnyaAuthException(message: _mapFirebaseAuthError(e.code));
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    _ensureSupabaseAnonHeaders();
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'इस ईमेल के साथ कोई अधिवक्ता खाता पंजीकृत नहीं है।';
      case 'wrong-password':
        return 'दर्ज किया गया पासवर्ड अमान्य है।';
      case 'email-already-in-use':
        return 'यह ईमेल पहले से पंजीकृत है। कृपया लॉगिन करें।';
      case 'invalid-email':
        return 'अमान्य ईमेल प्रारूप।';
      case 'weak-password':
        return 'पासवर्ड कमजोर है (न्यूनतम 6 अक्षर आवश्यक)।';
      case 'network-request-failed':
        return 'इंटरनेट कनेक्शन उपलब्ध नहीं है।';
      default:
        return 'प्रमाणीकरण विफल ($code)। कृपया पुनः प्रयास करें।';
    }
  }
}

class PratidnyaAuthException implements Exception {
  final String message;
  PratidnyaAuthException({required this.message});
  @override
  String toString() => message;
}
