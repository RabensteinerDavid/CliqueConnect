import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

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
  late Future<String> courseFuture;
  late Future<String> aboutMeFuture;
  late Future<String> interestsFuture;
  late Future<bool> imageUrlFuture;


  @override
  void initState() {
    super.initState();
    imageUrlFuture = getImgUrl();
    courseFuture = getCourse();
    aboutMeFuture = getAboutMeText();
    interestsFuture = getInterests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Current Screen'),
      ),
      body: Center(
        child: FutureBuilder(
          // Use a List or Tuple to combine multiple futures
          future: Future.wait([courseFuture, aboutMeFuture, interestsFuture, imageUrlFuture]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData) {
                // Extract data from the snapshot
                var course = snapshot.data![0];
                var aboutMe = snapshot.data![1];
                var interests = snapshot.data![2] as String; // Change this line
                var imageUrl = snapshot.data![3];

                // Display the course and aboutMe in a nice way
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
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
                    const SizedBox(height: 16),
                    const Text(
                      'User Name',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Course: $course',
                      style: TextStyle(fontSize: 16),
                    ),

                    Text(
                      'About Me: $aboutMe',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Interests: $interests',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
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
    );
  }

  Future<bool> getImgUrl() async {
    var userID = user?.uid;

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