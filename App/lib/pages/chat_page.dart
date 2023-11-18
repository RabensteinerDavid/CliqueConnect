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


  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user
  User? get currentUser {
    return _auth.currentUser;
  }

  @override
  void initState() {
    super.initState();

    _chats = DatabaseService(uid: currentUser!.uid).getChats(widget.groupId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName, style: TextStyle(color: MyApp.blueMain)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.0,
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
      body: Container(
        // Set the background color to white
        color: Colors.white,
        child: Stack(
          children: <Widget>[
            StreamBuilder<QuerySnapshot>(
              stream: _chats,
              builder: (context, snapshot) {
                return snapshot.hasData
                    ? ListView.builder(
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
            Container(
              alignment: Alignment.bottomCenter,
              width: MediaQuery.of(context).size.width,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                color: Colors.grey[700],
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: messageEditingController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Send a message ...",
                          hintStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.0),
                    GestureDetector(
                      onTap: () {
                        _sendMessage();
                      },
                      child: Container(
                        height: 50.0,
                        width: 50.0,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Center(child: Icon(Icons.send, color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  _sendMessage() {
    if (messageEditingController.text.isNotEmpty) {
      Map<String, dynamic> chatMessageMap = {
        "message": messageEditingController.text,
        "sender": widget.userName,
        'time': DateTime.now().millisecondsSinceEpoch,
      };

      DatabaseService(uid: currentUser!.uid).sendMessage(widget.groupId, chatMessageMap);

      setState(() {
        messageEditingController.text = "";
      });
    }
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    messageEditingController.dispose();
    super.dispose();
  }
}
