import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../helper/helper_functions.dart';
import '../pages/chat_page.dart';
import '../services/database_service.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchEditingController = TextEditingController();
  late QuerySnapshot searchResultSnapshot;
  bool isLoading = false;
  bool hasUserSearched = false;
  bool _isJoined = false;
  String _userName = '';
  late User _user;

  @override
  void initState() {
    super.initState();
    _getCurrentUserNameAndUid();
  }

  _getCurrentUserNameAndUid() async {
    await HelperFunctions.getUserNameSharedPreference().then((value) {
      _userName = value!;
    });
    _user = await FirebaseAuth.instance.currentUser!;
  }

  _initiateSearch() async {
    if (searchEditingController.text.isNotEmpty) {
      setState(() {
        isLoading = true;
      });
      await DatabaseService(uid: _user.uid).searchByName(searchEditingController.text).then(
            (snapshot) {
          searchResultSnapshot = snapshot;
          setState(() {
            isLoading = false;
            hasUserSearched = true;
          });
        },
      );
    }
  }

  _joinValueInGroup(String userName, String groupId, String groupName, String admin) async {
    bool value = await DatabaseService(uid: _user.uid).isUserJoined(groupId, groupName, userName);
    setState(() {
      _isJoined = value;
    });
  }

  Widget groupList() {
    return hasUserSearched
        ? ListView.builder(
      shrinkWrap: true,
      itemCount: searchResultSnapshot.docs.length,
      itemBuilder: (context, index) {
        return groupTile(
          _userName,
          searchResultSnapshot.docs[index]['groupId'],
          searchResultSnapshot.docs[index]['groupName'],
          searchResultSnapshot.docs[index]['admin'],
        );
      },
    )
        : Container();
  }

  Widget groupTile(String userName, String groupId, String groupName, String admin) {
    _joinValueInGroup(userName, groupId, groupName, admin);
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      leading: CircleAvatar(
        radius: 30.0,
        backgroundColor: Colors.blueAccent,
        child: Text(groupName.substring(0, 1).toUpperCase(), style: TextStyle(color: Colors.white)),
      ),
      title: Text(groupName, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("Admin: $admin"),
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                groupId: groupId,
                userName: userName,
                groupName: groupName,
              ),
            ),
          );
        },
   /*   trailing: InkWell(
        onTap: () async {
          await DatabaseService(uid: _user.uid).togglingGroupJoin(groupId, groupName, userName);
          if (_isJoined) {
            setState(() {
              _isJoined = !_isJoined;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.blueAccent,
                duration: Duration(milliseconds: 1500),
                content: Text("Successfully joined the group \"$groupName\"",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17.0)),
              ),
            );
            Future.delayed(Duration(milliseconds: 2000), () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>
                    ChatPage(groupId: groupId, userName: userName, groupName: groupName),
              ));
            });
          }
*//*          else {
            setState(() {
              _isJoined = !_isJoined;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.blueAccent,
                duration: Duration(milliseconds: 1500),
                content: Text("Left the group \"$groupName\"",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17.0)),
              ),
            );
          }*//*
        },
        child: _isJoined
            ? Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: Colors.black87,
            border: Border.all(color: Colors.white, width: 1.0),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Text('Joined', style: TextStyle(color: Colors.white)),
        )
            : Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: Colors.blueAccent,
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Text('Join', style: TextStyle(color: Colors.white)),
        ),
      ),*/
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Color(0xFF2E148C),
        title: Text('Search', style: TextStyle(fontSize: 27.0, fontWeight: FontWeight.bold, color: Colors.white)),
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'icons/arrow_white_noBG_white.png', // Set the correct path to your image
              width: 30,
              height: 30,
            ),
          ),
        ),
      ),

      body: Container(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchEditingController,
                      style: TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        hintText: "Search groups...",
                        hintStyle: TextStyle(color: Colors.black, fontSize: 16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _initiateSearch();
                    },
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Color(0xFF6059F0),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Icon(Icons.search, color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
            isLoading ? Container(child: Center(child: CircularProgressIndicator())) : groupList(),
          ],
        ),
      ),
    );
  }
}
