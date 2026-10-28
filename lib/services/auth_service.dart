import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../models/user_model.dart';
import '../models/gym_model.dart';
import '../core/utils/secure_logger.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// Call once at app startup (after Firebase.initializeApp)
  Future<void> initGoogleSignIn() async {
    await _googleSignIn.initialize(
      clientId: 'dummy-client-id.apps.googleusercontent.com',
    );
  }

  /// Fetch user profile from Firestore
  Future<UserModel?> _fetchUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!, doc.id);
      }
    } catch (e) {
      SecureLogger.logError('Error fetching user profile', e);
    }
    return null;
  }

  // ─── Sign In ─────────────────────────────────────────────────────────────────
  Future<dynamic> signIn({
    required String email,
    required String password,
    bool isOwnerLogin = false,
  }) async {
    try {
      debugPrint('[AUTH] Attempting sign-in for: $email (isOwnerLogin: $isOwnerLogin)');
      final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        debugPrint('[AUTH] Sign-in returned null user');
        return 'Authentication failed.';
      }
      debugPrint('[AUTH] Firebase Auth SUCCESS — uid: ${user.uid}');

      UserModel? userProfile = await _fetchUserProfile(user.uid);
      debugPrint('[AUTH] Firestore profile fetch: ${userProfile != null ? 'FOUND (role: ${userProfile.role})' : 'NOT FOUND'}');
      
      // If this is the super admin email, ensure the role is correct
      // (handles Firestore doc ID mismatch or seeder overwrite issues)
      if (email.toLowerCase() == 'superadmin@gymvibe.com') {
        debugPrint('[AUTH] Super admin email detected — forcing role override');
        if (userProfile != null && userProfile.role != 'super_admin') {
          // Override the role from the fetched profile
          userProfile = UserModel(
            id: user.uid,
            name: userProfile.name,
            email: userProfile.email,
            avatarUrl: userProfile.avatarUrl,
            location: userProfile.location,
            role: 'super_admin',
          );
          // Also fix the Firestore document for future logins
          try {
            await _firestore.collection('users').doc(user.uid).update({'role': 'super_admin'});
            debugPrint('[AUTH] Firestore role updated to super_admin');
          } catch (_) {}
        } else {
          userProfile ??= UserModel(
            id: user.uid,
            name: 'Super Admin',
            email: email,
            avatarUrl: 'https://i.pravatar.cc/150?img=11',
            location: 'System',
            role: 'super_admin',
          );
        }
      }
      
      if (userProfile == null) {
        debugPrint('[AUTH] No profile found — returning error');
        return 'User profile not found in database.';
      }

      // Check account status
      if (userProfile.accountStatus == 'suspended') {
        await _firebaseAuth.signOut();
        return 'This account has been suspended. Contact support.';
      }
      if (userProfile.accountStatus == 'deactivated') {
        await _firebaseAuth.signOut();
        return 'This account has been deactivated.';
      }

      // Super admin can log in from any login screen
      if (userProfile.isSuperAdmin) {
        _currentUser = userProfile;
        debugPrint('[AUTH] Super admin login SUCCESS — routing to admin portal');
        // Update last login (catch error if document doesn't exist due to security rules)
        try {
          await _firestore.collection('users').doc(user.uid).update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
        return _currentUser;
      }

      if (isOwnerLogin && !userProfile.isOwner) {
        await _firebaseAuth.signOut();
        return 'This account is not registered as a Gym Owner.';
      }

      // Update last login
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      _currentUser = userProfile;
      debugPrint('[AUTH] Login SUCCESS — role: ${userProfile.role}');
      return _currentUser;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AUTH] FirebaseAuthException: code=${e.code}, message=${e.message}');
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Invalid email or password.';
      }
      return e.message ?? 'An error occurred during sign in.';
    } catch (e) {
      debugPrint('[AUTH] Unexpected error: $e');
      SecureLogger.logError('Sign in error', e);
      return 'An unexpected error occurred.';
    }
  }

  // ─── Google Sign In ──────────────────────────────────────────────────────────
  Future<UserModel?> signInWithGoogle({bool isOwnerLogin = false}) async {
    try {
      // google_sign_in v7 API: authenticate() returns non-nullable GoogleSignInAccount
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // Get the ID token from the authentication getter
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Build Firebase credential from the Google ID token
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception('Authentication failed.');

      UserModel? userProfile = await _fetchUserProfile(user.uid);

      // Auto-register if profile doesn't exist yet
      if (userProfile == null) {
        userProfile = UserModel(
          id: user.uid,
          name: user.displayName ?? 'Google User',
          email: user.email ?? '',
          avatarUrl: user.photoURL ?? 'https://i.pravatar.cc/150?img=15',
          location: 'Davao City',
          membershipType: 'Free',
          role: 'gym_seeker',
        );
        await _firestore.collection('users').doc(user.uid).set(userProfile.toJson());
      }

      if (isOwnerLogin && !userProfile.isOwner) {
        await signOut();
        throw Exception('This account is not registered as a Gym Owner.');
      }

      _currentUser = userProfile;
      return _currentUser;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Google sign in was cancelled.');
      }
      SecureLogger.logError('Google Sign In Error', e);
      throw Exception('Failed to sign in with Google. Please try again.');
    } catch (e) {
      SecureLogger.logError('Google Sign In Error', e);
      throw Exception('Failed to sign in with Google. Please try again.');
    }
  }

  // ─── Facebook Sign In ────────────────────────────────────────────────────────
  Future<UserModel?> signInWithFacebook({bool isOwnerLogin = false}) async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == LoginStatus.success) {
        // Create a credential from the access token
        final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);

        // Sign in to Firebase with the Facebook credential
        final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
        final user = userCredential.user;
        
        if (user == null) throw Exception('Authentication failed.');

        UserModel? userProfile = await _fetchUserProfile(user.uid);

        // Auto-register if profile doesn't exist yet
        if (userProfile == null) {
          // You can also fetch user data from Facebook directly, but Firebase provides the basics
          userProfile = UserModel(
            id: user.uid,
            name: user.displayName ?? 'Facebook User',
            email: user.email ?? '',
            avatarUrl: user.photoURL ?? 'https://i.pravatar.cc/150?img=15',
            location: 'Davao City',
            membershipType: 'Free',
            role: 'gym_seeker',
          );
          await _firestore.collection('users').doc(user.uid).set(userProfile.toJson());
        }

        if (isOwnerLogin && !userProfile.isOwner) {
          await signOut();
          throw Exception('This account is not registered as a Gym Owner.');
        }

        _currentUser = userProfile;
        return _currentUser;
      } else if (result.status == LoginStatus.cancelled) {
        throw Exception('Facebook sign in was cancelled.');
      } else {
        throw Exception(result.message ?? 'An error occurred during Facebook sign in.');
      }
    } catch (e) {
      SecureLogger.logError('Facebook Sign In Error', e);
      throw Exception('Failed to sign in with Facebook. Please try again.');
    }
  }

  // ─── Register ────────────────────────────────────────────────────────────────
  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    bool isOwner = false,
    String? gymName,
  }) async {
    try {
      final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Registration failed.');

      // Create new user model
      final newUser = UserModel(
        id: user.uid,
        name: name,
        email: email,
        avatarUrl: 'https://i.pravatar.cc/150?img=15', // Default avatar
        location: 'Davao City', // Default location
        membershipType: 'Free',
        role: isOwner ? 'gym_owner' : 'gym_seeker',
        gymName: gymName,
      );

      // Save to Firestore
      await _firestore.collection('users').doc(user.uid).set(newUser.toJson());

      // If user is an owner, create their initial Gym profile
      if (isOwner && gymName != null && gymName.isNotEmpty) {
        final gymRef = _firestore.collection('gyms').doc();
        final newGym = GymModel(
          id: gymRef.id,
          ownerId: user.uid,
          name: gymName,
          imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1470&auto=format&fit=crop',
          address: 'Update Address',
          city: 'Davao City',
          hours: '6:00 AM - 10:00 PM',
          rating: 0.0,
          reviewCount: 0,
          memberCount: 0,
          bookingsCount: 0,
          isOpen: true,
        );
        await gymRef.set(newGym.toJson());
      }

      _currentUser = newUser;
      return _currentUser;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('An account with this email already exists.');
      } else if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      }
      throw Exception(e.message ?? 'An error occurred during registration.');
    }
  }

  // ─── Sign Out ────────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
    
    try {
      await _googleSignIn.signOut().timeout(const Duration(seconds: 2));
    } catch (_) {}
    
    try {
      await FacebookAuth.instance.logOut().timeout(const Duration(seconds: 2));
    } catch (_) {}
    
    _currentUser = null;
  }

  // ─── Reset Password ──────────────────────────────────────────────────────────
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No account found for this email.');
      }
      throw Exception(e.message ?? 'Failed to send reset email.');
    }
  }

  // ─── Update Profile ──────────────────────────────────────────────────────────
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
    // Reload local model
    _currentUser = await _fetchUserProfile(uid);
  }

  // ─── Delete Account ──────────────────────────────────────────────────────────
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
      _currentUser = null;
    }
  }
}
