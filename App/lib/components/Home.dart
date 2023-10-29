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
import 'package:test_clique_connect/components/AuthGate.dart';

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

  Future _cropImage(  File? imageFile) async {
    if (imageFile != null) {
      CroppedFile? cropped = await ImageCropper().cropImage(
          sourcePath: imageFile!.path,
          aspectRatioPresets:
          [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9
          ],

          uiSettings: [
          AndroidUiSettings(
          toolbarTitle: 'Crop',
          cropGridColor: Colors.black,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false),
          IOSUiSettings(title: 'Crop')
    ]);

    if (cropped != null) {
    setState(() {
      _photo = File(cropped.path);
    });
    }
  }
  }

  Future imgFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 0);

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
    final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 0);
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
  static String imageURL = '';

void getImgUrl() async {
  var userID = user?.uid;

  if (userID != null) {
    final snapshot = await firestore.collection("users").doc(userID).get();

    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      final imageName = await data["image_data"];

      if (imageName != null) {
        imageURL = imageName;
        print("Image Name: $imageName");
      }
      else {
        print("Image Name not found in the document.");
      }
    } else {

      print("Document not found for user with ID: $userID");
      final Reference storageRef = FirebaseStorage.instance.ref('files/cliqueConnect.png');

      try {
        final imageUrl = await storageRef.getDownloadURL();

        if (imageUrl != null) {
          imageURL = imageUrl;
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
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => AuthGate()), // Replace with your authentication gate screen
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
                          // You can conditionally display a local image or a network image
             /*             if (imageURL == null)
                            Image.asset(
                            "assets/cliqueConnect.png",
                            width: 100,
                            height: 100,
                            fit: BoxFit.fitHeight,
                          )*/
                      /*    else*/
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Color(0xff8179b4),
                          child: _photo != null
                              ? ClipOval(
                            child: Image.network(
                              imageURL,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover, // Use 'cover' for best circular fit
                            ),
                          )
                              : Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle, // Use a circular shape for the container
                            ),
                            width: 100,
                            height: 100,
                            child: ClipOval(
                              child: Image.network(
                                imageURL,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover, // Use 'cover' for best circular fit
                              ),
                            ),
                          ),
                        ),

                        /* AspectRatio(
                          aspectRatio: 4,
                          child: Image.network(imageURL),
                          ),*/
                         /*ProfilePicture(
                         name: 'Aditya Dharmawan Saputra',
                         radius: 20,
                          fontsize: 1,
                          img:  imageURL),*/
                        // Other profile information widgets can be added here.
                    ],
                  ),
                ),
              );
            },
          )
        ],
        automaticallyImplyLeading: false,
      ),
 /*     floatingActionButton: FloatingActionButton(
        onPressed: () {
          _signOut();
        },
        child: Icon(Icons.logout_rounded),
        backgroundColor: Colors.green,
      ),*/
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
              child: const Text('Save Profile'),
            ),
            ElevatedButton(
              onPressed: () => _signOut(context), // Call the sign-out function with the correct context
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}