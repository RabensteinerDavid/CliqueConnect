import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:rrule/rrule.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'package:intl/intl.dart';
import '../pages/chat_page.dart';
import '../services/database_service.dart';

class Event extends StatefulWidget {
  const Event({Key? key, required this.eventCategory, required this.eventName}) : super(key: key);

  final String eventCategory;
  final String eventName;

  @override
  _EventState createState() => _EventState();
}

class _EventState extends State<Event> {

  var rrule;
  late DateTime dateTime;
  final firestore = FirebaseFirestore.instance;

  List<dynamic> eventList = [];
  Map<String, dynamic> users = {}; // Map für Benutzernamen und Status --> zum Datenbank-Schreiben (alle Benutzer des Events (true/false))
  final List<dynamic> userNames = []; // Liste für Benutzernamen --> zum Anzeigen

  double bannerHeight = 254.0;
  double bannerWidth = 400.0;

  String imageURLBanner = "";
  String title = "";
  String date = "";
  String description = "";
  String location = "";
  String secondTime = "";
  String thirdTime = "";

  bool sameDate = false;

  User? user = FirebaseAuth.instance.currentUser; // Aktueller Benutzer
  String myUserName = ""; // Benutzername des aktuellen Benutzers
  String icon = "assets/cliqueConnect.png";
  String buttonText = "Connect";
  Color buttonColor = const Color(0xFF220690);
  String groupId = "";

  @override
  void initState() {
    super.initState();
    _initializeData();
    findGroupId();
  }

  Future<void> _initializeData() async {
    imageURLBanner = await getEvent(widget.eventName, widget.eventCategory);
    _checkUserInList();
  }

  Future<void> findGroupId() async {
    var groupData = await firestore.collection('groups').get();

    groupData.docs.forEach((doc) {
      if (doc['groupName'] == widget.eventName) {
        groupId = doc['groupId'];
      }
    });
  }

  Future<void> _checkUserInList() async {
    var userData = await firestore.collection('users').doc(user?.uid).get();
    myUserName = userData["username"];

    bool isJoined = false;

    await DatabaseService(uid: user!.uid).searchByName(widget.eventName).then((snapshot) async {
      if (snapshot != null && snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;

        String groupId = doc['groupId'];
        String groupName = doc['groupName'];

        try {
          isJoined = await DatabaseService(uid: user!.uid).isUserJoined(groupId, groupName, userData["username"]);
        } catch (e) {
          print('Error adding user to the group: $e');
        }
      } else {
        print('Snapshot is null or does not contain any documents');
      }
    });

    setState(() {
      buttonText = isJoined ? "Disconnect" : "Connect";
      buttonColor =
      isJoined ? const Color(0xFFF199F2) : const Color(0xFF220690);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily:
        'DINCondensed',
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Image.network(
                    imageURLBanner,
                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) {
                        return child; // Das Bild ist geladen
                      } else if (loadingProgress.expectedTotalBytes == null) {
                        return const Center(
                          child:
                          CircularProgressIndicator(),
                        );
                      } else {
                        // Das Bild konnte nicht geladen werden, zeige einen Platzhalter
                        return Center(
                          child: Container(
                            width: bannerWidth,
                            height: bannerHeight,
                            color: Colors.grey,
                          ),
                        );
                      }
                    },
                    errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                      // Ein Fehler ist aufgetreten, zeige ebenfalls einen Platzhalter
                      return Center(
                        child: Container(
                          width: bannerWidth,
                          height: bannerHeight,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: bannerHeight,
                    left: 20,
                    child: Image.asset('assets/Event/${widget.eventCategory}.png',
                      height: 75,
                    ),
                  ),
                ],
              ),
              Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 25.0, top: 60.0, right: 40.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 32.0,
                          letterSpacing: 0.5,
                          height: 1.0
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    right: 25,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              groupId: groupId,
                              userName: myUserName,
                              groupName: widget.eventName,
                            ),
                          ),
                        );
                      },
                      child: Visibility(
                        visible: userNames.contains(myUserName),
                        child: Image.asset('icons/chat_single_grey.png', height: 30,),
                      ),
                    ),
                  ),
                ],
              ),
              rrule != null ? Padding(
                padding: const EdgeInsets.only(left: 25.0, top:10.0, right: 40.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "${rrule.byWeekDays != null ? 'When: ${rrule.byWeekDays.toString().replaceAll("{", "").replaceAll("}", "")} ${giveOutTime(sameDate)}' : "When: ${time()}"}${rrule.byMonths != null ? ' till ${_getMonthNames(rrule.byMonths)}' : ''}",
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontFamily: 'DINNextLtPro',
                    ),
                  ),
                ),
              ) : Padding(
                padding:
                const EdgeInsets.only(left: 25.0, top: 10.0, right: 40.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    date,
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontFamily: 'DINNextLtPro',
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 0.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    location,
                    style: const TextStyle(
                      fontSize: 14.0,
                      height: 1,
                      fontFamily: 'DINNextLtPro',
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.0,),
              Padding(
                padding:
                const EdgeInsets.only(left: 25.0, top: 2.0, right: 40.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    description,
                    style: const TextStyle(
                      fontSize: 17.0,
                      fontFamily: 'DINNextLtPro',
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8, width: 12),
                  Padding(
                    padding:
                    const EdgeInsets.only(left: 25.0, top: 40, right: 25.0),
                    child: Row(
                      children: [
                        const Text(
                          'Participants:',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontFamily: 'DINNextLtPro',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E148C),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 100,
                          height: 40,
                          child: FloatingActionButton(
                            heroTag: 'connectButtonHero',
                            onPressed: () {
                              if (userNames.contains(users["username"])) {
                                _countMeOut(widget.eventName);
                              } else {
                                _countMeIn(widget.eventName, widget.eventCategory);
                              }
                              setState(() {
                                buttonText = (userNames.contains(myUserName))
                                    ? "Connect"
                                    : "Disconnect";
                                buttonColor = (userNames.contains(myUserName))
                                    ? const Color(0xFF220690)
                                    : const Color(0xFFF199F2);
                              });
                            },
                            backgroundColor: buttonColor,
                            elevation: 0,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(15),
                                right: Radius.circular(15),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 4, width: 12),
                                Text(
                                  buttonText,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontFamily: "DINNextLtPro",
                                    color: buttonText == "Connect"
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: userNames.length,
                itemBuilder: (context, index) {
                  String username = userNames[index];
                  return FutureBuilder<String>(
                    future: getImageUrlForUser(username),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LinearProgressIndicator(
                          color: Color(0xFF2E148C),
                          minHeight: 0.2,
                        );
                      } else if (snapshot.hasError) {
                        return const Text('Error loading image');
                      } else {
                        String imageUrl = snapshot.data ?? '';
                        return SizedBox(
                          height: 75,
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(
                                  username,
                                  style: const TextStyle(
                                    color: Color(0xFF2E148C),
                                    fontFamily: "DINNextLtPro",
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(imageUrl),
                                ),
                              ),
                              if (index < userNames.length - 1)
                                const Divider(color: Colors.black12, thickness: 0.5),
                            ],
                          ),
                        );
                      }
                    },
                  );
                },
              )
            ],
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(context),
      ),
    );
  }

  String time(){
    return DateFormat.yMMMMd().add_jm().format(dateTime);
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    if (Platform.isIOS) {
      // iOS-specific UI
      return Row(
        children: [
          Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32.0, 125.0, 0.0, 0.0),
                  child: SizedBox(
                    width: 30.0,
                    height: 30.0,
                    child: FloatingActionButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      elevation: 0,
                      child: Image.asset('icons/arrow_white.png', width: 30, height: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (Platform.isAndroid) {
      // Android-specific UI
      return Row(
        children: [
          Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30.0, 48.0, 0.0, 0.0),
                  child: SizedBox(
                    width: 30.0,
                    height: 30.0,
                    child: FloatingActionButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      elevation: 0,
                      child: Image.asset('icons/arrow_white.png', width: 30, height: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  String giveOutTime(bool sameDate){
    String weekdaysString = rrule.byWeekDays.toString();
    List<String> weekdaysList = weekdaysString.split(', ');

    if(weekdaysList.length == 2){
      if (_formatTime(dateTime) == secondTime ){
        return "${_formatTime(dateTime)}";
      }else{
        return "${_formatTime(dateTime)} and ${secondTime}";
      }
    }else{
      if (_formatTime(dateTime) == secondTime && secondTime == thirdTime){
        return "${_formatTime(dateTime)}";
      }
      else{
        return "${_formatTime(dateTime)}, ${secondTime} and ${thirdTime}";
      }
    }
  }

  String? _getMonthNames(Set<int>? monthNumbers) {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    final List<String>? selectedMonthNames = monthNumbers?.map((monthNumber) {
      if (monthNumber >= 1 && monthNumber <= 12) {
        return monthNames[monthNumber - 1];
      } else {
        return 'Unknown';
      }
    }).toList();

    return selectedMonthNames?.join('');
  }

  Future<String> getImageUrlForUser(String username) async {
    try {
      final snapshot = await firestore
          .collection("users")
          .where('username', isEqualTo: username)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final imageName = data["image_data"];

        if (imageName != null) {
          return imageName;
        } else {
          return '';
        }
      } else {
        return '';
      }
    } catch (e) {
      print('Error retrieving image URL for user $username: $e');
      return '';
    }
  }

  void _countMeIn(String activityName, String activityCategory) async {
    try {
      CollectionReference activitiesCollection =
      FirebaseFirestore.instance.collection('activities');

      var userData = await firestore.collection('users').doc(user?.uid).get();

      // Überprüfen, ob der Benutzername bereits auf der Liste steht
      if (userNames.contains(userData["username"])) {
        // Der Benutzer ist bereits auf der Liste
        _countMeOut(activityName);
        return;
      }

      // Füge den Benutzernamen zur Liste hinzu
      users.addEntries([MapEntry(userData["username"], true)]);

      // Hier wird die Liste aktualisiert und ein neues State-Update ausgelöst
      setState(() {
        userNames.remove(userData["username"]);
        userNames.insert(0, userData["username"]);
      });

      await DatabaseService(uid: user!.uid)
          .searchByName(activityName)
          .then((snapshot) async {
        if (snapshot != null && snapshot.docs.isNotEmpty) {
          var doc = snapshot.docs.first;
          String groupId = doc['groupId'];
          String groupName =
          doc['groupName'];

          try {
            await DatabaseService(uid: user!.uid).togglingGroupJoin(groupId, groupName, userData["username"]);
            if (await DatabaseService(uid: user!.uid).isUserJoined(groupId, groupName, userData["username"])) {
              print('User is removed from the group successfully');
            } else {
              print('User added to the group successfully');
            }
          } catch (e) {
            print('Error adding user to the group: $e');
          }
        } else {
          print('Snapshot is null or does not contain any documents');
        }
      });
      await activitiesCollection.doc(widget.eventCategory).update({
        widget.eventName: eventList,
      });
    } catch (e) {
      print("Fehler beim Hinzufügen zur Datenbank: $e");
    }
  }

  void _countMeOut(String activityName) async {
    try {
      CollectionReference activitiesCollection =
      FirebaseFirestore.instance.collection('activities');

      var userData = await firestore.collection('users').doc(user?.uid).get();
      myUserName = userData["username"];

      // Überprüfen, ob der Benutzername auf der Liste steht
      if (userNames.contains(userData["username"])) {
        // Der Benutzer steht auf der Liste
        setState(() {
          userNames.remove(userData["username"]);
          users[userData["username"]] = false;
        });

        // Schreiben Sie das aktualisierte Array zurück in die Datenbank
        await activitiesCollection.doc(widget.eventCategory).update({
          widget.eventName: eventList,
        });

        await DatabaseService(uid: user!.uid).searchByName(activityName).then((snapshot) async {
          if (snapshot != null && snapshot.docs.isNotEmpty) {
            var doc = snapshot.docs.first;
            String groupId = doc['groupId'];
            String groupName = doc['groupName'];

            try {
              await DatabaseService(uid: user!.uid).togglingGroupJoin(groupId, groupName, userData["username"]);
            } catch (e) {
              print('Error adding user to the group: $e');
            }
          } else {
            print('Snapshot is null or does not contain any documents');
          }
        });
      } else {
        print("Der Benutzer steht nicht auf der Liste!");
      }
    } catch (e) {
      print("Fehler beim Aktualisieren in der Datenbank: $e");
    }
  }

  Future<String> getEvent(String eventName, String eventCategory) async {
    final snapshot = await firestore.collection("activities").doc(eventCategory).get();
    var userData = await firestore.collection('users').doc(user?.uid).get();
    myUserName = userData["username"];

    DateTime dateTimeTwo = DateTime.now();;
    DateTime dateTimeThree = DateTime.now();;

    if (snapshot.exists) {
      eventList = snapshot.data()?[eventName] ?? [];

      if (eventList.isNotEmpty) {
        title = eventList[0];
        description = eventList[1];
        Timestamp timestamp = eventList[2];
        dateTime = timestamp.toDate();
        date = _formatDateTime(dateTime);

        Map<String, dynamic> moreDates = {};
        moreDates = eventList[3];
        int i = 0;

        moreDates.forEach((date, value) {
          if(value != "noMore"){
            i++;
            value = value.toDate();
            if(i == 1){
              secondTime = _formatTime(value);
              dateTimeTwo = value;
            }
            if(i == 2){
              thirdTime = _formatTime(value);
              dateTimeThree = value;
            }
          }
        });

        if(dateTimeTwo == dateTimeThree){
          sameDate = true;
        }

        GeoPoint locationData = eventList[4];
        _convertCoordinatesToAddress(locationData);
        imageURLBanner = eventList[5];

        users = eventList[7];

        var ruleNew = "";
        if (eventList.length > 8) {
          ruleNew = await eventList[8];
          rrule = RecurrenceRule.fromString(ruleNew);
        }

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
    return imageURLBanner;
  }

  Future<void> _convertCoordinatesToAddress(GeoPoint locationData) async {
    var latitude = locationData.latitude;
    var longitude = locationData.longitude;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude,);

      if (placemarks.isNotEmpty) {
        Placemark first = placemarks.first;
        setState(() {
          location = '${first.street} ${first.locality} ${first.country}';
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
    String formattedHour = dateTime.hour.toString().padLeft(2, '0');
    String formattedMinute = dateTime.minute.toString().padLeft(2, '0');
    return '$formattedHour:$formattedMinute';
  }
}
