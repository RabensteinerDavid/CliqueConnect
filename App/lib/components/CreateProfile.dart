import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_cropper/image_cropper.dart';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path/path.dart';

import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_clique_connect/components/Home.dart';

final filters = <String>{};

Future<bool> profileIsCreated() async{
  // Load and obtain the shared preferences for this app.
  final prefs = await SharedPreferences.getInstance();

// Save the counter value to persistent storage under the 'counter' key.
  return await prefs.setBool('profileIsCreated', true);
}

class CreateProfile extends StatefulWidget {
  const CreateProfile({Key? key}) : super(key: key);

  @override
  _EventState createState() => _EventState();
}

class _EventState extends State<CreateProfile> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  File? _photo;
  final ImagePicker _picker = ImagePicker();

  User? user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  firebase_storage.FirebaseStorage storage = firebase_storage.FirebaseStorage.instance;

  //final TextEditingController coordinatesController = TextEditingController();
  var university;
  var course;
  String? selectedStudyCourse;
  String? universityType;
  TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getUniversity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Screen Title'),
      ),
      body: Material(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(46.0, 60.0, 46.0, 60.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                DropdownButtonFormField<String>(
                  value: universityType,
                  items: university != null
                      ? university.map<DropdownMenuItem<String>>(
                          (category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList()
                      : [],
                  onChanged: (value) {
                    setState(() {
                      universityType = value;
                      selectedStudyCourse = null;
                      getCourse();
                    });
                  },
                  decoration: const InputDecoration(labelText: 'University'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedStudyCourse,
                  items: course != null
                      ? course.map<DropdownMenuItem<String>>(
                          (category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList()
                      : [],
                  onChanged: (value) {
                    setState(() {
                      selectedStudyCourse = value;
                    });
                  },
                  decoration:
                  const InputDecoration(labelText: 'Course of study'),
                ),
                TextField(
                  controller: aboutController,
                  decoration: const InputDecoration(labelText: 'About You'),
                ),
                const SizedBox(height: 16.0),
                const Text(
                  "Interests",
                  style: TextStyle(
                    fontSize: 26.0, // Adjust the font size as needed
                    fontWeight: FontWeight.bold, // Apply bold style if desired
                    color: Colors.black, // Adjust the color as needed
                  ),
                ),
                const SizedBox(height: 16.0),
                const Align(
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: FilterChipExample(),
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () => savePictureToFirestore(context),
                  child: const Text('Create Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  Future _cropImage(  File? imageFile) async {
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
            IOSUiSettings(title: 'Crop',aspectRatioLockEnabled: true)
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

  Future<String?> getUniversity() async {
    try {
      final activitiesCollectionRef =
      FirebaseFirestore.instance.collection("school");
      final data = await activitiesCollectionRef.doc("data").get();

      if (data.exists) {
        setState(() {
          data.data()!.forEach((key, value) {
            university = value;
            print(university);
          });
        });
        return "Data retrieved successfully.";
      } else {
        print("Document does not exist");
        return null;
      }
    } catch (e) {
      print('Error retrieving data: $e');
      return null;
    }
  }

  Future<String?> getCourse() async {

    await getUniversity();

    try {
      final activitiesCollectionRef =
      FirebaseFirestore.instance.collection("course");
      final data = await activitiesCollectionRef.doc("data").get();

      if (data.exists) {
        setState(() {
          data.data()!.forEach((key, value) {

            if (key ==  universityType){
              print("hhere");
              print(key);
              course = value;
              print(course);
            }

          });
        });
        return "Data retrieved successfully.";
      } else {
        print("Document does not exist");
        return null;
      }
    } catch (e) {
      print('Error retrieving data: $e');
      return null;
    }
  }

  Future<void> saveUserDataToFirestore(context,String username, String imageUrl) async {
    final user = this.user;

    if (user != null && selectedStudyCourse != null && aboutController.text.isNotEmpty && filters.isNotEmpty) {

      try {
        await firestore.collection('users').doc(user.uid).set({
          'username': username,
          'image_data': imageUrl,
          'universityType':universityType,
          'course':selectedStudyCourse,
          'about_me':aboutController.text,
          'interests': filters,
        });

        nameController.clear();
        aboutController.clear();
        setState(() {
          selectedStudyCourse = null;
          universityType = null;
        });
        profileIsCreated();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));

      } catch (e) {
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(SnackBar(
          content: Text('Error saving data to Firestore: $e'),
        ));
      }
    }
  }

  void savePictureToFirestore(context) async {
    String username = nameController.text;

    if (username.isNotEmpty) {
      if (_photo != null) {
        final path = 'files/${user?.uid}/${basename(_photo!.path)}';
        final ref = firebase_storage.FirebaseStorage.instance.ref().child(path);
        var uploadTask = ref.putFile(_photo!);
        final snapshot = await uploadTask!.whenComplete(() {});
        final urlDownload = await snapshot.ref.getDownloadURL();
        //final imageUrl = await firebaseReference.getDownloadURL();
        await saveUserDataToFirestore(context, username, urlDownload);
      } else {
        print('No Photo to upload');
        await saveUserDataToFirestore(context,username, '');
      }

      // Optionally, you can reset the text input field and image after saving
      setState(() {
        nameController.clear();
        _photo = null;
      });
    }
    else {
      print('No Username to upload');
    }
  }
}

class FilterChipExample extends StatefulWidget {
  const FilterChipExample({Key? key});

  @override
  State<FilterChipExample> createState() => _FilterChipExampleState();
}

class _FilterChipExampleState extends State<FilterChipExample> {

  Future<String?> getCatergoryActivities() async {
    try {
      final activitiesCollectionRef =
      FirebaseFirestore.instance.collection("categoriesActivities");
      final data = await activitiesCollectionRef.doc("category").get();

      if (data.exists) {
        final activityList = data.data()!['activity'] as List<dynamic>;
        final activities = activityList.map((dynamic item) => item.toString()).toList();
        return activities.join(',');
      } else {
        print("Document does not exist");
        return "";
      }
    } catch (e) {
      print('Error retrieving data: $e');
      return "";
    }
  }



  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: getCatergoryActivities(),
      builder: (context, snapshot) {


        if (snapshot.hasError) {
          // Return an error message if there's an error
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          // Return an empty container if there's no data
          return Container();
        }

        // Extract categories from the snapshot data
        List<String> categories = snapshot.data!.split(',');

        return Row(
          children: categories.map((String category) {
            return Row(
              children: [
                FilterChip(
                  label: Text(category),
                  selected: filters.contains(category),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        filters.add(category);
                      } else {
                        filters.remove(category);
                      }
                    });
                  },
                ),
                SizedBox(width: 4.0), // Add the desired spacing here
              ],
            );
          }).toList(),
        );
      },
    );
  }
}


