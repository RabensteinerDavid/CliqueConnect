import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Event extends StatefulWidget {
  const Event({Key? key}) : super(key: key);

  @override
  _EventState createState() => _EventState(imageURL: 'events/zeichnen_banner.jpg');
}

class _EventState extends State<Event> {
  String imageURL = "";

  _EventState({required this.imageURL});

  String title = "Zeichnen";
  String date = "11.11.2023";
  String description = "Beschreibung";
  String location = "Ort";
  String icon = "assets/cliqueConnect.png";

  final firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    getEvent("Also jo", "Creativ");
    getImageUrl("events/zeichnen_banner.jpg");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
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
              padding: EdgeInsets.only(left: 40.0, top: 30.0),
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
              padding: EdgeInsets.only(left: 40.0, top: 10.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Datum: $date',
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
                  'Beschreibung: $description',
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
                  'Ort: $location',
                  style: TextStyle(
                    fontFamily: 'Asap Condensed',
                    fontSize: 20.0,
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Logic for navigation to the start page
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
    );
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
    print("Getting event--------------------------------------------------------------");
    final snapshot = await firestore.collection("activities").doc(eventCategory).get();

    print(snapshot.get(eventName));

    title = snapshot.get(eventName)[0];
    description = snapshot.get(eventName)[1];
    date= DateTime.fromMillisecondsSinceEpoch(snapshot.get(eventName)[2]).toString();
  }
}
