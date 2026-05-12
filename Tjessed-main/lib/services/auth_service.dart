import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  /// Register new user and initialize database record
  Future<User?> register(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        String username = email.split('@')[0];
        await initializeUserData(user.uid, username);
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Initialize default user data in Firebase
  Future<void> initializeUserData(String uid, String username) async {
    DatabaseReference ref = _db.ref('Accounts/$uid');
    await ref.set({
      "DOB": "01/01/2010",
      "Elo": 1500,
      "Matches Lost": 0,
      "Matches Played": 0,
      "Matches Won": 0,
      "Username": username,
      "Stats": {
        "PowerupsUsed": 0,
      }
    });
  }
}
