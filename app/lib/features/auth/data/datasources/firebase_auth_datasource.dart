import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:trash/core/constants/app_constants.dart';
import 'package:trash/core/error/failures.dart';
import 'package:trash/features/auth/data/models/auth_user_model.dart';

class FirebaseAuthDataSource {
  final fb.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthDataSource({
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  // ─── Auth State ───────────────────────────────────────────────
  Stream<AuthUserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try {
        final doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .get();
        if (doc.exists) return AuthUserModel.fromFirestore(doc);
        return AuthUserModel.fromFirebaseUser(user);
      } catch (_) {
        return AuthUserModel.fromFirebaseUser(user);
      }
    });
  }

  AuthUserModel? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return AuthUserModel.fromFirebaseUser(user);
  }

  // ─── Email Sign In ────────────────────────────────────────────
  Future<({AuthUserModel? user, Failure? failure})> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) return (user: null, failure: const AuthFailure());

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return (user: AuthUserModel.fromFirestore(doc), failure: null);
      }
      return (user: AuthUserModel.fromFirebaseUser(user), failure: null);
    } on fb.FirebaseAuthException catch (e) {
      return (user: null, failure: _mapAuthException(e));
    } catch (_) {
      return (user: null, failure: const ServerFailure());
    }
  }

  // ─── Google Sign In ───────────────────────────────────────────
  Future<({AuthUserModel? user, Failure? failure})> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return (user: null, failure: const AuthFailure('Sign in cancelled.'));
      }

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await _firebaseAuth.signInWithCredential(credential);
      final fbUser = userCredential.user;
      if (fbUser == null) return (user: null, failure: const AuthFailure());

      // Always write/merge the user document — never assume it exists correctly
      final nameParts = (fbUser.displayName ?? '').trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName =
      nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final userRef =
      _firestore.collection(AppConstants.usersCollection).doc(fbUser.uid);
      final doc = await userRef.get();

      if (!doc.exists) {
        // Brand new user — create full document
        final model = AuthUserModel(
          uid: fbUser.uid,
          email: fbUser.email ?? '',
          firstName: firstName,
          lastName: lastName,
          username: '',           // empty until they set it
          photoUrl: fbUser.photoURL,
          isEmailVerified: fbUser.emailVerified,
          createdAt: DateTime.now(),
        );
        await userRef.set(model.toFirestore());
        return (user: model, failure: null);
      } else {
        // Existing user — patch any missing fields silently
        final data = doc.data() as Map<String, dynamic>;
        final updates = <String, dynamic>{};
        if (data['coins'] == null)       updates['coins'] = 0;
        if (data['stars'] == null)       updates['stars'] = 0;
        if (data['score'] == null)       updates['score'] = 0;
        if (data['level'] == null)       updates['level'] = 1;
        if (data['totalClaims'] == null) updates['totalClaims'] = 0;
        if (data['streak'] == null)      updates['streak'] = 0;
        if (data['firstName'] == null || (data['firstName'] as String).isEmpty) {
          updates['firstName'] = firstName;
        }
        if (data['lastName'] == null || (data['lastName'] as String).isEmpty) {
          updates['lastName'] = lastName;
        }
        if (updates.isNotEmpty) {
          updates['updatedAt'] = FieldValue.serverTimestamp();
          await userRef.update(updates);
        }
        return (user: AuthUserModel.fromFirestore(doc), failure: null);
      }
    } on fb.FirebaseAuthException catch (e) {
      return (user: null, failure: _mapAuthException(e));
    } catch (e) {
      return (user: null, failure: ServerFailure(e.toString()));
    }
  }

  // ─── Email Registration ───────────────────────────────────────
  Future<({String? uid, Failure? failure})> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) return (uid: null, failure: const AuthFailure());

      // Send verification email
      await credential.user?.sendEmailVerification();

      return (uid: uid, failure: null);
    } on fb.FirebaseAuthException catch (e) {
      return (uid: null, failure: _mapAuthException(e));
    } catch (_) {
      return (uid: null, failure: const ServerFailure());
    }
  }

  // ─── Save Profile ─────────────────────────────────────────────
  Future<({bool success, Failure? failure})> saveUserProfile({
    required String uid,
    required String firstName,
    required String lastName,
    required String username,
    String? photoUrl,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      final model = AuthUserModel(
        uid: uid,
        email: user?.email ?? '',
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        username: username.trim().toLowerCase(),
        photoUrl: photoUrl ?? user?.photoURL,
        isEmailVerified: user?.emailVerified ?? false,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(model.toFirestore());

      // Update Firebase display name
      await user?.updateDisplayName('$firstName $lastName');

      return (success: true, failure: null);
    } catch (_) {
      return (success: false, failure: const ServerFailure());
    }
  }

  // ─── Username Check ───────────────────────────────────────────
  Future<({bool available, Failure? failure})> checkUsernameAvailable(
      String username) async {
    try {
      final query = await _firestore
          .collection(AppConstants.usersCollection)
          .where('username', isEqualTo: username.trim().toLowerCase())
          .limit(1)
          .get();
      return (available: query.docs.isEmpty, failure: null);
    } catch (_) {
      return (available: false, failure: const ServerFailure());
    }
  }

  // ─── OTP (Firebase email verification) ───────────────────────
  Future<({bool success, Failure? failure})> sendOtp(String email) async {
    try {
      await _firebaseAuth.currentUser?.sendEmailVerification();
      return (success: true, failure: null);
    } catch (_) {
      return (success: false, failure: const ServerFailure());
    }
  }

  Future<({bool success, Failure? failure})> verifyOtp({
    required String email,
    required String otp,
  }) async {
    // Firebase doesn't expose OTP directly; we check emailVerified after
    // user clicks the verification link. For SMS-style OTP you'd use
    // a Cloud Function. This is a placeholder for that integration.
    try {
      await _firebaseAuth.currentUser?.reload();
      final verified = _firebaseAuth.currentUser?.emailVerified ?? false;
      if (!verified) return (success: false, failure: const InvalidOtpFailure());
      return (success: true, failure: null);
    } catch (_) {
      return (success: false, failure: const ServerFailure());
    }
  }

  // ─── Password Reset ───────────────────────────────────────────
  Future<({bool success, Failure? failure})> sendPasswordResetEmail(
      String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return (success: true, failure: null);
    } on fb.FirebaseAuthException catch (e) {
      return (success: false, failure: _mapAuthException(e));
    } catch (_) {
      return (success: false, failure: const ServerFailure());
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
      _googleSignIn.disconnect() // ← ADD THIS — clears cached account completely

    ]);
  }

  // ─── Helper ───────────────────────────────────────────────────
  Failure _mapAuthException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const UserNotFoundFailure();
      case 'wrong-password':
      case 'invalid-credential':
        return const InvalidCredentialsFailure();
      case 'email-already-in-use':
        return const EmailAlreadyInUseFailure();
      case 'weak-password':
        return const WeakPasswordFailure();
      case 'invalid-email':
        return const AuthFailure('Invalid email address.');
      case 'user-disabled':
        return const AuthFailure('This account has been disabled.');
      case 'too-many-requests':
        return const AuthFailure('Too many attempts. Please try again later.');
      case 'network-request-failed':
        return const NetworkFailure();
      default:
        return AuthFailure(e.message ?? 'Authentication error.');
    }
  }
}
