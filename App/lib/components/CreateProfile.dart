import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_clique_connect/main.dart';
import 'NavigationBar.dart';

final filters = <String>{};

Future<bool> profileIsCreated(bool state) async{
  User? user = FirebaseAuth.instance.currentUser;
  var userID = user?.uid;

  final prefs = await SharedPreferences.getInstance();
  return await prefs.setBool(userID!, state);
}

class CreateProfile extends StatefulWidget {
  const CreateProfile({Key? key}) : super(key: key);

  @override
  _EventState createState() => _EventState();
}

class _EventState extends State<CreateProfile> {

  final TextEditingController nameController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final firestore = FirebaseFirestore.instance;

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _aboutFocus = FocusNode();
  final FocusNode _universityFocus = FocusNode();
  final FocusNode _courseFocus = FocusNode();

  var university;
  var course;

  File? _photo;
  User? user = FirebaseAuth.instance.currentUser;
  firebase_storage.FirebaseStorage storage = firebase_storage.FirebaseStorage.instance;
  String? selectedStudyCourse;
  String? universityType;

  Color _nameLabelColor = MyApp.greyDark;
  Color _aboutLabelColor = MyApp.greyDark;
  Color _universityLabelColor = MyApp.greyDark;
  Color _courseLabelColor = MyApp.greyDark;

  @override
  void initState() {
    super.initState();
    getUniversity();
    profileIsCreated(false);
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _aboutFocus.dispose();
    _universityFocus.dispose();
    _courseFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          _nameLabelColor = MyApp.greyDark;
          _aboutLabelColor = MyApp.greyDark;
          _universityLabelColor = MyApp.greyDark;
          _courseLabelColor = MyApp.greyDark;
        });
        },
      child: Scaffold(
        body: Material(
          child: SingleChildScrollView(
            child: Stack(
                children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.3,
                  color: MyApp.blueMain,
                ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.08,
                    left: MediaQuery.of(context).size.width * 0.1,
                    right: MediaQuery.of(context).size.width * 0.1,
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.1,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/cliqueConnect.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.5 - 65),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(46.0, 20.0, 46.0, 60.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: nameController,
                              focusNode: _nameFocus,
                              onTap: () {
                                setState(() {
                                  _nameLabelColor = MyApp.blueMain;
                                  _aboutLabelColor = MyApp.greyDark;
                                  _universityLabelColor = MyApp.greyDark;
                                  _courseLabelColor = MyApp.greyDark;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Name',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                                labelStyle: TextStyle(
                                  color: _nameFocus.hasFocus ? MyApp.blueMain : _nameLabelColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20.0),
                            DropdownButtonFormField<String>(
                              value: universityType,
                              items: university != null
                                  ? university.map<DropdownMenuItem<String>>((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList() : [],
                              onChanged: (value) {
                                setState(() {
                                  universityType = value;
                                  selectedStudyCourse = null;
                                  getCourse();
                                });
                              },
                              onTap: () {
                                setState(() {
                                  _universityLabelColor = MyApp.blueMain;
                                  _nameLabelColor = MyApp.greyDark;
                                  _aboutLabelColor = MyApp.greyDark;
                                  _courseLabelColor = MyApp.greyDark;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'University',
                                hintText: 'Select your university',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                                labelStyle: TextStyle(
                                  color: _universityFocus.hasFocus ? MyApp.blueMain : _universityLabelColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20.0),
                            DropdownButtonFormField<String>(
                              value: selectedStudyCourse,
                              items: course != null
                                  ? course.map<DropdownMenuItem<String>>((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList() : [],
                              onChanged: (value) {
                                setState(() {
                                  selectedStudyCourse = value;
                                });
                              },
                              onTap: () {
                                setState(() {
                                  _courseLabelColor = MyApp.blueMain;
                                  _universityLabelColor = MyApp.greyDark;
                                  _nameLabelColor = MyApp.greyDark;
                                  _aboutLabelColor = MyApp.greyDark;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Course of study',
                                hintText: 'Select your university',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                                labelStyle: TextStyle(
                                  color: _courseFocus.hasFocus ? MyApp.blueMain : _courseLabelColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20.0),
                            TextField(
                              controller: aboutController,
                              focusNode: _aboutFocus,
                              onTap: () {
                                setState(() {
                                  _aboutLabelColor = MyApp.blueMain;
                                  _nameLabelColor = MyApp.greyDark;
                                  _universityLabelColor = MyApp.greyDark;
                                  _aboutLabelColor = MyApp.greyDark;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'About You',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                                labelStyle: TextStyle(
                                  color: _aboutFocus.hasFocus ? MyApp.blueMain : _aboutLabelColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22.0),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Interests",
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            const Align(
                              alignment: Alignment.center,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: FilterChipExample(),
                              ),
                            ),
                            const SizedBox(height: 28.0),
                            ElevatedButton(
                              onPressed: () => savePictureToFirestore(context),
                              style: ElevatedButton.styleFrom(
                                primary: MyApp.blueMain,
                                onPrimary: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                elevation: 3.0,
                              ),
                              child: const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.3 - 75,
                  left: MediaQuery.of(context).size.width * 0.5 - 80,
                  child: GestureDetector(
                    onTap: () {
                      _showPicker(context);
                    },
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: const Color(0xff8179b4),
                      child: _photo != null ? ClipRRect(
                        borderRadius: BorderRadius.circular(500),
                        child: Image.file(
                          _photo!,
                          width: 150,
                          height: 150,
                          fit: BoxFit.fitHeight,
                        ),
                      ) : Container(
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(500)),
                        width: 150,
                        height: 150,
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
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
            CropAspectRatioPreset.original,
            //CropAspectRatioPreset.ratio3x2,
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
          'groups': [],
        });

        nameController.clear();
        aboutController.clear();
        setState(() {
          selectedStudyCourse = null;
          universityType = null;
        });
        profileIsCreated(true);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BottomNavigationBarExample()));

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
        await saveUserDataToFirestore(context, username, urlDownload);
      } else {
        print('No Photo to upload');
        await saveUserDataToFirestore(context,username, '');
      }
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
        final activities = activityList
            .where((activity) => activity != 'All' && activity != 'Archive')
            .map((dynamic item) => item.toString())
            .toList();
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
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
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
                SizedBox(width: 4.0),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}