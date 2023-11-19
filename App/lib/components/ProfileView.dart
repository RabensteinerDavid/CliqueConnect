import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';


import '../main.dart';

final filters = <String>{};
User? user = FirebaseAuth.instance.currentUser;

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  _YourCurrentScreenState createState() => _YourCurrentScreenState();
}

class _YourCurrentScreenState extends State<ProfileView> {
  final FirebaseAuth auth = FirebaseAuth.instance;

  final firestore = FirebaseFirestore.instance;
  static String imageURL = '';
  late Future<String> userNameFuture;
  late Future<String> courseFuture;
  late Future<String> universityFuture;
  late Future<String> aboutMeFuture;
  late Future<String> interestsFuture;
  late Future<bool> imageUrlFuture;


  @override
  void initState() {
    super.initState();
    imageUrlFuture = getImgUrl();
    userNameFuture = getUserName();
    courseFuture = getCourse();
    universityFuture = getUniversity();
    aboutMeFuture = getAboutMeText();
    interestsFuture = getInterests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: MyApp.blueMain,
          ),
          Positioned(
            top: 80, // Adjust the top position as needed
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: const Color(0xff8179b4),
                child: ClipOval(
                  child: imageURL.isNotEmpty
                      ? Image.network(
                    imageURL,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                      : Image.asset(
                    'assets/cliqueConnect.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2, // Adjust the top position as needed
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.8,
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                ),
                child: FutureBuilder(
                  // Use a List or Tuple to combine multiple futures
                  future: Future.wait([courseFuture, universityFuture, aboutMeFuture, interestsFuture, imageUrlFuture, userNameFuture]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        // Extract data from the snapshot
                        var course = snapshot.data![0];
                        var university = snapshot.data![1];
                        var aboutMe = snapshot.data![2];
                        var interests = snapshot.data![3] as String; // Change this line
                        var imageUrl = snapshot.data![4];
                        var username = snapshot.data![5];

                        return Padding (
                            padding: EdgeInsets.only(left: 20), // Adjust the left padding as needed
                    child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 60),
                             Text(
                              '$username',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Image.asset(
                                      'icons/hat_rose.png',
                                      width: 40,
                                      height: 40,
                                    ),
                                    const SizedBox(width: 20), // Adjust the spacing as needed
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$course',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: MyApp.blueMain,
                                          ),
                                        ),
                                        Text(
                                          '$university',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20), // Adjust the vertical spacing between rows
                                Row(
                                  children: [
                                    Image.asset(
                                      'icons/profile_rose.png',
                                      width: 40,
                                      height: 40,
                                    ),
                                    const SizedBox(width: 20), // Adjust the spacing as needed
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'About Me',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: MyApp.blueMain,
                                          ),
                                        ),
                                        Text(
                                          '$aboutMe',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Text(
                                      'Interests: $interests',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        );
                      } else {
                        // Handle the case where data is not available
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Data not available.'),
                          ],
                        );
                      }
                    } else {
                      // Show a loading indicator while waiting for the Futures to complete.
                      return const CircularProgressIndicator();
                    }
                  },
                ),
              ),
            ),
          ), ],
      ),
    );
  }





  Future<bool> getImgUrl() async {
    var userID = user?.uid;

    print("userID");
    print(userID);

    if (userID != null) {
      final snapshot = await firestore.collection("users").doc(userID).get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final imageName = await data["image_data"];

        if (imageName != null) {
          imageURL = imageName;
          print("Image Name: $imageName");
          return true;
        } else {
          print("Image Name not found in the document.");
          return false;
        }
      } else {
        print("Document not found for user with ID: $userID");
        final Reference storageRef =
        FirebaseStorage.instance.ref('files/cliqueConnect.png');

        try {
          final imageUrl = await storageRef.getDownloadURL();

          if (imageUrl != null) {
            imageURL = imageUrl;
            print("Image URL: $imageUrl");
            return true;
          } else {
            print("Image URL not found.");
            return false;
          }
        } catch (e) {
          print("Error retrieving image URL: $e");
          return false;
        }
      }
    }

    return false;
  }

  Future<String> getUserName() async {
    var userID = user?.uid;
    var userName = "No Username Available";

    if (userID != null) {
      final snapshot = await firestore.collection("users").doc(userID).get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final name = data["username"];

        print(name);
        if (name != null) {
          userName = name;
        }
      }
    }
    return userName;
  }

  Future<String> getCourse() async {
    var userID = user?.uid;
    var course = "No Course Available";

    if (userID != null) {
      final snapshot = await firestore.collection("users").doc(userID).get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final userCourse = data["course"];

        print(userCourse);
        if (userCourse != null) {
          course = userCourse;
        }
      }
    }
    return course;
  }

  Future<String> getUniversity() async {
    var userID = user?.uid;
    var university = "No University Available";

    if (userID != null) {
      final snapshot = await firestore.collection("users").doc(userID).get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final userUniversity = data["universityType"];

        print(userUniversity);
        if (userUniversity != null) {
          university = userUniversity;
        }
      }
    }
    return university;
  }

  Future<String> getAboutMeText() async {
    var userID = user?.uid;
    var aboutMe = "No AboutMe-Text Available";

    if (userID != null) {
      final snapshot = await firestore.collection("users").doc(userID).get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final aboutMeText = data["about_me"];

        print(aboutMeText);
        if (aboutMeText != null) {
          aboutMe = aboutMeText;
        }
      }
    }
    return aboutMe;
  }

  Future<String> getInterests() async {
    final firestore = FirebaseFirestore.instance;
    var userID = user?.uid;
    final data = await firestore.collection("users").doc(userID).get();

    var interests = "No AboutMe-Text Available";

    if (data.exists) {
      final activityList = data.data()!['interests'] as List<dynamic>;
      final activities = activityList
          .map((dynamic item) => item.toString())
          .toList();

      if (activities != null) {
        interests = activities.join(',');
      } else {
        interests = "No Interests";
      }
      return interests;
    } else {
      return "No Interests"; // Add a default return statement
    }
  }

}