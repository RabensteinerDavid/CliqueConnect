import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class MessageTile extends StatefulWidget {
  final String message;
  final String sender;
  final bool sentByMe;

  const MessageTile({Key? key, required this.message, required this.sender, required this.sentByMe})
      : super(key: key);

  @override
  _MessageTileState createState() => _MessageTileState();
}

class _MessageTileState extends State<MessageTile> {
  String imageURL = '';
  late Future<bool> imageUrlFuture;

  @override
  void initState() {
    super.initState();
    imageUrlFuture = getImgUrl();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: widget.sentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(
            top: 14,
            bottom: 0,
            left: widget.sentByMe ? 0 : 24,
            right: widget.sentByMe ? 24 : 0,
          ),
          alignment: widget.sentByMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: widget.sentByMe
                ? const EdgeInsets.only(left: 30)
                : const EdgeInsets.only(right: 30),
            padding: const EdgeInsets.only(
              top: 17,
              bottom: 17,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              borderRadius: widget.sentByMe
                  ? const BorderRadius.only(
                topLeft: Radius.circular(23),
                topRight: Radius.circular(23),
                bottomLeft: Radius.circular(23),
              )
                  : const BorderRadius.only(
                topLeft: Radius.circular(23),
                topRight: Radius.circular(23),
                bottomRight: Radius.circular(23),
              ),
              color: widget.sentByMe ? MyApp.blueMain : MyApp.greyChat,
            ),
            child: Text(
              widget.message,
              textAlign: TextAlign.start,
              style: TextStyle(fontSize: 15.0, color: widget.sentByMe ? MyApp.white : MyApp.black),
            ),
          ),
        ),
        const SizedBox(height: 7.0),
        Padding(
          padding: const EdgeInsets.only(),
          child: Row(
            mainAxisAlignment: widget.sentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              const SizedBox(width: 24),
              FutureBuilder(
                future: imageUrlFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData) {
                      return CircleAvatar(
                        radius: 10,
                        backgroundColor: const Color(0xff8179b4),
                        child: ClipOval(
                          child: imageURL.isNotEmpty
                              ? Image.network(
                            imageURL,
                            width: 15,
                            height: 15,
                            fit: BoxFit.cover,
                          )
                              : Image.asset(
                            'assets/cliqueConnect.png',
                            width: 15,
                            height: 15,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }
                    // Show a loading indicator while waiting for the Futures to complete.
                    return const CircularProgressIndicator();
                  }
                  return Container(); // Return an empty container during loading.
                },
              ),
              const SizedBox(width: 8), // Add some spacing between CircleAvatar and Text
              Text(
                widget.sender.toUpperCase(),
                textAlign: TextAlign.start,
                style: const TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> getImgUrl() async {
    User? user = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;
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
        final Reference storageRef = FirebaseStorage.instance.ref('files/cliqueConnect.png');

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
}
