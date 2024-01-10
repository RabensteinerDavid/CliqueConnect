import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AuthGate.dart';

import '../main.dart';

final filters = <String>{};

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  YourCurrentScreenState createState() => YourCurrentScreenState();
}

class YourCurrentScreenState extends State<ProfileView> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  User? user = FirebaseAuth.instance.currentUser;

  final firestore = FirebaseFirestore.instance;
  static String imageURL = '';
  late Future<String> userNameFuture;
  late Future<String> courseFuture;
  late Future<String> universityFuture;
  late Future<String> aboutMeFuture;
  late Future<String> interestsFuture;
  late bool imageUrlFuture;


  @override
  void initState() {
    super.initState();
    loadPic();
    userNameFuture = getUserName();
    courseFuture = getCourse();
    universityFuture = getUniversity();
    aboutMeFuture = getAboutMeText();
    interestsFuture = getInterests();
  }

  void loadPic() async {
    imageUrlFuture = await getImgUrl();
    setState(() {});
  }

  void _deleteAccount(context) async {
    try {
      await firestore.collection("users").doc(user?.uid).delete();

      // Delete the user account
      await user?.delete();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => AuthGate()),
        // Replace AuthGate with your authentication gate screen
      );
    } catch (e) {
      print('Error deleting account: $e');
      // Handle the error, show a message, etc.
    }
  }

  Future<bool> deleteYourLogin() async {
    final prefs = await SharedPreferences.getInstance();

    // Remove the counter key-value pair from persistent storage.
    return await prefs.remove('isLoggedIn');
  }

  void _signOut(context) async {
    await deleteYourLogin();

    try {
      await FirebaseAuth.instance.signOut().then((value) => print("Ausloggen erfolgreich"));

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) =>
        const AuthGate()), // Replace with your authentication gate screen
      );
    } catch (e) {
      print('Error signing out Outlogggging: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: MyApp.blueMain,
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
                  future: Future.wait([courseFuture, universityFuture, aboutMeFuture, interestsFuture, userNameFuture]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        // Extract data from the snapshot
                        var course = snapshot.data![0];
                        var university = snapshot.data![1];
                        var aboutMe = snapshot.data![2];
                        var interests = snapshot.data![3] as String; // Change this line

                        var username = snapshot.data![4];

                        return Padding (
                          padding: const EdgeInsets.only(left: 20), // Adjust the left padding as needed
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 60),
                              Text(
                                '$username',
                                style: const TextStyle(fontSize: 20,
                                    fontFamily: 'DINNextLTPro-Bold',
                                    fontWeight: FontWeight.bold,
                                    color: MyApp.blueMain
                                ),
                              ),
                              const SizedBox(height: 40),
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
                                                fontFamily: 'DIN-Next-LT-Pro-Regular'
                                            ),
                                          ),
                                          Text(
                                            '$university',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontFamily: 'DIN-Next-LT-Pro-Regular'
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10), // Adjust the vertical spacing between rows
                                  Container(
                                    padding: const EdgeInsets.only(right: 20.0), // Ändern Sie den Abstand nach Bedarf
                                    child: const Divider(
                                      color: MyApp.greyMedium,
                                      thickness: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 10), // Adjust the vertical spacing between rows
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
                                                fontFamily: 'DIN-Next-LT-Pro-Regular'
                                            ),
                                          ),
                                          Text(
                                            '$aboutMe',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontFamily: 'DIN-Next-LT-Pro-Regular'
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  const Row(
                                    children: [
                                      Text(
                                        'Interests:',
                                        style: TextStyle(fontSize: 18, color: MyApp.blueMain, fontFamily: 'DIN-Next-LT-Pro-Regular'),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.only(right: 20.0), // Adjust the right padding as needed
                                    child: const SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: FilterChipExample(),
                                    ),
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
                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      } else {
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        );
                      }
                    },
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
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  // Handle menu item selection here
                  if (value == 'edit') {
                    // Handle "Edit Account" press
                  } else if (value == 'logout') {
                    // Handle "Log-out" press
                    _signOut(context); // Call your sign-out method
                  } else if (value == 'delete') {
                    _deleteAccount(context);
                    // Handle "Delete Account" press
                  } else if (value == 'impressum') {
                    // Handle "Impressum" press
                  }
                },
                icon: const Icon(
                  Icons.settings,
                  color: Colors.white,
                ),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit Account'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.exit_to_app),
                      title: Text('Log-out'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('Delete Account'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'impressum',
                    child: ListTile(
                      leading: Icon(Icons.info),
                      title: Text('Impressum'),
                    ),
                  ),
                ],
              ),
              // Add more action buttons as needed
            ],
          )
        ],
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

        print("imageName");
        print(imageName);

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

          print("getDownloadURL");
          print(storageRef.getDownloadURL());

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

class FilterChipExample extends StatefulWidget {
  const FilterChipExample({super.key});

  @override
  State<FilterChipExample> createState() => _FilterChipExampleState();
}

class _FilterChipExampleState extends State<FilterChipExample> {
  late User? user; // Make sure user is initialized

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  Future<List<String>> getInterests() async {
    final firestore = FirebaseFirestore.instance;
    var userID = user?.uid;
    final data = await firestore.collection("users").doc(userID).get();

    if (data.exists) {
      final activityList = data.data()!['interests'] as List<dynamic>;
      var activities = activityList.map((item) => item.toString()).toList();

      return activities;
    } else {
      return ["No Interests"]; // Add a default return statement
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: getInterests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Return a loading indicator while waiting for data
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          // Return an error message if there's an error
          return Text('Error: ${snapshot.error}');
        }

        // Extract categories from the snapshot data
        List<String> interests = snapshot.data ?? ["No Interests"];

        return Wrap(
          // Use Wrap instead of Row to handle multiple rows
          children: interests.map((String interest) {
            return Padding(
              padding: const EdgeInsets.all(4.0),
              child: FilterChip(
                label: Text(interest),
                selected: filters.contains(interest),
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      filters.add(interest);
                    } else {
                      filters.remove(interest);
                    }
                  });
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}