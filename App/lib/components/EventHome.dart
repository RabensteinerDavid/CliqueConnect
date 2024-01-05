import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stacked_card_carousel/stacked_card_carousel.dart';
import 'package:test_clique_connect/components/AddEventForm.dart';
import 'package:test_clique_connect/components/ProfileView.dart';
import 'package:test_clique_connect/main.dart';
import 'event.dart';

final List<String> filtersCategory = [];

class EventHome extends StatefulWidget {
  const EventHome({Key? key}) : super(key: key);

  @override
  _EventHomeState createState() => _EventHomeState();
}

class _EventHomeState extends State<EventHome> {
  final firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;

  static const eventBoxSize = 260.0;
  static const textLength = 30;

  late Future<List<Map<String, dynamic>>> eventDataAll;
  late Future<String> userName;
  late Future<List<Map<String, dynamic>>> connectedEvents;
  late List<Map<String, dynamic>> filteredEvents = [];

  @override
  void initState() {
    super.initState();
    userName = getUserName();
    eventDataAll = getEventData();
    connectedEvents = getConnectedEventsNames();

    _updateFilteredEvents();
  }


  PreferredSizeWidget buildAppBar() {
    return PreferredSize(
      preferredSize: Size(
        MediaQuery.of(context).size.width, // Set the width to the full width of the screen
        MediaQuery.of(context).size.height * 0.08,
      ),
      child: AppBar(
        title: Image.asset('assets/cliqueConnect.png', fit: BoxFit.contain, height: MediaQuery.of(context).size.height * 0.08),
        centerTitle: true,
        backgroundColor: MyApp.blueMain,
        elevation: 0.0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: Image.asset(
                'icons/profile_white.png',
                width: 25,
                height: 25,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileView(),
                  ),
                );
              },
              color: Colors.white,
            ),
          ),
        ],
        leading: IconButton(
          icon: Image.asset(
            'icons/plus_white.png',
            width: 30,
            height: 30,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddEventForm(),
              ),
            );
          },
        ),
        leadingWidth: 65,
      ),
    );
  }




  Future<List<Map<String, dynamic>>> getEventData() async {
    final activitiesCollectionRef =
    FirebaseFirestore.instance.collection("activities");

    try {
      var querySnapshot = await activitiesCollectionRef.get();

      List<Map<String, dynamic>> tempList = [];

      for (var activityDoc in querySnapshot.docs) {
        final Map<String, dynamic> data = activityDoc.data();
        activityDoc.data().forEach((key, value) {
          final alldata = List.from(data[key] ?? []);
          if (alldata.isNotEmpty) {
            tempList.add({
              'eventName': key,
              'eventCategory': activityDoc.id,
              'imgURL': value[5],
              'connected': value[7],
            });
          }
        });
      }
      return tempList;
    } catch (e) {
      print("Error getting documents: $e");
      return [];
    }
  }

  Future<List<String>> getConnectedEventsName() async {
    List<String> connectedEvents = [];
    var userID = user?.uid;

    if (userID != null) {
      final snapshot = await firestore.collection("users").doc(userID).get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        var userGroup = data["groups"];

        for (var group in userGroup) {
          connectedEvents.add(group.split("_")[1]);
        }
      }
    }
    return connectedEvents;
  }

  Future<List<Map<String, dynamic>>> getConnectedEventsNames() async {
    List<Map<String, dynamic>> connectedEvents = [];
    List<Map<String, dynamic>> events = await eventDataAll;

    for (var event in events) {
      List<String> connectedEventNames = await getConnectedEventsName();
      for (var name in connectedEventNames) {
        if (name.contains(event['eventName'])) {
          connectedEvents.add(event);
        }
      }
    }
    print(connectedEvents);
    return connectedEvents;
  }

  Future<String> getUserName() async {
    var userID = user?.uid;
    var userName = "No Username Available";

    if (userID != null) {
      final snapshot = await firestore.collection("users").doc(userID).get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final name = data["username"];

        print(name);
        if (name != null) {
          userName = name;
        }
      }
    }
    return userName;
  }

  Widget _buildGradientShadow() {
    return Container(
      height: eventBoxSize,
      width: eventBoxSize * 1.34,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.transparent,
            Colors.transparent,
            Colors.transparent,
            Colors.black12,
            Colors.black87,
          ],
        ),
      ),
    );
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

  void _updateFilteredEvents() async {
    final events = await eventDataAll;

    setState(() {
      filteredEvents = events.where((marker) {
        return filtersCategory.isEmpty || filtersCategory.contains(marker['eventCategory']);
      }).toList();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              margin: const EdgeInsets.only(left: 30.0, top: 20.0, bottom: 0),
              child: const Text(
                "Connected",
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 20.0, right: 20.0),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: connectedEvents,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  return CarouselSlider.builder(
                    itemCount: snapshot.data!.length,
                    options: CarouselOptions(
                      scrollPhysics: const BouncingScrollPhysics(),
                      height: 150.0,
                      enableInfiniteScroll: false,
                      viewportFraction: 0.5,
                      pageSnapping: false,
                      padEnds: false,
                    ),
                    itemBuilder: (context, index, realIndex) {
                      String eventName = snapshot.data![index]['eventName'];
                      if (eventName.length > textLength) {
                        eventName =
                        '${eventName.substring(0, textLength)}...';
                      }

                      return Padding(
                        padding: const EdgeInsets.only(
                            right: 8), // Adjust spacing as needed
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Event(
                                  eventName: snapshot.data![index]
                                  ['eventName'],
                                  eventCategory: snapshot.data![index]
                                  ['eventCategory'],
                                ),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              Image.network(
                                snapshot.data![index]['imgURL'],
                                height: 150.0,
                                fit: BoxFit.fitHeight,
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 50,
                                  color: MyApp.blueMain,
                                  child: Center(
                                    child: Text(
                                      eventName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Container(
              margin: const EdgeInsets.only(left: 30.0, top: 20.0, bottom: 0),
              child: const Text(
                "Explore",
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
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
                                  filtersCategory.add(category);
                                } else {
                                  filtersCategory.remove(category);
                                }
                                _updateFilteredEvents(); // Update filtered markers when filters change
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
          Expanded(
              child: filteredEvents.isNotEmpty
                  ? StackedCardCarousel(
              initialOffset: 20,
              spaceBetweenItems: eventBoxSize * 1.1,
              type: StackedCardCarouselType.fadeOutStack,
              items: filteredEvents.map((item) {
                String eventName = item['eventName'];
                if (eventName.length > textLength) {
                  eventName = '${eventName.substring(0, textLength)}...';
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Event(
                          eventName: item['eventName'],
                          eventCategory: item['eventCategory'],
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      Image.network(
                        item['imgURL'],
                        height: eventBoxSize,
                        fit: BoxFit.cover,
                      ),
                      _buildGradientShadow(),
                      Positioned(
                        top: eventBoxSize * 0.03,
                        right: eventBoxSize * 0.03,
                        child: Image.asset(
                          'assets/Event/${item['eventCategory']}.png',
                          height: 75,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(
                            left: 16.0, bottom: 16.0),
                        child: Text(
                          eventName,
                          style: const TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
          : const Center(
          child: Text("No Events"),
          ))
        ],
      ),
    );
  }
}