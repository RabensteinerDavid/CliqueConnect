import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_clique_connect/main.dart';
import 'package:test_clique_connect/pages/chat_page.dart';

class GroupTile extends StatefulWidget {
  final String userName;
  final String groupId;
  final String groupName;

  GroupTile({
    Key? key,
    required this.userName,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  _GroupTileState createState() => _GroupTileState();
}

class _GroupTileState extends State<GroupTile> {
  late Future<String> lastMessage;
  late Future<String> recentMessager;

  @override
  void initState() {
    super.initState();
    recentMessager = recentMessageSender(widget.groupId);
    lastMessage = loadLastMessage(widget.groupId);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              groupId: widget.groupId,
              userName: widget.userName,
              groupName: widget.groupName,
            ),
          ),
        );

        if (result != null && result) {
          setState(() {
            lastMessage = loadLastMessage(widget.groupId);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
        child: ListTile(
          leading: FutureBuilder<String>(
            future: getGroupCategory(widget.groupId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircleAvatar(
                  radius: 30.0,
                  backgroundColor: MyApp.blueMain,
                  child: CircularProgressIndicator(),
                );
              } else {
                return CircleAvatar(
                  radius: 30.0,
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
          title: Text(widget.groupName, style: const TextStyle(fontFamily: 'DINNextLtPro')),
          subtitle: FutureBuilder(
            future: Future.wait([lastMessage,recentMessager]),
            builder: (context, snapshot) {
              final data = snapshot.data;
              return Text(
                data?[0]?.toString() != null && data![0].isNotEmpty
                    ? "${data[1]}: ${data[0]}"
                    : "Join the conversation as ${widget.userName}",
                style: const TextStyle(fontSize: 13.0),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              );
            },
          ),
        ),
      ),
    );
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

  Future<String> loadLastMessage(String groupId) async {
    try {
      DocumentSnapshot groupDoc = await groupCollection.doc(groupId).get();

      if (groupDoc.exists) {
        return groupDoc['recentMessage'];
      } else {
        return "";
      }
    } catch (e) {
      return "";
    }
  }

  Future<String> recentMessageSender(String groupId) async {
    try {
      DocumentSnapshot groupDoc = await groupCollection.doc(groupId).get();

      if (groupDoc.exists) {
        return groupDoc['recentMessageSender'];
      } else {
        return "";
      }
    } catch (e) {
      return "";
    }
  }
}
