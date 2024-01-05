import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';

import '../services/database_service.dart';


//TODo: Edit the Event Page as admin button instead of connect button
//TODO: David sagen das wenn keine Richtige Adresse eingegben wird das ganze event nicht created wird
//TODO: Standartbild für Events ins richtige Format bringen

class Event extends StatefulWidget {
  const Event({Key? key, required this.eventCategory, required this.eventName})
      : super(key: key);

  final String eventCategory;
  final String eventName;

  @override
  _EventState createState() =>
      _EventState();
}

class _EventState extends State<Event> {
  String imageURLBanner= "" ;
  double bannerHeight = 254.0;
  double bannerWidth = 400.0;

  List<dynamic> eventList = [];

  String title = "";
  String date = "";
  String description = "";
  String location = "";

  Map<String, dynamic> users =
      {}; // Map für Benutzernamen und Status --> zum Datenbank-Schreiben (alle Benutzer des Events (true/false))
  final List<dynamic> userNames =
      []; // Liste für Benutzernamen --> zum Anzeigen
  User? user = FirebaseAuth.instance.currentUser; // Aktueller Benutzer
  String myUserName = ""; // Benutzername des aktuellen Benutzers

  String icon = "assets/cliqueConnect.png";
  String buttonText = "Connect";
  Color buttonColor = const Color(0xFF220690);


  final firestore = FirebaseFirestore.instance;



  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Warte darauf, dass getEvent abgeschlossen ist
    await getEvent(widget.eventName, widget.eventCategory);

    _checkUserInList();
  }

  Future<void> _checkUserInList() async {
    var userData = await firestore.collection('users').doc(user?.uid).get();
    myUserName = userData["username"];
    print("checkUserInList: userNames: $userNames + myUserName: $myUserName");
    setState(() {

      buttonText = (userNames.contains(myUserName)) ? "Disconnect" : "Connect";
      buttonColor = (userNames.contains(myUserName)) ?  Color(0xFFF199F2) : Color(0xFF220690);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily:
        'DINCondensed', // Hier die gewünschte Standard-Schriftart angeben
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [

                  Image.network(
                    //TODO: Change the default image
          imageURLBanner.isNotEmpty ? imageURLBanner : 'https://firebasestorage.googleapis.com/v0/b/cliqueconnect-eb893.appspot.com/o/files%2F3fk45j6p0cad2PzAURCTOaIGgmE2%2Fimage_cropper_C244C1D3-467C-46CB-90F1-3CBB8C862AE1-75989-00028C6D7F089556.jpg?alt=media&token=ea67af55-b058-4c1a-87fc-67de0f0ae640',
                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) {
                        return child; // Das Bild ist geladen
                      } else if (loadingProgress.expectedTotalBytes == null) {
                        return const Center(
                          child: CircularProgressIndicator(), // Das Bild wird noch geladen
                        );
                      } else {
                        // Das Bild konnte nicht geladen werden, zeige einen Platzhalter
                        return Center(
                          child: Container(
                            width: bannerWidth, // Breite des Platzhalters
                            height: bannerHeight, // Höhe des Platzhalters
                            color: Colors.grey, // Farbe des Platzhalters
                          ),
                        );
                      }
                    },
                    errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                      // Ein Fehler ist aufgetreten, zeige ebenfalls einen Platzhalter
                      return Center(
                        child: Container(
                          width: bannerWidth, // Breite des Platzhalters
                          height: bannerHeight, // Höhe des Platzhalters
                          color: Colors.grey, // Farbe des Platzhalters
                        ),
                      );
                    },
                  ),

                  Positioned(
                    top: bannerHeight+15,
                    right: 40,
                    child: GestureDetector(
                      onTap: () {
                        //TODO navigate to the stories site, if stories are available
                        // Handle button click action here
                        print("Button Clicked!");
                      },
                      child: Image.asset(
                        'assets/Event/${widget.eventCategory}.png',
                        height: 75,
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: EdgeInsets.only(left: 25.0, top: 60.0, right: 40.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 35.0,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 25.0, top: 20.0, right: 40.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    date,
                    style: const TextStyle(
                      fontSize: 17.0,
                      fontFamily: 'DINNextLtPro',
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 25.0, top: 2.0, right: 40.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    description,
                    style: const TextStyle(
                      fontSize: 17.0,
                      fontFamily: 'DINNextLtPro',
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 25.0, top: 20.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    location,
                    style: const TextStyle(
                      fontSize: 17.0,
                      fontFamily: 'DINNextLtPro',
                    ),
                  ),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8, width: 12),
                  Padding(
                    padding: EdgeInsets.only(left: 25.0, top: 40 , right: 25.0),
                    child: Row(
                      children: [
                        Text(
                          'Participants:',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontFamily: 'DINNextLtPro',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E148C),
                          ),
                        ),
                        Spacer(),
                        SizedBox(
                          width: 100,
                          height: 40,
                          child: FloatingActionButton(
                            onPressed: () {
                              if (userNames.contains(users["username"])) {
                                _countMeOut();
                              } else {
                                _countMeIn(widget.eventName, widget.eventCategory);
                              }
                              setState(() {
                                buttonText = (userNames.contains(myUserName)) ? "Connect" :  "Disconnect";
                                buttonColor = (userNames.contains(myUserName)) ? Color(0xFF220690) : Color(0xFFF199F2);
                              });
                            },

                            backgroundColor: buttonColor,
                            elevation: 0,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(15),
                                right: Radius.circular(15),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 4, width: 12),
                                Text(
                                  buttonText,
                                  style: const TextStyle(fontSize: 15, fontFamily: "DINNextLtPro"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Display user names in a ListView
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: userNames.length,
                itemBuilder: (context, index) {
                  String username = userNames[index];

                  return FutureBuilder<String>(
                    future: getImageUrlForUser(username),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return LinearProgressIndicator(color: Color(0xFF2E148C),  minHeight: 0.2,);
                      } else if (snapshot.hasError) {
                        return Text('Error loading image');
                      } else {
                        String imageUrl = snapshot.data ?? ''; // Use a default value if null
                        return SizedBox(
                          height: 75, // Adjust the height as needed
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(
                                  username,
                                  style: const TextStyle(
                                    color: Color(0xFF2E148C),
                                    fontFamily: "DINNextLtPro",
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(imageUrl),
                                ),
                              ),
                              if (index < userNames.length - 1)
                                const Divider(color: Colors.black12, thickness: 0.5),
                            ],
                          ),
                        );
                      }
                    },
                  );
                },
              )


            ],
          ),
        ),
        floatingActionButton: Row(
          children: [
            Stack(
              children: [
                // Back button upper left-corner
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(30.0, 40.0, 0.0, 0.0),
                    child: SizedBox(
                      width: 30.0,
                      height: 30.0,
                      child: FloatingActionButton(
                        onPressed: () {
                          // Logic for navigation to the start page
                          Navigator.pop(context);
                        },
                        elevation: 0,
                        child: Image.asset(
                          'icons/arrow_white.png', // Set the correct path to your image

                        ),
                      ),
                    ),
                  ),
                ),


                //connect button bottom right-corner

              ],
            ),
          ],
        ),
      ),
    );
  }



  Future<String> getImageUrlForUser(String username) async {
    try {
      final snapshot = await firestore.collection("users").where('username', isEqualTo: username).get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        final imageName = data["image_data"];

        if (imageName != null) {
          return imageName;
        } else {
          return ''; // Default image or handle accordingly
        }
      } else {
        return ''; // Default image or handle accordingly
      }
    } catch (e) {
      print('Error retrieving image URL for user $username: $e');
      return ''; // Default image or handle accordingly
    }
  }





  void _countMeIn(String activityName, String activityCategory) async {
    print("userNames: $userNames");
    print("users['username']: ${users["username"]}");

    try {
      CollectionReference activitiesCollection =
          FirebaseFirestore.instance.collection('activities');

      var userData = await firestore.collection('users').doc(user?.uid).get();
      print("Username: " + userData["username"]);

      // Überprüfen, ob der Benutzername bereits auf der Liste steht
      if (userNames.contains(userData["username"])) {
        // Der Benutzer ist bereits auf der Liste
        _countMeOut(); // Rufe hier deine Funktion auf
        return;
      }

      // Füge den Benutzernamen zur Liste hinzu
      users.addEntries([MapEntry(userData["username"], true)]);

      print(users);

      // Hier wird die Liste aktualisiert und ein neues State-Update ausgelöst
      setState(() {
        userNames.remove(userData["username"]);
        userNames.insert(0, userData["username"]);
      });

      await DatabaseService(uid: user!.uid).searchByName(activityName).then((snapshot) async {
        if (snapshot != null && snapshot.docs.isNotEmpty) {
          print("here in if");
          var doc = snapshot.docs.first; // Assuming you're interested in the first document
          String groupId = doc['groupId']; // Replace with the actual field name
          String groupName = doc['groupName']; // Replace with the actual field name
              print("Dates from user");
          print(groupId);
          print(groupName);
          print(userData["username"]);
          try {
            // Perform operations with the extracted values
            // For example, you might want to call a function with these values
            await DatabaseService(uid: user!.uid).togglingGroupJoin(groupId, groupName, userData["username"]);
            print('User added to the group successfully');
          } catch (e) {
            print('Error adding user to the group: $e');
          }
        } else {
          print('Snapshot is null or does not contain any documents');
        }
      });

      // Schreiben Sie das aktualisierte Array zurück in die Datenbank
      await activitiesCollection.doc(widget.eventCategory).update({
        widget.eventName: eventList,
      });

      // Hier kannst du weitere Aktionen durchführen, z.B. eine Erfolgsmeldung anzeigen
      print("Count me in erfolgreich!");
    } catch (e) {
      // Fehlerbehandlung, falls etwas schief geht
      print("Fehler beim Hinzufügen zur Datenbank: $e");
    }
  }

  void _countMeOut() async {
    try {
      CollectionReference activitiesCollection =
          FirebaseFirestore.instance.collection('activities');

      var userData = await firestore.collection('users').doc(user?.uid).get();
      myUserName = userData["username"];
      print("Username: " + userData["username"]);

      // Überprüfen, ob der Benutzername auf der Liste steht
      if (userNames.contains(userData["username"])) {
        // Der Benutzer steht auf der Liste
        setState(() {
          userNames.remove(userData["username"]);
          users[userData["username"]] = false;
        });

        // Schreiben Sie das aktualisierte Array zurück in die Datenbank
        await activitiesCollection.doc(widget.eventCategory).update({
          widget.eventName: eventList,
        });

        // Hier kannst du weitere Aktionen durchführen, z.B. eine Erfolgsmeldung anzeigen
        print("Count me out erfolgreich!");
      } else {
        print("Der Benutzer steht nicht auf der Liste!");
      }
    } catch (e) {
      // Fehlerbehandlung, falls etwas schief geht
      print("Fehler beim Aktualisieren in der Datenbank: $e");
    }
  }

  Future<void> getEvent(String eventName, String eventCategory) async {
    final snapshot = await firestore.collection("activities").doc(eventCategory).get();
    var userData = await firestore.collection('users').doc(user?.uid).get();
    myUserName = userData["username"];

    if (snapshot.exists) {
      eventList = snapshot.data()?[eventName] ?? [];
      print(eventList);

      if (eventList.isNotEmpty) {
        title = eventList[0];
        description = eventList[1];
        Timestamp timestamp = eventList[2];
        DateTime dateTime = timestamp.toDate();
        date = _formatDateTime(dateTime);

        GeoPoint locationData = eventList[4];
        _convertCoordinatesToAddress(locationData);
        this.imageURLBanner=eventList[5];
        print("This is a imageBanner: "+imageURLBanner);



        users = eventList[7];

        // Iteriere durch die Map und füge Benutzernamen hinzu, wenn der Wert true ist
        users.forEach((userName, value) {
          if (value == true) {
            userNames.add(userName);


          }

        });
        print("userNames: $userNames + myUserName: $myUserName");
      }
    } else {
      print("Document does not exist");
    }
  }

  Future<void> _convertCoordinatesToAddress(GeoPoint locationData) async {
    var latitude = locationData.latitude;
    var longitude = locationData.longitude;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark first = placemarks.first;
        setState(() {
          location = '${first.street}\n${first.locality}\n${first.country}';
        });
      } else {
        setState(() {
          location = 'No address found for the given coordinates';
        });
      }
    } catch (e) {
      setState(() {
        location = 'Error: $e';
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${_formatTime(dateTime)}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute}';
  }
}
