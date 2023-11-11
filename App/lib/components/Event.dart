import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Event extends StatefulWidget {
  const Event({Key? key}) : super(key: key);

  @override
  _EventState createState() => _EventState(imageURL: 'zeichnen_banner.jpg');
}

class _EventState extends State<Event> {
  String imageURL = "";

  _EventState({required this.imageURL});

  String title = "Zeichnen";
  String date = "11.11.2023";
  String description = "Beschreibung";
  String location = "Ort";

  @override
  void initState() {
    super.initState();
    getImageUrl("events/zeichnen_banner.jpg");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.network(
              imageURL,
              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) {
                  return child; // Bild ist geladen
                } else if (loadingProgress.expectedTotalBytes == null) {
                  return const Center(
                    child: CircularProgressIndicator(), // Bild wird geladen
                  );
                } else {
                  return Center(
                    child: Container(
                      width: 100.0, // Breite des Platzhalters
                      height: 100.0, // Höhe des Platzhalters
                      color: Colors.grey, // Farbe des Platzhalters
                    ),
                  );
                }
              },
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
            // Hier die Logik für die Navigation zur Startseite einfügen
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
}
