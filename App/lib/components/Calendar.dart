import 'package:flutter/material.dart';
import 'package:flutter_neat_and_clean_calendar/flutter_neat_and_clean_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:rrule/rrule.dart';
import 'package:latlong2/latlong.dart' as latlong;

import '../main.dart';
import '../models/user.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeData();
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
    return Scaffold(
        appBar: buildAppBar(),
    body: Padding(
    padding: const EdgeInsets.only(top: 30.0), // Füge hier den gewünschten Abstand hinzu
    child: Column(
    children: [
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


  Future<void> _initializeData() async {
    List<EventData> eventDataList = await getMarkersAsFuture();

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