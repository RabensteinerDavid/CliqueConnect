import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String uid;

  DatabaseService({required this.uid});

  final CollectionReference userCollection =
  FirebaseFirestore.instance.collection('users');
  final CollectionReference groupCollection =
  FirebaseFirestore.instance.collection('groups');

  Stream<DocumentSnapshot> getUserGroups() {
    return FirebaseFirestore.instance.collection("users").doc(uid).snapshots();
  }

  Future<QuerySnapshot> searchByName(String searchField) async {
    return await FirebaseFirestore.instance
        .collection("groups")
        .where("groupName", isGreaterThanOrEqualTo: searchField)
        .get();
  }

  Future<DocumentSnapshot> getUserData(String email) async {
    try {
      return await userCollection.doc(uid).get();
    } catch (e) {
      print('Error getting user data: $e');
      throw e;
    }
  }

  Future<void> createGroup(String userName, String groupName, String category) async {
    try {
      DocumentReference groupDocRef = await groupCollection.add({
        'groupName': groupName,
        'groupIcon': '',
        'admin': userName,
        'members': [],
        'groupId': '',
        'recentMessage': '',
        'recentMessageSender': '',
        'category': category,
      });

      await groupDocRef.update({
        'members': FieldValue.arrayUnion([uid + '_' + userName]),
        'groupId': groupDocRef.id,
      });

      DocumentReference userDocRef = userCollection.doc(uid);
      await userDocRef.update({
        'groups': FieldValue.arrayUnion([groupDocRef.id + '_' + groupName]),
      });
    } catch (e) {
      print('Error creating group: $e');
    }
  }

  Future<bool> isUserJoined(String groupId, String groupName, String userName) async {
    try {
      DocumentSnapshot groupDoc =
      await groupCollection.doc(groupId).get();

      List<dynamic> members = groupDoc['members'];

      return members.contains(uid + '_' + userName);
    } catch (e) {
      print('Error checking if user is joined: $e');
      return false;
    }
  }

  Future<void> togglingGroupJoin(String groupId, String groupName, String userName) async {
    try {
      DocumentReference groupDocRef = groupCollection.doc(groupId);

      bool isJoined = await isUserJoined(groupId, groupName, userName);

      if (isJoined) {
        await groupDocRef.update({
          'members': FieldValue.arrayRemove([uid + '_' + userName]),
        });

        await userCollection.doc(uid).update({
          'groups': FieldValue.arrayRemove([groupId + '_' + groupName]),
        });
      } else {
        await groupDocRef.update({
          'members': FieldValue.arrayUnion([uid + '_' + userName]),
        });
        await userCollection.doc(uid).update({
          'groups': FieldValue.arrayUnion([groupId + '_' + groupName]),
        });
      }
    } catch (e) {
      print('Error toggling group join: $e');
    }
  }

  Future<void> sendMessage(String groupId, chatMessageData) async {
    try {
      FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .add(chatMessageData);

      FirebaseFirestore.instance.collection('groups').doc(groupId).update({
        'recentMessage': chatMessageData['message'],
        'recentMessageSender': chatMessageData['sender'],
        'recentMessageTime': chatMessageData['time'].toString(),
      });
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Stream<QuerySnapshot> getChats(String groupId) {
    return FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('time')
        .snapshots();
  }
}
