import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../widgets/message_tile.dart';
import '../main.dart';

class ChatPage extends StatefulWidget {
  final String groupId;
  final String userName;
  final String groupName;

  ChatPage({
    required this.groupId,
    required this.userName,
    required this.groupName,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Stream<QuerySnapshot> _chats;
  TextEditingController messageEditingController = TextEditingController();
  ScrollController _scrollController = ScrollController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user
  User? get currentUser {
    return _auth.currentUser;
  }

  @override
  void initState() {
    super.initState();

    _chats = DatabaseService(uid: currentUser!.uid).getChats(widget.groupId);

    // Add a post-frame callback to scroll to the bottom after the widgets are built
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 1),
          curve: Curves.easeOut,
        );
      });
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName, style: const TextStyle(color: MyApp.blueMain, fontFamily: "DINNextLtPro",)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.0,
        actions: [
          GestureDetector(
            onTap: () {
            },
            child:Padding(
              padding: const EdgeInsets.only(right: 20.0), // Adjust the padding as needed
              child: FutureBuilder<String>(
                future: getGroupCategory(widget.groupId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // If the Future is still running, you can return a placeholder or loading image
                    return const CircleAvatar(
                      radius: 25.0,
                      backgroundColor: MyApp.blueMain,
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    return CircleAvatar(
                      radius: 25.0,
                      backgroundColor: MyApp.blueMain,
                      child: Image.asset(
                        getCategoryPic(snapshot.data ?? ""),
                        fit: BoxFit.cover,
                        width: 56.0,
                        height: 56.0,
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
        // Add a line at the bottom of the AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: 1.0, // Adjust the height to change the width of the line
            color: Colors.grey.withOpacity(0.5), // Adjust opacity and color
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Expanded(
                flex: 1, // 70% height
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 120.0),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _chats,
                    builder: (context, snapshot) {
                      return snapshot.hasData
                          ? ListView.builder(
                        shrinkWrap: true,
                        controller: _scrollController,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          return MessageTile(
                            message: snapshot.data!.docs[index]['message'],
                            sender: snapshot.data!.docs[index]['sender'],
                            sentByMe: widget.userName ==
                                snapshot.data!.docs[index]['sender'],
                          );
                        },
                      )
                          : Container();
                    },
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 40, // Adjust this value to move it higher or lower
            left: 30,
            right: 30,
            child: Container(
              width: MediaQuery.of(context).size.width, // Adjust the width as needed
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, -2), // Negative offset to move it up
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageEditingController,
                      style: TextStyle(color: Colors.black,  fontFamily: "DINNextLtPro"),
                      decoration: const InputDecoration(
                        hintText: "Send a message ...",
                        hintStyle: TextStyle(
                          fontFamily: "DINNextLtPro",
                          color: Colors.black54,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  GestureDetector(
                    onTap: () {
                      _sendMessage();
                    },
                    child: Container(
                      height: 30.0,
                      width: 30.0,
                      child: Image.asset(
                        "icons/send_blue.png", // Replace with your image asset path
                        width: 30, // Adjust width as needed
                        height: 30, // Adjust height as needed
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }




  _sendMessage() async {
    if (messageEditingController.text.isNotEmpty) {
      Map<String, dynamic> chatMessageMap = {
        "message": messageEditingController.text,
        "sender": widget.userName,
        'time': DateTime.now().millisecondsSinceEpoch,
      };

      DatabaseService(uid: currentUser!.uid).sendMessage(widget.groupId, chatMessageMap);

      // Wait for a short duration to ensure the message is added before scrolling
      await Future.delayed(const Duration(milliseconds: 100));

      // Scroll to the bottom after sending a message
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

      setState(() {
        messageEditingController.text = "";
      });
    }
  }

  String getCategoryPic(String category) {
    switch (category) {
      case 'Creative':
        return "assets/creative_noStory.png";
      case 'Sports':
        return "assets/sports_noStory.png";
      case 'Games':
        return "assets/gaming_noStory.png";
      case 'Education':
        return "assets/education_noStory.png";
      case 'Nightlife':
        return "assets/nightLife_noStory.png";
      case 'Culinary':
        return "assets/culinary_noStory.png";
      case 'Off Topic':
        return "assets/offTopic_noStory.png";
      case 'Archives':
        return "assets/archive_noStory.png";
      default:
        return "assets/offTopic_noStory.png";
    }
  }

  final CollectionReference groupCollection = FirebaseFirestore.instance.collection('groups');

  Future<String> getGroupCategory(String groupId) async {
    try {
      DocumentSnapshot groupDoc = await groupCollection.doc(groupId).get();

      if (groupDoc.exists) {
        return groupDoc['category'];
      } else {
        return "";
      }
    } catch (e) {
      return "";
    }
  }



  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    messageEditingController.dispose();
    super.dispose();
  }
}
