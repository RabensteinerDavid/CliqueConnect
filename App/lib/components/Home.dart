import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path/path.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_clique_connect/components/AddEventForm.dart';
import 'package:test_clique_connect/components/AnimatedMarkersMap.dart';
import 'package:test_clique_connect/components/AnimatedMarkersMap_NEW.dart';
import 'package:test_clique_connect/components/Event.dart';
import 'package:test_clique_connect/components/EventHome.dart';
import 'package:test_clique_connect/components/ProfileView.dart';
import 'AuthGate.dart';
import 'Calendar.dart';
import 'CreateProfile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _usernameController = TextEditingController();
  File? _photo;
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth auth = FirebaseAuth.instance;
  User? user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    getImgUrl();
  }

  Future<bool> deleteYourLogin() async {
    final prefs = await SharedPreferences.getInstance();

    // Remove the counter key-value pair from persistent storage.
    return await prefs.remove('isLoggedIn');
  }

  Future _cropImage(File? imageFile) async {
    if (imageFile != null) {
      CroppedFile? cropped = await ImageCropper().cropImage(
          sourcePath: imageFile!.path,
          maxHeight: 400,
          maxWidth: 400,
          aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
          aspectRatioPresets:
          [
            CropAspectRatioPreset.square,
            //CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            //CropAspectRatioPreset.ratio4x3,
            //CropAspectRatioPreset.ratio16x9
          ],

          uiSettings: [
            AndroidUiSettings(
                toolbarTitle: 'Crop',
                cropGridColor: Colors.black,
                initAspectRatio: CropAspectRatioPreset.original,
                lockAspectRatio: true),
            IOSUiSettings(title: 'Crop', aspectRatioLockEnabled: true)
          ]);

      if (cropped != null) {
        setState(() {
          _photo = File(cropped.path);
        });
      }
    }
  }

  Future imgFromGallery() async {
    final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 0);

    setState(() {
      if (pickedFile != null) {
        _photo = File(pickedFile.path);
        _cropImage(File(pickedFile.path));
      } else {
        print('No img selected');
      }
    });
  }

  Future imgFromCamera() async {
    final pickedFile = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 0);
    setState(() {
      if (pickedFile != null) {
        _photo = File(pickedFile.path);
        _cropImage(File(pickedFile.path));
      } else {
        print('No img selected');
      }
    });
  }

  Future uploadFile() async {
    if (_photo == null) {
      print('No file to upload');
      return;
    }
    final fileName = basename(_photo!.path);
    final destination = 'files/$fileName';

    try {
      final ref = storage.ref(destination);
      await ref.putFile(_photo!);
    } catch (e) {
      print('Error uploading file: $e');
    }
  }


  void getImgUrl() async {
    var userID = user?.uid;

    if (userID != null) {
      final snapshot = await firestore.collection("users").doc(userID).get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final imageName = await data["image_data"];

        if (imageName != null) {
          print("Image Name: $imageName");
        }
        else {
          print("Image Name not found in the document.");
        }
      } else {
        print("Document not found for user with ID: $userID");
        final Reference storageRef = FirebaseStorage.instance.ref(
            'files/cliqueConnect.png');

        try {
          final imageUrl = await storageRef.getDownloadURL();

          if (imageUrl != null) {
            print("Image URL: $imageUrl");
            // Now, you can use this URL to display the image in your app.
          } else {
            print("Image URL not found.");
          }
        } catch (e) {
          print("Error retrieving image URL: $e");
        }
      }
    }
  }

  void _showPicker(context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  imgFromGallery();
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  imgFromCamera();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> saveUserDataToFirestore(String username, String imageUrl) async {
    final user = this.user;

    if (user != null) {
      try {
        await firestore.collection('users').doc(user.uid).set({
          'username': username,
          'image_data': imageUrl,
        });
      } catch (e) {
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(SnackBar(
          content: Text('Error saving data to Firestore: $e'),
        ));
      }
    }
  }

  void saveDataToFirestore() async {
    String username = _usernameController.text;

    if (username.isNotEmpty) {
      if (_photo != null) {
        final path = 'files/${user?.uid}/${basename(_photo!.path)}';
        final ref = firebase_storage.FirebaseStorage.instance.ref().child(path);
        var uploadTask = ref.putFile(_photo!);
        final snapshot = await uploadTask!.whenComplete(() {});
        final urlDownload = await snapshot.ref.getDownloadURL();
        //final imageUrl = await firebaseReference.getDownloadURL();
        await saveUserDataToFirestore(username, urlDownload);
      } else {
        print('No Photo to upload');

        await saveUserDataToFirestore(username, '');
      }

      // Optionally, you can reset the text input field and image after saving
      setState(() {
        _usernameController.clear();
        _photo = null;
        getImgUrl();
      });
    }
    else {
      print('No Username to upload');
    }
  }

  void _signOut(BuildContext context) async {
    await deleteYourLogin();
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) =>
            AuthGate()), // Replace with your authentication gate screen
      );
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileView()),
              );
            },
          )
        ],
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Text(
                'Welcome!',
                style: Theme
                    .of(context)
                    .textTheme
                    .displaySmall,
              ),
              GestureDetector(
                onTap: () {
                  _showPicker(context);
                },
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Color(0xff8179b4),
                  child: _photo != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.file(
                      _photo!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.fitHeight,
                    ),
                  )
                      : Container(
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(50)),
                    width: 100,
                    height: 100,
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  // Other elements or widgets
                  const SizedBox(height: 36.0), // Add space above the TextField
                  SizedBox(
                    width: 250.0,
                    child: TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'Enter your username',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36.0), // Add space below the TextField
                  // Other elements or widgets
                ],
              ),
              ElevatedButton(
                onPressed: saveDataToFirestore,
                child: const Text('Save Profile'),
              ),
              ElevatedButton(
                onPressed: () => _signOut(context),
                child: const Text('Sign Out'),
              ),
              // Add the MapboxMap widget here
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const AnimatedMarkersMap_NEW()));
                },
                child: Text('Go to Map'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) =>
                      const Event(
                        eventName: 'Tanzen', eventCategory: 'Creative',)));
                },
                child: Text('Go to Event'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const AddEventForm()));
                },
                child: Text('Add Event'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const EventHome()));
                },
                child: Text('Go To All Events'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => CreateProfile()));
                },
                child: Text('Create Profile'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => CalendarScreen()));
                },
                child: Text('Create Calendar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}