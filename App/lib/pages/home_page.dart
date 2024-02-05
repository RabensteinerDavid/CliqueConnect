import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:test_clique_connect/components/AddEventForm.dart';
import 'package:test_clique_connect/main.dart';
import '../helper/helper_functions.dart';
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

  late StreamController<Map<String, dynamic>> _groupsController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get _groups => _groupsController.stream;

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
          IconButton(
            icon: Image.asset(
              "icons/plus_pink.png",
              width: 50.0,
              height: 50.0,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEventForm()),
              );
            },
          ),
          const SizedBox(height: 20.0),
          const Text(
            "You've not joined any group. You have to connect to be in a group",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: "DINNextLtPro",
              fontSize: 16.0,
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
                int reqIndex = snapshot.data?['groups'].length - index - 1;
                return GroupTile(userName: snapshot.data?['username'],
                    groupId: _destructureId(snapshot.data?['groups'][reqIndex]),
                    groupName: _destructureName(snapshot.data?['groups'][reqIndex]));
              },
            );
          } else {
            return noGroupWidget(context);
          }
        } else {
          return const Center(
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
        Stream<DocumentSnapshot> groupsStream = DatabaseService(uid: _user!.uid).getUserGroups();
        groupsStream.listen((DocumentSnapshot<Object?> snapshot) {
          if (snapshot.exists) {
            Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
            _groupsController.add(data);
          } else {
            print('Document does not exist');
          }
        });
      }
      await HelperFunctions.getUserEmailSharedPreference().then((value) {
        setState(() {
          _email = value!;
        });
      });
    }
  }

  String _destructureId(String res) {
    return res.substring(0, res.indexOf('_'));
  }

  String _destructureName(String res) {
    return res.substring(res.indexOf('_') + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(48.0, 15.0, 18.0, 8.0),
          ),
          Expanded(
            child: groupsList(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget buildAppBar() {
    return PreferredSize(
      preferredSize: Size(
        MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.height * 0.08,
      ),
      child: AppBar(
        title: Image.asset('assets/cliqueConnect.png', fit: BoxFit.contain, height: MediaQuery.of(context).size.height * 0.08),
        centerTitle: true,
        backgroundColor: MyApp.blueMain,
        elevation: 0.0,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
    );
  }
}
