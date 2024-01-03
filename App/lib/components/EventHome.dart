import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stacked_card_carousel/stacked_card_carousel.dart';
import 'package:test_clique_connect/components/AddEventForm.dart';
import 'package:test_clique_connect/components/AnimatedMarkersMap_NEW.dart';
import 'package:test_clique_connect/components/ProfileView.dart';
import 'package:test_clique_connect/main.dart';

import 'event.dart';

final filters = <String>{};

class EventHome extends StatefulWidget {
  const EventHome({Key? key}) : super(key: key);

  @override
  _EventHomeState createState() => _EventHomeState();
}

class _EventHomeState extends State<EventHome> {
  final firestore = FirebaseFirestore.instance;
  static const eventBoxSize = 230.0;
  static const textLength = 30;
  List<Map<String, dynamic>> eventList = [];
  List<Map<String, dynamic>> eventListShowing = [];
  static Set<String> filterCategories = <String>{};

  @override
  void initState() {
    super.initState();
    getEventData();
  }

  void setFilterCategories(Set<String> newFilterCategories) {
    setState(() {
      filterCategories = newFilterCategories;
      filterEvents(filterCategories);
    });
  }

  void filterEvents(Set<String> filters) {
    if (filters.isEmpty) {
      eventListShowing = eventList;
    } else {
      eventListShowing =
          eventList.where((event) => filters.contains(event['eventCategory'])).toList();
    }
  }

  PreferredSizeWidget buildAppBar() {
    return PreferredSize(
      preferredSize: Size(
        MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.height * 0.09,
      ),
      child: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: MyApp.blueMain,
        elevation: 0.0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.only(top: 25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Image.asset(
                  'icons/plus_white.png',
                  width: 30,
                  height: 30,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddEventForm()),
                  );
                },
              ),
              Image.asset(
                'assets/cliqueConnect.png',
                fit: BoxFit.contain,
                height: MediaQuery.of(context).size.height * 0.08,
              ),
              IconButton(
                icon: Image.asset(
                  'icons/profile_rose.png',
                  width: 30,
                  height: 30,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileView()),
                  );
                },
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: Material(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                margin: const EdgeInsets.only(left: 16.0, top: 6.0, bottom: 0),
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
            Container(
              margin: const EdgeInsets.only(top: 0.0),
              child: Transform(
                transform: Matrix4.translationValues(-300 / 8, 0, 0),
                child: CarouselSlider.builder(
                  itemCount: eventList.length,
                  options: CarouselOptions(
                    height: 150.0,
                    enlargeCenterPage: true,
                    enableInfiniteScroll: false,
                    viewportFraction: 0.5,
                  ),
                  itemBuilder: (context, index, realIndex) {
                    String eventName = eventList[index]['eventName'];
                    if (eventName.length > textLength) {
                      eventName = eventName.substring(0, textLength) + '...';
                    }

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Event(
                              eventName: eventList[index]['eventName'],
                              eventCategory: eventList[index]['eventCategory'],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        child: Stack(
                          children: [
                            Image.network(
                              eventList[index]['imgURL'],
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
                ),
              ),
            ),

            Align(
              alignment: Alignment.topLeft,
              child: Container(
                margin: const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 0),
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

            const Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: FilterChipExample(),
              ),
            ),

            Expanded(
              child: eventListShowing.isNotEmpty
                  ? StackedCardCarousel(
                initialOffset: 20,
                spaceBetweenItems: eventBoxSize * 1.1,
                type: StackedCardCarouselType.fadeOutStack,
                items: eventListShowing.map((item) {
                  String eventName = item['eventName'];
                  if (eventName.length > textLength) {
                    eventName = eventName.substring(0, textLength) + '...';
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
                    child: Container(
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
                            margin: const EdgeInsets.only(left: 16.0, bottom: 16.0),
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
                    ),
                  );
                }).toList(),
              )
                  : Container(
                child: Center(
                  child: Text("No events to display"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  Future<void> getEventData() async {
    final activitiesCollectionRef = firestore.collection("activities");

    try {
      var querySnapshot = await activitiesCollectionRef.get();

      List<Map<String, dynamic>> tempList = [];

      querySnapshot.docs.forEach((activityDoc) {
        final Map<String, dynamic> data = activityDoc.data();
        activityDoc.data().forEach((key, value) {
          final alldata = List.from(data[key] ?? []);
          if (alldata.isNotEmpty) {
            if (activityDoc.id == 'Off Topic') {
              tempList.add({
                'eventName': key,
                'eventCategory': "OffTopic",
                'imgURL': value[5],
              });
            } else {
              tempList.add({
                'eventName': key,
                'eventCategory': activityDoc.id,
                'imgURL': value[5],
              });
            }

            print('Event: $key, Category: ${activityDoc.id}');
          }
        });
      });

      setState(() {
        eventList = tempList;
        filterEvents(filterCategories); // Initial filter
      });
    } catch (e) {
      print("Error getting documents: $e");
    }
  }
}

class FilterChipExample extends StatefulWidget {
  const FilterChipExample({Key? key});

  @override
  State<FilterChipExample> createState() => _FilterChipExampleState();
}

class _FilterChipExampleState extends State<FilterChipExample> {
  Future<String?> getCatergoryActivities() async {
    try {
      final activitiesCollectionRef =
      FirebaseFirestore.instance.collection("categoriesActivities");
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
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
          children: categories.isNotEmpty
              ? categories.map((String category) {
            return Row(
              children: [
                FilterChip(
                  label: Text(category),
                  selected: filters.contains(category),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        filters.add(category);
                      } else {
                        filters.remove(category);
                      }

                      if (filters.isEmpty) {
                        _EventHomeState.filterCategories = Set.from(categories);
                      } else {
                        _EventHomeState.filterCategories = Set.from(filters);
                      }
                      _EventHomeState().filterEvents(_EventHomeState.filterCategories);

                      print("Filter Categories: ${_EventHomeState.filterCategories.join(', ')}");
                    });
                  },
                  selectedColor: Color(0xFFEF3DF2),
                  backgroundColor: Color(0xEEEEEEEE),
                  labelStyle: TextStyle(
                    color: filters.contains(category) ? Colors.white : Colors.black,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                ),
                SizedBox(width: 4.0),
              ],
            );
          }).toList()
              : [Container()],
        );
      },
    );
  }
}
