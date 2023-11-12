import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import 'event.dart';

class EventHome extends StatefulWidget {
  const EventHome({Key? key}) : super(key: key);

  @override
  _EventHomeState createState() => _EventHomeState();
}

class _EventHomeState extends State<EventHome> {
  final firestore = FirebaseFirestore.instance;

  Map<String, dynamic> eventMap = {};

  @override
  void initState() {
    super.initState();
    getEventData();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Event Home'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (eventMap.isNotEmpty) // Change this line to use eventMap
              Expanded(
                child: ListView.builder(
                  itemCount: eventMap.length, // Change this line to use eventMap
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: CupertinoButton(
                        onPressed: () {
                          // Hier wird zur EventPage navigiert
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => Event(
                                //es geht trotz fehler
                                eventName: eventMap.keys.elementAt(index),
                                eventCategory: eventMap.values.elementAt(index),
                              ),
                            ),
                          );
                        },
                        color: CupertinoColors.activeBlue,
                        child: Text(
                          eventMap.keys.elementAt(index), // Use the key as the event name
                          style: TextStyle(
                            color: CupertinoColors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Text(
                'No events available',
                style: TextStyle(fontSize: 18),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> getEventData() async {
    final activitiesCollectionRef = firestore.collection("activities");

    try {
      var querySnapshot = await activitiesCollectionRef.get();

      // Iteriere durch die Dokumente und füge die IDs zur Liste hinzu
      querySnapshot.docs.forEach((activityDoc) {
        activityDoc.data().forEach((key, value) {
          eventMap.addEntries([MapEntry(key, activityDoc.id)]);
        });
      });

      // Löse ein erneutes Rendering aus, um die Liste anzuzeigen
      setState(() {});
    } catch (e) {
      print("Error getting documents: $e");
      // Handle Fehler hier
    }
  }
}
