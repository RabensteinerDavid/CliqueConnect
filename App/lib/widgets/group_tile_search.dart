import 'package:flutter/material.dart';
import '../pages/chat_page.dart';

class GroupTile_Search extends StatelessWidget {
  final String userName;
  final String groupId;
  final String groupName;

  GroupTile_Search({required this.userName, required this.groupId, required this.groupName});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        leading: CircleAvatar(
          radius: 30.0,
          backgroundColor: Colors.blueAccent,
          child: Text(groupName.substring(0, 1).toUpperCase(), style: TextStyle(color: Colors.white)),
        ),
        title: Text(groupName, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Join the conversation as $userName", style: TextStyle(fontSize: 13.0)),
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
      ),
    );
  }
}
