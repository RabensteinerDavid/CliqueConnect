import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HelperFunctions{

  static String sharedPreferenceUserLoggedInKey = "ISLOGGEDIN";
  static String sharedPreferenceUserNameKey = "USERNAMEKEY";
  static String sharedPreferenceUserEmailKey = "USEREMAILKEY";

  final FirebaseAuth auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  User? user = FirebaseAuth.instance.currentUser;

  static Future<bool> saveUserLoggedInSharedPreference(bool isUserLoggedIn) async{

    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setBool(sharedPreferenceUserLoggedInKey, isUserLoggedIn);
  }

  static Future<bool> saveUserNameSharedPreference(String userName) async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceUserNameKey, userName);
  }

  static Future<bool> saveUserEmailSharedPreference(String userEmail) async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceUserEmailKey, userEmail);
  }

  static Future<bool?> getUserLoggedInSharedPreference() async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getBool(sharedPreferenceUserLoggedInKey);
  }

  static Future<String?> getUserNameSharedPreference() async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceUserNameKey);
  }

  static Future<String?> getUserEmailSharedPreference() async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceUserEmailKey);
  }

  static Future<Object> getImgUrl() async {
    User? user = FirebaseAuth.instance.currentUser;
    var userID = user?.uid;
    final firestore = FirebaseFirestore.instance;

    if (userID != null) {
      final snapshot = await firestore.collection("users").doc(userID).get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final imageName = await data["image_data"];

        if (imageName != null) {
          return imageName;
        } else {
          return false;
        }
      } else {
        final Reference storageRef =
        FirebaseStorage.instance.ref('files/cliqueConnect.png');

        try {
          final imageUrl = await storageRef.getDownloadURL();

          if (imageUrl != null) {
            return imageUrl;
          } else {
            return false;
          }
        } catch (e) {
          return false;
        }
      }
    }
    return false;
  }

  static Future<Object> getUserName() async {

    User? user = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    var userID = user?.uid;
    var userName = "false";

    if (userID != null) {
      final snapshot = await firestore.collection("users").doc(userID).get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final name = data["username"];

        if (name != null) {
          userName = name;
        }
      }
    }
    return userName;
  }

  static Future<Object> getCourse() async {

    User? user = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    var userID = user?.uid;
    var course = "false";

    if (userID != null) {
      final snapshot = await firestore.collection("users").doc(userID).get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final userCourse = data["course"];

        if (userCourse != null) {
          course = userCourse;
        }
      }
    }
    return course;
  }

  static Future<Object> getUniversity() async {

    User? user = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    var userID = user?.uid;
    var university = "false";

    if (userID != null) {
      final snapshot = await firestore.collection("users").doc(userID).get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final userUniversity = data["universityType"];

        if (userUniversity != null) {
          university = userUniversity;
        }
      }
    }
    return university;
  }

  static Future<Object> getAboutMeText() async {

    User? user = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    var userID = user?.uid;
    var aboutMe = "false";

    if (userID != null) {
      final snapshot = await firestore.collection("users").doc(userID).get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final aboutMeText = data["about_me"];

        if (aboutMeText != null) {
          aboutMe = aboutMeText;
        }
      }
    }
    return aboutMe;
  }
}