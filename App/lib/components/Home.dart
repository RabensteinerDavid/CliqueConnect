import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path/path.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _usernameController = TextEditingController();
  File? _photo;
  final ImagePicker _picker = ImagePicker();
  User? user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  String _userImageUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchUserImage();
  }

  Future<void> _fetchUserImage() async {
    _userImageUrl = (await getImgUrl());
  }

  Future imgFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 0);

    setState(() {
      if (pickedFile != null) {
        _photo = File(pickedFile.path);
      } else {
        print('No img selected');
      }
    });
  }

  Future imgFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 0);
    setState(() {
      if (pickedFile != null) {
         _photo = File(pickedFile.path);

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

  Future<String> getImgUrl() async {
    var userID = user?.uid;
    String imageURL = "";

    if (userID != null) {
      final snapshot = await firestore.collection("users").doc(userID).get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final imageName = data["image_data"];

        if (imageName != null) {
          _userImageUrl = imageURL = imageName;
          print("Image Name: $imageName");
        } else {
          print("Image Name not found in the document.");
        }
      } else {
        print("Document not found for user with ID: $userID");
      }
    } else {
      print("User is not authenticated.");
    }
    return imageURL;
  }



  void _showPicker(context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Gallery'),
                onTap: () {
                  imgFromGallery();
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
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
      });
    }
    else {
      print('No Username to upload');
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
                MaterialPageRoute<ProfileScreen>(
                  builder: (context) => ProfileScreen(
                    appBar: AppBar(
                      title: const Text('User Profile'),
                    ),
                    actions: [
                      SignedOutAction((context) {
                        Navigator.of(context).pop();
                      }),
                    ],
                    children: [
                      const Divider(),
                      if (_photo != null)
                        Image.file(
                          _photo!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.fitHeight,
                        )
                      else
                        const AspectRatio(
                          aspectRatio: 1,
                          /*child: getImgUrl(),*/
                        child: ProfilePicture(
                            name: 'Aditya Dharmawan Saputra',
                            radius: 5,
                            fontsize: 5,
                            img: "https://firebasestorage.googleapis.com/v0/b/cliqueconnect-eb893.appspot.com/o/files%2Fprofile_Y9OEsvuZINelTsyB2xknxBisDu53.jpg?alt=media&token=b29b3ceb-7b70-412b-996d-a42f60a5925d"
                          )
                        ),
                    ],
                  ),
                ),
              );
            },
          )
        ],
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          children: [
              Text(
                'Welcome!',
                style: Theme.of(context).textTheme.displaySmall,
              ),
            // Display the error message if it's not null
            GestureDetector(
              onTap: () {
                _showPicker(context);
              }, child: CircleAvatar(
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
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
              ),
            ),
            ElevatedButton(
              onPressed: saveDataToFirestore,
              child: const Text('Save to Firestore'),
            ),
            const SignOutButton(),
          ],
        ),
      ),
    );
  }
}