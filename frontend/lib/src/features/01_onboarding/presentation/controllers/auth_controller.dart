import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/activity_service.dart';
import '../../data/auth_repository.dart';
import '../../data/profile_repository.dart';
import '../../domain/advocate_profile.dart';

final authStateStreamProvider = StreamProvider((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

final currentAdvocateProfileProvider = FutureProvider<AdvocateProfile?>((ref) async {
  final authState = ref.watch(authStateStreamProvider);
  final user = authState.asData?.value;
  if (user == null) return null;

  final profileRepo = ref.watch(profileRepositoryProvider);
  return await profileRepo.getProfile(user.uid);
});

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    authRepository: ref.watch(authRepositoryProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
    ref: ref,
  );
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;
  final AdvocateProfileRepository _profileRepository;
  final Ref _ref;

  AuthController({
    required AuthRepository authRepository,
    required AdvocateProfileRepository profileRepository,
    required Ref ref,
  })  : _authRepository = authRepository,
        _profileRepository = profileRepository,
        _ref = ref,
        super(const AsyncValue.data(null));

  Future<void> loginWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final cred = await _authRepository.signInWithGoogle();
      _ref.invalidate(currentAdvocateProfileProvider);
      ActivityService.logActivity(
        activityType: 'AUTH_GOOGLE_LOGIN_SUCCESS',
        advocateId: cred.user?.uid,
        details: {'email': cred.user?.email},
      );
    });
  }

  Future<void> loginWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final cred = await _authRepository.signInWithEmail(email: email, password: password);
      _ref.invalidate(currentAdvocateProfileProvider);
      ActivityService.logActivity(
        activityType: 'AUTH_EMAIL_LOGIN_SUCCESS',
        advocateId: cred.user?.uid,
        details: {'email': email.trim()},
      );
    });
  }

  Future<void> signupWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final cred = await _authRepository.signUpWithEmail(email: email, password: password);
      _ref.invalidate(currentAdvocateProfileProvider);
      ActivityService.logActivity(
        activityType: 'AUTH_EMAIL_SIGNUP_SUCCESS',
        advocateId: cred.user?.uid,
        details: {'email': email.trim()},
      );
    });
  }

  Future<void> acceptDpdpConsent() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = _authRepository.currentFirebaseUser;
      if (user == null) throw Exception('उपयोगकर्ता प्रमाणीकृत नहीं है।');
      await _profileRepository.recordStatutoryConsent(
        user.uid,
        email: user.email,
        fullName: user.displayName,
      );
      _ref.invalidate(currentAdvocateProfileProvider);
    });
  }

  Future<void> saveBarProfile({
    required String fullName,
    required String barCouncilNumber,
    required String primaryCourtName,
    required String enrolledState,
    String? chamberAddress,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = _authRepository.currentFirebaseUser;
      if (user == null) throw Exception('उपयोगकर्ता प्रमाणीकृत नहीं है।');

      await _profileRepository.saveAdvocateBarProfile(
        firebaseUid: user.uid,
        email: user.email ?? '',
        fullName: fullName,
        barCouncilNumber: barCouncilNumber,
        primaryCourtName: primaryCourtName,
        enrolledState: enrolledState,
        chamberAddress: chamberAddress,
      );
      _ref.invalidate(currentAdvocateProfileProvider);
    });
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.signOut();
      _ref.invalidate(currentAdvocateProfileProvider);
    });
  }
}
