import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';

class Event extends StatefulWidget {
  const Event({Key? key}) : super(key: key);

  @override
  _EventState createState() => _EventState(imageURL: 'events/zeichnen_banner.jpg');
}

class _EventState extends State<Event> {
  String imageURL = "";

  _EventState({required this.imageURL});

  List<dynamic> eventList = [];

  String title = "";
  String date = "";
  String description = "";
  String location = "";


  Map<String, dynamic> users = {}; // Map für Benutzernamen und Status --> zum Datenbank-Schreiben
  final List<dynamic> userNames = []; // Liste für Benutzernamen --> zum Anzeigen
  User? user = FirebaseAuth.instance.currentUser; // Aktueller Benutzer
  String myUserName = ""; // Benutzername des aktuellen Benutzers

  String icon = "assets/cliqueConnect.png";

  String activityName = "Tanzen";
  String activityCategory = "Creative";

  final firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    getEvent(activityName, activityCategory);
    getImageUrl("events/zeichnen_banner.jpg");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    imageURL,
                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) {
                        return child; // Image is loaded
                      } else if (loadingProgress.expectedTotalBytes == null) {
                        return const Center(
                          child: CircularProgressIndicator(), // Image is still loading
                        );
                      } else {
                        // Image failed to load, show placeholder
                        return Center(
                          child: Container(
                            width: 400.0, // Width of the placeholder
                            height: 254.0, // Height of the placeholder
                            color: Colors.grey, // Color of the placeholder
                          ),
                        );
                      }
                    },
                    errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                      // Error occurred while loading the image, show placeholder
                      return Center(
                        child: Container(
                          width: 400.0, // Width of the placeholder
                          height: 254.0, // Height of the placeholder
                          color: Colors.grey, // Color of the placeholder
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 200,
                    left: 20,
                    child: Container(
                      width: 100.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xff26168C),
                        border: Border.all(
                          color: Colors.white,
                          width: 3.0,
                        ),
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: AssetImage(icon), // Asset image
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(left: 40.0, top: 30.0, right: 40.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Asap Condensed',
                      fontSize: 45.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 40.0, top: 10.0, right: 40.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    date,
                    style: TextStyle(
                      fontFamily: 'Asap Condensed',
                      fontSize: 20.0,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 40.0, top: 10.0, right: 40.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Asap Condensed',
                      fontSize: 20.0,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 40.0, top: 10.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    location,
                    style: TextStyle(
                      fontFamily: 'Asap Condensed',
                      fontSize: 20.0,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'List of User Names:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Display user names in a ListView
              ListView.builder(
                shrinkWrap: true,
                itemCount: userNames.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(userNames[index]),
                  );
                },
              ),
            ],
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () {
                // Logic for navigation to the start page
                Navigator.pop(context);
              },
              child: Icon(Icons.arrow_back),
            ),
            SizedBox(height: 16.0),

            FloatingActionButton(
              onPressed: () {
                // Überprüfe, ob der Benutzername bereits auf der Liste steht
                if (userNames.contains(users["username"])) {
                  // Der Benutzer steht bereits auf der Liste, führe die Aktion für "link off" aus
                  _countMeOut();
                } else {
                  // Der Benutzer steht nicht auf der Liste, führe die Aktion für "link insert" aus
                  _countMeIn(activityName, activityCategory);
                }
              },
              child: Icon(
                (userNames.contains(myUserName))
                    ? Icons.link_off // Benutzer steht auf der Liste
                    : Icons.insert_link, // Benutzer steht nicht auf der Liste
                color: Colors.white, // Icon-Farbe festlegen
              ),
            ),

          ],
        ),
      ),
    );
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
        eventList[eventList.length - 1] = users;
        userNames.add(userData["username"]);
      });

      // Schreiben Sie das aktualisierte Array zurück in die Datenbank
      await activitiesCollection.doc(activityCategory).update({
        activityName: eventList,
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
        await activitiesCollection.doc(activityCategory).update({
          activityName: eventList,
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

  Future<String?> getImageUrl(String imagePath) async {
    try {
      final Reference storageRef = FirebaseStorage.instance.ref(imagePath);
      String imageURL = await storageRef.getDownloadURL();

      print(imageURL);
      setState(() {
        this.imageURL = imageURL;
      });
      return imageURL;
    } catch (e) {
      print('Error retrieving image URL: $e');
      return null;
    }
  }

  Future<void> getEvent(String eventName, String eventCategory) async {
    final snapshot = await firestore.collection("activities").doc(eventCategory).get();

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

        users = eventList[5];

        // Iteriere durch die Map und füge Benutzernamen hinzu, wenn der Wert true ist
        users.forEach((userName, value) {
          if (value == true) {
            userNames.add(userName);
          }
        });
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
