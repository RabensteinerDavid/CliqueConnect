
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stacked_card_carousel/stacked_card_carousel.dart';
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
  static const eventBoxSice = 230.0;
  static const textLength = 30;
  List<Map<String, dynamic>> eventList = [];

  @override
  void initState() {
    super.initState();
    getEventData();
  }

  PreferredSizeWidget buildAppBar() {
    return PreferredSize(
      preferredSize: Size(
        MediaQuery.of(context).size.width, // Set the width to the full width of the screen
        MediaQuery.of(context).size.height * 0.08,
      ),
      child: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('icons/arrow_white_noBG_white.png', // Set the correct path to your image
              width: 30,
              height: 30,
            ),
          ),
        ),
        title: Image.asset('assets/cliqueConnect.png', fit: BoxFit.contain, height: MediaQuery.of(context).size.height * 0.08),
        centerTitle: true,
        backgroundColor: MyApp.blueMain,
        elevation: 0.0,
        iconTheme: const IconThemeData(color: Colors.white),
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
              margin: const EdgeInsets.only(top: 0.0), // Adjust the top margin as needed
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
                    return GestureDetector(
                      onTap: () {
                        // Navigate to the EventPage
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
                                height: 50, // Adjust the height as needed
                                color: MyApp.blueMain,
                                child: Center(
                                  child: Text(
                                    eventList[index]['eventName'],
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
              child: StackedCardCarousel(
                initialOffset: 20,
                spaceBetweenItems: eventBoxSice * 1.1,
                type: StackedCardCarouselType.fadeOutStack,
                items: eventList.map((item) {
                  String eventName = item['eventName'];
                  if (eventName.length > textLength) {
                    // Begrenze den Text auf 64 Zeichen
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
                        alignment: Alignment.bottomLeft, // Text links unten positionieren
                        children: [
                          // Bild
                          Image.network(
                            item['imgURL'],
                            height: eventBoxSice,
                            fit: BoxFit.cover,
                          ),
                          // Gradienten-Overlay über dem Bild
                          Container(
                            width: 309, // TODO: An Bild anpassen
                            height: eventBoxSice, // Set to the height of the image
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
                                  // Adjust the color as needed
                                ],
                              ),
                            ),
                          ),
                          // Text
                          Container(
                            margin: const EdgeInsets.only(left: 16.0, bottom: 16.0), // Anpassen, wie es dir gefällt
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
              ),
            ),





          ],
        ),
      ),
    );
  }

  Widget _buildGradientShadow() {
    return Container(
      height: eventBoxSice, // Set to the height of the image
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
            // Adjust the color as needed
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
            tempList.add({
              'eventName': key,
              'eventCategory': activityDoc.id,
              'imgURL': value[5],
            });
          }});
      });

      setState(() {
        eventList = tempList;
      });
    } catch (e) {
      print("Error getting documents: $e");
      // Handle errors here
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
          // Return an error message if there's an error
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          // Return an empty container if there's no data
          return Container();
        }

        // Extract categories from the snapshot data
        List<String> categories = snapshot.data!.split(',');

        return Row(
          children: categories.map((String category) {
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
                    });
                  },
                ),
                SizedBox(width: 4.0), // Add the desired spacing here
              ],
            );
          }).toList(),
        );
      },
    );
  }
}


