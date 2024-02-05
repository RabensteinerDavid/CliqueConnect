import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_auth/firebase_auth.dart';
import '../helper/helper_functions.dart';
import '../models/user.dart' as custom_user;

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // create user object based on firebase_auth.User
  custom_user.User? _userFromFirebaseUser(firebase_auth.User user) {
    return (user != null) ? custom_user.User(uid: user.uid) : null;
  }

  // sign in with email and password
  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      firebase_auth.User? user = result.user;
      return _userFromFirebaseUser(user!);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // register with email and password
  Future registerWithEmailAndPassword(
      String fullName, String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      firebase_auth.User? user = result.user;

      return _userFromFirebaseUser(user!);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // sign out
  Future signOut() async {
    try {
      await HelperFunctions.saveUserLoggedInSharedPreference(false);
      await HelperFunctions.saveUserEmailSharedPreference('');
      await HelperFunctions.saveUserNameSharedPreference('');

      return await _auth.signOut().whenComplete(() async {
        print("Logged out");
        await HelperFunctions.getUserLoggedInSharedPreference().then((value) {
          print("Logged in: $value");
        });
        await HelperFunctions.getUserEmailSharedPreference().then((value) {
          print("Email: $value");
        });
        await HelperFunctions.getUserNameSharedPreference().then((value) {
          print("Full Name: $value");
        });
      });
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}
