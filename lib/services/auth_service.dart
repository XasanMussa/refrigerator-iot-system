import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String userKey = 'user_data';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user data to SharedPreferences
      await _saveUserData(userCredential.user);

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user data to SharedPreferences
      await _saveUserData(userCredential.user);

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _clearUserData();
  }

  // Save user data to SharedPreferences
  Future<void> _saveUserData(User? user) async {
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, user.uid);
  }

  // Clear user data from SharedPreferences
  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userKey);
  }

  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(userKey);

    return userId == currentUser.uid;
  }

  // Handle Firebase Auth exceptions
  Exception _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return Exception('No user found with this email.');
        case 'wrong-password':
          return Exception('Wrong password provided.');
        case 'email-already-in-use':
          return Exception('Email is already registered.');
        case 'weak-password':
          return Exception('The password provided is too weak.');
        case 'invalid-email':
          return Exception('The email address is invalid.');
        default:
          return Exception(e.message ?? 'An unknown error occurred.');
      }
    }
    return Exception('An unexpected error occurred.');
  }
}
