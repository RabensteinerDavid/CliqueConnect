import 'package:flutter/material.dart';
import 'package:flutter_neat_and_clean_calendar/flutter_neat_and_clean_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:rrule/rrule.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:firebase_auth/firebase_auth.dart';

import '../main.dart';
import '../shema/MapMarker.dart';

class EventData {
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String description;
  final latlong.LatLng location;
  final String category;
  final RecurrenceRule rrule;

  EventData({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.description,
    required this.location,
    required this.category,
    required this.rrule,
  });
}

class CalendarScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _CalendarScreenState();
  }
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool showEvents = true;
  late String nameActivityCalender;

  List<NeatCleanCalendarEvent> _eventList = [];
  final List<String> filtersCategory = [];

  late List<EventData> eventDataList = [];
  late List<EventData> filteredEventData =[];

  List<String> connectedEventNames = [];

  @override
  void initState() {
    super.initState();
    load();
    _initializeData();
  }

  void load() async {
    await getConnectedEventsName();
  }

  Future<List<String>> getConnectedEventsName() async {
    final firestore = FirebaseFirestore.instance;
    User? user = FirebaseAuth.instance.currentUser;

    List<String> connectedEvents = [];
    var userID = user?.uid;

    if (userID != null) {
      final snapshot = await firestore.collection("users").doc(userID).get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        var userGroup = data["groups"];

        for (var group in userGroup) {
          connectedEventNames.add(group.split("_")[1]);
        }
      }
    }
    return connectedEvents;
  }

  PreferredSizeWidget buildAppBar() {
    return PreferredSize(
      preferredSize: Size(
        MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.height * 0.08,
      ),
      child: AppBar(
        title: Image.asset(
          'assets/cliqueConnect.png',
          fit: BoxFit.contain,
          height: MediaQuery.of(context).size.height * 0.08,
        ),
        centerTitle: true,
        backgroundColor: MyApp.blueMain,
        elevation: 0.0,
        iconTheme: const IconThemeData(color: MyApp.blueMain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if(filtersCategory.isEmpty){
      filtersCategory.clear();
      filtersCategory.add("All");
    }
    if(filtersCategory.contains("All")){
      filtersCategory.clear();
      filtersCategory.add("All");
      _eventList = convertToCalendarEvents(eventDataList);
    }
    else if(filtersCategory.contains("Connected")){
      filtersCategory.clear();
      filtersCategory.add("Connected");
      late List<EventData> eventDataListNew = [];
      eventDataListNew = eventDataList.where((marker) {
        return filtersCategory.isEmpty || connectedEventNames.contains(marker.title);
      }).toList();
      _eventList = convertToCalendarEvents(eventDataListNew);
    }
    return Scaffold(
      appBar: buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: FutureBuilder<String?>(
                    future: getCatergoryActivities(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (!snapshot.hasData) {
                        return Container();
                      }

                      List<String> categories = snapshot.data!.split(',');

                      return Row(
                        children: categories.map((String category) {
                          return Row(
                            children: [
                              FilterChip(
                                label: Text(category),
                                selected: filtersCategory.contains(category),
                                onSelected: (bool selected) {
                                  setState(() {
                                    if (mounted && selected) {
                                      if (filtersCategory.contains("All") ||
                                          filtersCategory.contains("Connected")) {
                                        filtersCategory.clear();
                                        filtersCategory.add(category);
                                      } else {
                                        filtersCategory.add(category);
                                      }
                                    } else {
                                      filtersCategory.remove(category);
                                    }
                                    _updateFilteredMarkers();
                                  });
                                },
                              ),
                              const SizedBox(width: 4.0),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14.0),
            Expanded(
              child: Calendar(
                startOnMonday: true,
                weekDays: const ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'],
                eventsList: _eventList,
                isExpandable: true,
                defaultDayColor: MyApp.black,
                selectedTodayColor: MyApp.blueMain,
                eventDoneColor: MyApp.blueMain,
                selectedColor: MyApp.blueMain,
                todayColor: MyApp.pinkMain,
                eventColor: null,
                locale: 'de_DE',
                isExpanded: true,
                expandableDateFormat: 'EEEE, dd. MMMM yyyy',
                onEventSelected: (value) {
                  print('Event selected ${value.summary}');
                },
                onEventLongPressed: (value) {
                  print('Event long pressed ${value.summary}');
                },
                onMonthChanged: (value) {
                  print('Month changed $value');
                },
                onRangeSelected: (value) {
                  print('Range selected ${value.from} - ${value.to}');
                },
                datePickerType: DatePickerType.date,
                dayOfWeekStyle: const TextStyle(
                  color: MyApp.blueMain,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
                showEvents: showEvents,
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _updateFilteredMarkers() {
    setState(() {
      filteredEventData = eventDataList.where((marker) {
        return filtersCategory.isEmpty || filtersCategory.contains(marker.category);
      }).toList();
      _eventList = convertToCalendarEvents(filteredEventData);
    });
  }

  Future<String?> getCatergoryActivities() async {
    try {
      final activitiesCollectionRef = FirebaseFirestore.instance.collection("categoriesActivities");
      final data = await activitiesCollectionRef.doc("category").get();

      if (data.exists) {
        final activityList = data.data()!['activity'] as List<dynamic>;
        final activities = activityList
            .where((activity) => activity != 'All' && activity != 'Archive')
            .map((dynamic item) => item.toString())
            .toList();
        activities.insert(0, 'All');
        activities.insert(1, 'Connected');
        return activities.join(',');
      } else {
        print("Document does not exist");
        return "";
      }
    } catch (e) {
      print('Error retrieving data: $e');
      return "";
    }
  }

  Future<void> _initializeData() async {
    eventDataList = await getMarkersAsFuture();

    setState(() {
      _eventList = convertToCalendarEvents(eventDataList);
    });
  }


  Future<List<EventData>> getMarkersAsFuture() async {
    firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;
    final userID = user?.uid;
    List<EventData> eventDataList = [];
    List<dynamic> alldata =[];

    if (userID != null) {
      final activitiesCollectionRef = firestore.collection("activities");

      final querySnapshot = await activitiesCollectionRef.get();

      for (final activityDoc in querySnapshot.docs) {
        final Map<String, dynamic> data = activityDoc.data();
        for (final key in data.keys) {
          alldata = List.from(data[key] ?? []);
          if (alldata.isNotEmpty) {
            final nameActivity = await alldata[0];
            nameActivityCalender = nameActivity;

            final startTimestamp = await alldata[2]; // Assuming this is a Timestamp object
            final start = startTimestamp.seconds * 1000 +
                (startTimestamp.nanoseconds / 1e6).round();

            final description = await alldata[1];
            final location = await alldata[4];
            final category = await alldata[6];
            var ruleNew = "";
            RecurrenceRule rrule =  RecurrenceRule.fromString("RRULE:FREQ=WEEKLY;INTERVAL=1;BYDAY=FR;BYMONTH=12");
            if (alldata.length > 8) {
              ruleNew = await alldata[8];
              rrule = RecurrenceRule.fromString(ruleNew);
            }

            if (location != null && location is GeoPoint) {
              eventDataList.add(EventData(
                title: nameActivity,
                startTime: DateTime.fromMillisecondsSinceEpoch(start),
                endTime: DateTime.fromMillisecondsSinceEpoch(start),
                description: description,
                location: latlong.LatLng(
                    location.latitude, location.longitude),
                category: category,
                rrule: rrule,
              ));
            }
          }
        }
      }
      return eventDataList;
    } else {
      return eventDataList;
    }
  }

  // Funktion zum Umwandeln von Datenbankdaten in das Event-Format
  List<NeatCleanCalendarEvent> convertToCalendarEvents(List<EventData> events) {
    List<NeatCleanCalendarEvent> calendarEvents = [];

    for (EventData event in events) {
      calendarEvents.add(NeatCleanCalendarEvent(
        event.title,
        startTime: event.startTime,
        endTime: event.endTime,
        description: event.description,
        color: MyApp.blueMain,

        //color: event.color,
        //isMultiDay: event.isMultiDay,
        //isAllDay: event.isAllDay,
        //icon: event.icon,
      ));
    }

    return calendarEvents;
  }

}