import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import 'AuthGate.dart';
import '../main.dart';

final filters = <String>{};

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  YourCurrentScreenState createState() => YourCurrentScreenState();
}

class YourCurrentScreenState extends State<ProfileView> {
  User? user = FirebaseAuth.instance.currentUser;
  final FirebaseAuth auth = FirebaseAuth.instance;

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

  Future<List> allEventNames() async {
    final firestore = FirebaseFirestore.instance;
    final userID = user?.uid;
    List<dynamic> alldata =[];
    List<dynamic> eventNames = [];

    if (userID != null) {
      final activitiesCollectionRef = firestore.collection("activities");
      final querySnapshot = await activitiesCollectionRef.get();
      for (final activityDoc in querySnapshot.docs) {
        final Map<String, dynamic> data = activityDoc.data();
        for (final key in data.keys) {
          alldata = List.from(data[key] ?? []);
          if (alldata.isNotEmpty) {
            final nameActivity = await alldata[0];
            eventNames.add(nameActivity);
          }
        }
      }
      return eventNames;
    } else {
      return eventNames;
    }
  }

  Future<bool> isUserJoined(String groupId, String groupName, String userName) async {
    final CollectionReference groupCollection = FirebaseFirestore.instance.collection('groups');
    try {
      DocumentSnapshot groupDoc =
      await groupCollection.doc(groupId).get();

      List<dynamic> members = groupDoc['members'];

      return members.contains(user!.uid + '_' + userName);
    } catch (e) {
      print('Error checking if user is joined: $e');
      // Handle the error accordingly
      return false;
    }
  }

  Future<List> disconnectActivities(String eventName, String eventCategory, String username) async {
    List<dynamic> eventList = [];
    List<dynamic> userNames = [];

    CollectionReference activitiesCollection = FirebaseFirestore.instance.collection('activities');

    try {
      final snapshot = await firestore.collection("activities").doc(eventCategory).get();

      if (snapshot.exists) {
        eventList = snapshot.data()?[eventName] ?? [];

        if (eventList.isNotEmpty && eventList.length >= 7) {
          Map<String, dynamic> users = eventList[7];

          users.forEach((userName, value) {
            if (userName == username) {
              // Toggle the value in the users map
              users[userName] = !(value ?? false);
            }
            userNames.add(userName);
          });

          // Update the eventList with the modified users map
          eventList[7] = users;

          // Update the Firestore document with the modified eventList
          await activitiesCollection.doc(eventCategory).update({
            eventName: eventList,
          });
          print("dissconnected");
        }
      }
    } catch (e) {
      print('Error disconnecting activities: $e');
      // Handle the error accordingly, e.g., show a message to the user or log it.
    }
    return eventList;
  }

  Future<void> disconnectAllEvents() async{

    List<dynamic> eventNames = await allEventNames();

    var userData = await firestore.collection('users').doc(user?.uid).get();
    var myUserName = userData["username"];

    for(int i = 0; i < eventNames.length; i++){
      await DatabaseService(uid: user!.uid).searchByName(eventNames[i]).then((snapshot) async {
        if (snapshot != null && snapshot.docs.isNotEmpty) {
          var doc = snapshot.docs.first;
          String groupId = doc['groupId'];
          String groupName = doc['groupName'];
          String category = doc['category'];

          try {
            bool isJoined = await isUserJoined(groupId, groupName, myUserName);
            if(isJoined){
              disconnectActivities(groupName,category, myUserName);
              await DatabaseService(uid: user!.uid).togglingGroupJoin(groupId, groupName, myUserName);
            }
          } catch (e) {
            print('Error adding user to the group: $e');
          }
        } else {
          print('Snapshot is null or does not contain any documents');
        }
      });
    }
  }

  void _deleteAccount(context) async {
    try {
      await disconnectAllEvents();
      await firestore.collection("users").doc(user?.uid).delete();
      // Delete the user account
      await user?.delete().then;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => AuthGate()),
      );
    } catch (e) {
      print('Error deleting account: $e');
    }
  }

  Future<bool> deleteYourLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove('isLoggedIn');
  }

  void _signOut(context) async {
    await deleteYourLogin();

    try {
      await FirebaseAuth.instance
          .signOut()
          .then((value) => print("Ausloggen erfolgreich"));

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) =>
                const AuthGate()),
      );
    } catch (e) {
      print('Error signing out Outlogggging: $e');
    }
  }

  Future<List<String>> getInterestsChip() async {
    final firestore = FirebaseFirestore.instance;
    var userID = user?.uid;
    final data = await firestore.collection("users").doc(userID).get();

    if (data.exists) {
      final activityList = data.data()!['interests'] as List<dynamic>;
      var activities = activityList.map((item) => item.toString()).toList();

      return activities;
    } else {
      return ["No Interests"];
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
            top: MediaQuery.of(context).size.height * 0.2,
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
                  future: Future.wait([
                    courseFuture,
                    universityFuture,
                    aboutMeFuture,
                    interestsFuture,
                    userNameFuture
                  ]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        var course = snapshot.data![0];
                        var university = snapshot.data![1];
                        var aboutMe = snapshot.data![2];
                        var username = snapshot.data![4];
                        return Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 60),
                              Text(
                                '$username',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontFamily: 'DINNextLTPro-Bold',
                                    fontWeight: FontWeight.bold,
                                    color: MyApp.blueMain),
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
                                      const SizedBox(width: 20),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$course',
                                            style: const TextStyle(
                                                fontSize: 18,
                                                color: MyApp.blueMain,
                                                fontFamily:
                                                    'DIN-Next-LT-Pro-Regular'),
                                          ),
                                          Text(
                                            '$university',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontFamily:
                                                    'DIN-Next-LT-Pro-Regular'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.only(right: 20.0),
                                    child: const Divider(
                                      color: MyApp.greyMedium,
                                      thickness: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Image.asset(
                                        'icons/profile_rose.png',
                                        width: 40,
                                        height: 40,
                                      ),
                                      const SizedBox(width: 20),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'About Me',
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: MyApp.blueMain,
                                                fontFamily:
                                                    'DIN-Next-LT-Pro-Regular'),
                                          ),
                                          Text(
                                            '$aboutMe',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontFamily:
                                                    'DIN-Next-LT-Pro-Regular'),
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
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: MyApp.blueMain,
                                            fontFamily:
                                                'DIN-Next-LT-Pro-Regular'),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 20),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: FutureBuilder<List<String>>(
                                          future: getInterestsChip(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return const CircularProgressIndicator();
                                            }
                                            if (snapshot.hasError) {
                                              return Text('Error: ${snapshot.error}');
                                            }
                                            List<String> interests = snapshot.data ?? ["No Interests"];
                                            return Row(
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
                                        ),
                                      ),),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      } else {
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Data not available.'),
                          ],
                        );
                      }
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
              ),
            ),
          ),
          Positioned(
            top: 80,
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
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            } else {
                              return Center(
                                child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1) : null,),
                              );
                            }
                          },
                        ) : Image.asset('assets/cliqueConnect.png', width: 100, height: 100, fit: BoxFit.cover,),
                ),
              ),
            ),
          ),
          AppBar(
            elevation: 0.0,
            backgroundColor: Color(0x2E148C),
            leading: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(005.0),
                child: Image.asset(
                  'icons/arrow_white_noBG_white.png',
                  width: 30,
                  height: 30,
                ),
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                  } else if (value == 'logout') {
                    _signOut(context);
                  } else if (value == 'delete') {
                    _deleteAccount(context);
                  } else if (value == 'Disconnect') {
                  }
                },
                icon: const Icon(
                  Icons.settings,
                  color: Colors.white,
                ),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
                ],
              ),
            ],
          )
        ],
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
      final activities =
          activityList.map((dynamic item) => item.toString()).toList();

      if (activities != null) {
        interests = activities.join(',');
      } else {
        interests = "No Interests";
      }
      return interests;
    } else {
      return "No Interests";
    }
  }
}