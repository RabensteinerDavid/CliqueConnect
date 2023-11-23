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
        // Inside your MessageTile widget
        Padding(
          padding: const EdgeInsets.only(),
          child:Row(
            mainAxisAlignment: widget.sentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              const SizedBox(width: 24),
              FutureBuilder<String>(
                future: getImageUrlForUser(widget.sender),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // If the Future is still running, show a loading indicator or placeholder
                    return const SizedBox(
                      width: 24.0, // Adjust the width as needed
                      height: 24.0, // Adjust the height as needed
                      child: Text(""),
                    );
                  } else if (snapshot.hasError) {
                    // If an error occurred, show an error message or handle it accordingly
                    return const Text('Error loading image');
                  } else {
                    // If the Future is complete, build the widget with the loaded image URL
                    String imageUrl = snapshot.data ?? ''; // Use a default value if null
                    // Only build the Row if the image URL is not empty
                    if (imageUrl.isNotEmpty) {
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 6,
                            backgroundImage: NetworkImage(imageUrl),
                          ),
                          const SizedBox(width: 4), // Add spacing between CircleAvatar and sender's name
                          Text(
                            widget.sender.toUpperCase(),
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: Colors.black,
                              letterSpacing: -.1,
                            ),
                          ),
                        ],
                      );
                    } else {
                      return const SizedBox(); // Return an empty SizedBox if the image URL is empty
                    }
                  }
                },
              ),
                const SizedBox(width: 24),
            ],
          ),
        ),
      ],
    );
  }

  Future<String> getImageUrlForUser(String username) async {
    final firestore = FirebaseFirestore.instance;
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
