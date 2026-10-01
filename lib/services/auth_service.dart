import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  
  Rx<User?> firebaseUser = Rx<User?>(null);
  GoogleSignInAccount? _googleAccount;

  static const List<String> _scopes = [
    drive.DriveApi.driveFileScope,
  ];

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    try {
      await _googleSignIn.initialize();
      if (_auth.currentUser != null) {
        _googleAccount = await _googleSignIn.attemptLightweightAuthentication();
      }
    } catch (e) {
      developer.log('Error initializing GoogleSignIn: $e', name: 'AuthService');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      _googleAccount = await _googleSignIn.authenticate();
      if (_googleAccount == null) return null; // Cancelled

      final auth = await _googleAccount!.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      developer.log('Google Sign-In Error: $e', name: 'AuthService');
      Get.snackbar('Sign-In Error', e.toString());
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {}
    await _auth.signOut();
    _googleAccount = null;
    _cachedDriveToken = null;
  }
  
  GoogleSignInAccount? get googleAccount => _googleAccount;
  
  String? _cachedDriveToken;

  Future<String?> getValidDriveAccessToken() async {
    if (_cachedDriveToken != null) return _cachedDriveToken;

    if (_googleAccount == null) {
      _googleAccount = await _googleSignIn.attemptLightweightAuthentication();
      if (_googleAccount == null) return null;
    }
    
    try {
      final authClient = _googleAccount!.authorizationClient;
      GoogleSignInClientAuthorization? authorization = 
          await authClient.authorizationForScopes(_scopes);
      authorization ??= await authClient.authorizeScopes(_scopes);
      
      _cachedDriveToken = authorization.accessToken;
      return _cachedDriveToken;
    } catch (e) {
      developer.log('Error getting drive scopes: $e', name: 'AuthService');
      return null;
    }
  }
}
