import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:test_clique_connect/components/AuthGate.dart';
import 'package:test_clique_connect/components/EventHome.dart';
import 'package:test_clique_connect/main.dart';
import '../helper/helper_functions.dart';
import '../components/AuthGate.dart';
import '../pages/profile_page.dart';
import '../pages/search_page.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/group_tile.dart';

class HomePageChat extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePageChat> {
  final AuthService _auth = AuthService();
  User? _user;
  String _userName = '';
  String _email = '';
/*  late Stream<Map<String, dynamic>> _groups = Stream.empty();*/
  late StreamController<Map<String, dynamic>> _groupsController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get _groups => _groupsController.stream;

  late String _groupName;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    await  _getUserAuthAndJoinedGroups();
  }

  Widget noGroupWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // Add the search icon button
          IconButton(
            icon: Image.asset(
              "icons/plus_pink.png",
              width: 50.0, // Adjust the width as needed
              height: 50.0, // Adjust the height as needed
            ),
            onPressed: () {
              // Navigate to the search page when the search icon is pressed
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EventHome()), // Replace EventHome with your actual widget
              );
            },
          ),
          const SizedBox(height: 20.0),
          const Text(
            "You've not joined any group. You have to connect to be in a group",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.0, // Adjust the font size as needed
            ),
          ),
        ],
      ),
    );
  }




  Widget groupsList() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _groups,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          var groupsData = snapshot.data?['groups'];
          if (groupsData != null && groupsData.length != 0) {
            return ListView.builder(
              itemCount: snapshot.data?['groups'].length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                int reqIndex = snapshot.data?['groups'].length - index - 1; // Use groupsData instead of snapshot.data['groups']
                return GroupTile(userName: snapshot.data?['username'], groupId: _destructureId(snapshot.data?['groups'][reqIndex]), groupName: _destructureName(snapshot.data?['groups'][reqIndex]));
              },
            );
          } else {
            return noGroupWidget(context);
          }
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }




  _getUserAuthAndJoinedGroups() async {
    _user = FirebaseAuth.instance.currentUser;

    if (_user != null) {
      await HelperFunctions.getUserNameSharedPreference().then((value) {
        setState(() {
          _userName = value!;
        });
      });

      if (_user!.uid != null) {
        // Remove the listen() method, StreamBuilder will handle it
        Stream<DocumentSnapshot> groupsStream = DatabaseService(uid: _user!.uid).getUserGroups();
        groupsStream.listen((DocumentSnapshot<Object?> snapshot) {
          if (snapshot.exists) {
            // Document exists, you can access its data
            Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
            _groupsController.add(data);
          } else {
            // Document doesn't exist
            print('Document does not exist');
          }
        }

    );
      }

      await HelperFunctions.getUserEmailSharedPreference().then((value) {
        setState(() {
          _email = value!;
        });
      });
    }
  }






  String _destructureId(String res) {
    print(res.substring(0, res.indexOf('_')));
    return res.substring(0, res.indexOf('_'));
  }

  String _destructureName(String res) {
    return res.substring(res.indexOf('_') + 1);
  }

  void _popupDialog(BuildContext context) {
    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget createButton = TextButton(
      child: Text("Create"),
      onPressed: () async {
        if (_groupName != null && _user != null) {
          await HelperFunctions.getUserNameSharedPreference().then((val) {
            DatabaseService(uid: _user!.uid).createGroup(val!, _groupName);
          });
          Navigator.of(context).pop();
        } else {
          // Handle the case where _groupName or _user is null
          // You might want to show a message or handle it in a way that makes sense for your app
          print("Error: _groupName or _user is null");
        }
      },
    );


    AlertDialog alert = AlertDialog(
      title: Text("Create a group"),
      content: TextField(
        onChanged: (val) {
          _groupName = val;
        },
        style: TextStyle(
          fontSize: 15.0,
          height: 2.0,
          color: Colors.black,
        ),
      ),
      actions: [
        cancelButton,
        createButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(48.0, 46.0, 18.0, 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Messages',
                style: TextStyle(fontSize: 18.0, color: MyApp.blueMain),
              ),
            ),
          ),
          groupsList(),
        ],
      ),
      /*floatingActionButton: buildFloatingActionButton(),*/
    );
  }



  PreferredSizeWidget buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: AppBar(
       title: Image.asset('assets/cliqueConnect.png',  fit: BoxFit.contain,
         height: 50,),
        centerTitle: true, // Center the title (icon) in the middle
        backgroundColor: MyApp.blueMain,
        elevation: 0.0,
        iconTheme: const IconThemeData(color: Colors.white), // Set the color of the back arrow to white
        actions: <Widget>[
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            icon: const Icon(Icons.search, color: Colors.white, size: 25.0),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => SearchPage()),
              );
            },
          )
        ],
      ),
    );
  }



  Widget buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        _popupDialog(context);
      },
      backgroundColor: Colors.grey[700],
      elevation: 0.0,
      child: const Icon(Icons.add, color: Colors.white, size: 30.0),
    );
  }
}
