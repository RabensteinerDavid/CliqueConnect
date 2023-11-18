import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:test_clique_connect/components/AuthGate.dart';
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

  Widget noGroupWidget() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 25.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              _popupDialog(context);
            },
            child: Icon(Icons.add_circle, color: Colors.grey[700], size: 75.0),
          ),
          SizedBox(height: 20.0),
          Text(
            "You've not joined any group, tap on the 'add' icon to create a group or search for groups by tapping on the search button below.",
          ),
        ],
      ),
    );
  }

  Widget groupsList() {
    print("_groups");
    print(_groups);
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
            return noGroupWidget();
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
        print("here3");
        // Remove the listen() method, StreamBuilder will handle it
        Stream<DocumentSnapshot> groupsStream = DatabaseService(uid: _user!.uid).getUserGroups();
        groupsStream.listen((DocumentSnapshot<Object?> snapshot) {
          if (snapshot.exists) {
            // Document exists, you can access its data
            Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
            print('Document ID: ${snapshot.id}');
            print('Data: $data');
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
      drawer: buildDrawer(),
      body: groupsList(),
/*      floatingActionButton: buildFloatingActionButton(),*/
    );
  }

  PreferredSizeWidget buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: AppBar(
        title: Text(
          'Groups',
          style: TextStyle(
            color: Colors.white,
            fontSize: 27.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black87,
        elevation: 0.0,
        actions: <Widget>[
          IconButton(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            icon: Icon(Icons.search, color: Colors.white, size: 25.0),
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


  Widget buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.symmetric(vertical: 50.0),
        children: <Widget>[
          Icon(Icons.account_circle, size: 150.0, color: Colors.grey[700]),
          SizedBox(height: 15.0),
          Text(_userName, textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 7.0),
          ListTile(
            onTap: () {},
            selected: true,
            contentPadding: EdgeInsets.symmetric(
                horizontal: 20.0, vertical: 5.0),
            leading: Icon(Icons.group),
            title: Text('Groups'),
          ),
          ListTile(
            onTap: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (context) =>
                    ProfilePage(userName: _userName, email: _email),
              ));
            },
            contentPadding: EdgeInsets.symmetric(
                horizontal: 20.0, vertical: 5.0),
            leading: Icon(Icons.account_circle),
            title: Text('Profile'),
          ),
          ListTile(
            onTap: () async {
              await _auth.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthGate()),
                    (Route<dynamic> route) => false,
              );
            },
            contentPadding: EdgeInsets.symmetric(
                horizontal: 20.0, vertical: 5.0),
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
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
