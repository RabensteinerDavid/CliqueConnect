import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:test_clique_connect/main.dart';
import 'package:test_clique_connect/pages/chat_page.dart';
import 'package:test_clique_connect/services/database_service.dart';

class GroupTile extends StatelessWidget {
  final String userName;
  final String groupId;
  final String groupName;

  GroupTile({
    super.key,
    required this.userName,
    required this.groupId,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
        child: ListTile(
          leading: FutureBuilder<String>(
            future: getGroupCategory(groupId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // If the Future is still running, you can return a placeholder or loading image
                return const CircleAvatar(
                  radius: 35.0,
                  backgroundColor: MyApp.blueMain,
                  child: CircularProgressIndicator(),
                );
              } else {
                return CircleAvatar(
                  radius: 35.0,
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
          title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("Join the conversation as $userName", style: const TextStyle(fontSize: 13.0)),
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
}
