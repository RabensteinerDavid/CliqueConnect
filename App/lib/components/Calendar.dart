  import 'package:flutter/material.dart';
  import 'package:flutter_neat_and_clean_calendar/flutter_neat_and_clean_calendar.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';

  import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:rrule/rrule.dart';


  import '../main.dart';
  import '../models/user.dart';




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

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: SafeArea(
          child: Calendar(
            startOnMonday: true,
            weekDays: ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'],
            eventsList: _eventList,
            isExpandable: true,
            eventDoneColor: const Color(0xFFACA9BF),
            selectedColor: const Color(0xFF6059F0),
            selectedTodayColor: Colors.green,
            todayColor: Colors.blue,
            eventColor: null,
            locale: 'de_DE',
            todayButtonText: 'Heute',
            allDayEventText: 'Ganztägig',
            multiDayEndText: 'Ende',
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
            dayOfWeekStyle: TextStyle(
                color: Colors.black, fontWeight: FontWeight.w800, fontSize: 11),
            showEvents: showEvents,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              showEvents = !showEvents;
            });
          },
          child: Icon(showEvents ? Icons.visibility_off : Icons.visibility),
          backgroundColor: Colors.green,
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
            alldata = List.from(data[key]);
            final nameActivity = await alldata[0];
            nameActivityCalender = nameActivity;

            final startTimestamp = await alldata[2]; // Assuming this is a Timestamp object
            final start = startTimestamp.seconds * 1000 + (startTimestamp.nanoseconds / 1e6).round();

            final description = await alldata[1];
            final location = await alldata[4];
            final category = await alldata[6];
            var ruleNew = "";
            var rrule;
            if (alldata.length > 8) {
              ruleNew = await alldata[8];
              rrule = RecurrenceRule.fromString(ruleNew);
            }
            print(rrule);
            eventDataList.add(EventData(
              title: nameActivity,
              startTime: DateTime.fromMillisecondsSinceEpoch(start),
              endTime: DateTime.fromMillisecondsSinceEpoch(start),
              description: description,
              location: location,
              category: category,
              rrule: rrule,
            ));
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
          //color: event.color,
          //isMultiDay: event.isMultiDay,
          //isAllDay: event.isAllDay,
          //icon: event.icon,
        ));
      }

      return calendarEvents;
    }

  }
  class EventData {
    final String title;
    final DateTime startTime;
    final DateTime endTime;
    final String description;

    // ... (andere Event-Attribute)

    EventData({
      required this.title,
      required this.startTime,
      required this.endTime,
      required this.description, required location, required category, required rrule,
      // ... (andere Event-Attribute)
    });
  }
