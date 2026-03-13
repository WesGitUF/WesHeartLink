import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    int? age,
    String? photoUrl,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user!;

      // Update Auth profile (name/photo)
      await user.updateDisplayName(name);
      if (photoUrl != null) await user.updatePhotoURL(photoUrl);
      await user.reload();

      // Create Firestore profile
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': user.email ?? '',
        if (age != null) 'age': age,
        if (photoUrl != null) 'photoURL': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Sign up failed.';
    }
  }



  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user!;
      await _ensureUserDoc(user);  // <-- only creates minimal doc if missing
      return user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Login failed.';
    }
  }

  Future<void> _ensureUserDoc(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        // do NOT set name/age defaults here — avoid wrong values
      });
    }
  }

  Future<void> saveUserProfile(User user, {required int age}) async {
    await _firestore.collection('users').doc(user.uid).set({
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'photoURL': user.photoURL ?? '',
      'age': age,
    }, SetOptions(merge: true)); // merge to avoid overwriting
  }

  // Facebook Sign In
  Future<User?> signInWithFacebook() async {
    // TODO: implement Facebook login
    // 1. Add flutter_facebook_auth to pubspec.yaml
    // 2. Call FacebookAuth.instance.login()
    // 3. Get credential via FacebookAuthProvider.credential(accessToken)
    // 4. Call _auth.signInWithCredential(credential)
    // 5. Call _ensureUserDoc on result
    throw UnimplementedError('Facebook login not yet implemented');
  }

  // Google Sign In
  Future<User?> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut(); // force account picker to always show
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      return null; // User canceled
    }
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    UserCredential result = await _auth.signInWithCredential(credential);
    if (result.user != null) await _ensureUserDoc(result.user!);
    return result.user;
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Auth State Changes Stream
  Stream<User?> get userChanges => _auth.authStateChanges();

  Future<void> updateProfileData(User user, {
    String? name,
    int? age,
    String? photoUrl,
  }) async {
    // Auth
    if (name != null) await user.updateDisplayName(name);
    if (photoUrl != null) await user.updatePhotoURL(photoUrl);
    await user.reload();

    // Firestore (merge)
    await _firestore.collection('users').doc(user.uid).set({
      if (name != null) 'name': name,
      if (age != null) 'age': age,
      if (photoUrl != null) 'photoURL': photoUrl,
      'email': user.email ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}