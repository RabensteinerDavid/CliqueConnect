import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:rrule/rrule.dart';
import '../main.dart';
import '../shema/MapMarker.dart';
import 'ProfileView.dart';
import 'Event.dart';
import 'package:intl/intl.dart';


// Replace with your Mapbox access token
const MAPBOX_ACCESS_TOKEN = 'sk.eyJ1IjoiYm9uaXRoYW4iLCJhIjoiY2xvaGFydjR1MGV5bDJqbnZ6cWg0dXh4cyJ9.m3uRWclpqOdSgYfUegOlTg';
const MAPBOX_STYLE = 'mapbox://styles/bonithan/cloh3lx0f000d01qoh3okhz10';
const MARKER_COLOR = Color(0xFF3DC5A7);
const MARKER_SIZE_EXPAND = 55.0;
const MARKER_SIZE_SHRINK = 30.0;

const LocationSettings locationSettings = LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 10,
);

final List<String> filtersCategory = [];
List<MapMarker> _markers = [];

var categorySave = "";

List<int> indexToShow = [];

late List<MapMarker> filteredMapMarkers; //hier stehen nur die einträge drinnen die gefiltert worden sind

class AnimatedMarkersMap_NEW extends StatefulWidget {
  const AnimatedMarkersMap_NEW({Key? key}) : super(key: key);

  @override
  State<AnimatedMarkersMap_NEW> createState() => _LocationPageState();
}

class _LocationPageState extends State<AnimatedMarkersMap_NEW> with TickerProviderStateMixin {
  MapController mapController = MapController();

  final PageController _pageController = PageController(initialPage: 0, keepPage: true);

  bool isCardVisible = false;

  int selectedCardIndex = 0;

  late Future<List<MapMarker>> _markersFuture;

  @override
  void initState() {
    super.initState();
    _updateMarkers();
    _markersFuture = getMarkersAsFuture();
    _markers = [];
  }

  void _updateMarkers() async {
    final markers = await getMarkersAsFuture();
    setState(() {
      _markers = List.from(markers);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _markers = [];
  }

  Future<String> _convertAddressToCoordinates(GeoPoint location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude, location.longitude);

      if (placemarks.isNotEmpty) {
        Placemark first = placemarks.first;

        return'${first.street}, ${first.locality}, ${first.administrativeArea}';
      } else {
        return 'No address found for the given coordinates';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<List<MapMarker>> getMarkersAsFuture() async {
    final firestore = FirebaseFirestore.instance;
    final userID = user?.uid;

    if (userID != null) {
      final activitiesCollectionRef = firestore.collection("activities");

      final querySnapshot = await activitiesCollectionRef.get();
      final now = Timestamp.now();

      Map<String, MapMarker> uniqueMarkers = {};

      for (final activityDoc in querySnapshot.docs) {
        final activityName = activityDoc.id;
        final Map<String, dynamic> data = activityDoc.data();

        for (final key in data.keys) {
          List<dynamic> alldata = List.from(data[key]);

          final nameActivity = await alldata[0];
          final description = await alldata[1];
          final start = await alldata[2];
          final location = await alldata[4];
          final category = await alldata[6];
          categorySave = category;
          var ruleNew = "";
          var rrule;
          if (alldata.length > 8) {
            ruleNew = await alldata[8];
            rrule = RecurrenceRule.fromString(ruleNew);
          }

          var imagePic = 'assets/Marker.png';
          switch (category) {
            case 'Creative':
              imagePic = "assets/creative_noStory.png";
            case 'Sports':
              imagePic = "assets/sports_noStory.png";
            case 'Games':
              imagePic = "assets/gaming_noStory.png";
            case 'Education':
              imagePic = "assets/education_noStory.png";
            case 'Nightlife':
              imagePic = "assets/nightLife_noStory.png";
            case 'Culinary':
              imagePic = "assets/culinary_noStory.png";
            case 'Off Topic':
              imagePic = "assets/offTopic_noStory.png";
            case 'Archives':
              imagePic = "assets/archive_noStory.png";
            default:
              imagePic = "assets/offTopic_noStory.png";
          }

          if (location != null && location is GeoPoint) {
            var address = await _convertAddressToCoordinates(location);

            // Use the title as a unique identifier
            String title = nameActivity.toString();
            final category = alldata.length > 6 ? await alldata[6].toString() : '';

            // Check if the title is already in the map
            if (!uniqueMarkers.containsKey(title)) {
              uniqueMarkers[title] = MapMarker(
                image: imagePic,
                title: title,
                address: address,
                location: latlong.LatLng(location.latitude, location.longitude),
                start: start,
                end: now,
                description: description,
                category: category,
                rule: rrule,
              );
            }
          }
        }
      }

      // Convert the map values to a list
      _markers = uniqueMarkers.values.toList();
      return _markers;
    } else {
      print("User ID is null. Make sure the user is authenticated.");
      return _markers; // Return an empty list if user ID is null
    }
  }

  List<Marker> _buildMarkersWithFilter(List<MapMarker> markers) {
    return markers.map((marker) {
      final index = filteredMapMarkers.indexOf(marker); // Use the index from the filtered list
      final markerSize = index == selectedCardIndex ? MARKER_SIZE_EXPAND : MARKER_SIZE_SHRINK;
      return Marker(
        height: markerSize,
        width: markerSize,
        point: marker.location,
        builder: (BuildContext context) {
          return YourCustomMarkerWidget(
            category: marker.category,
            marker: marker,
            selected: index == selectedCardIndex,
            onTap: () {
              setState(() {
                isCardVisible = true;
                selectedCardIndex = index;
              });
              Future.delayed(const Duration(milliseconds: 50), () {
                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.ease,
                  );
                  _animateCameraToMarker(marker);
                }
              });
            },
          );
        },
      );
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    filteredMapMarkers = _markers.where((marker) {
      return filtersCategory.isEmpty || filtersCategory.contains(marker.category);
    }).toList();
    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<Position>(
            stream: Geolocator.getPositionStream(locationSettings: locationSettings),
            builder: (context, positionSnapshot) {
              if (positionSnapshot.hasData) {
                print("first");
                final userPosition = positionSnapshot.data;
                return FutureBuilder<List<MapMarker>>(
                  future: _markersFuture,
                  builder: (context, markersSnapshot) {
                    if (markersSnapshot.connectionState == ConnectionState.done) {
                      print("second");
                      return _markers.isNotEmpty
                          ? FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          onTap: (tapPosition, point) {
                            if (tapPosition != Marker) {
                              setState(() {
                                isCardVisible = false;
                              });
                            }
                          },
                          minZoom: 1,
                          maxZoom: 19,
                          zoom: 18,
                          center: latlong.LatLng(userPosition!.latitude, userPosition.longitude),
                        ),
                        children: [
                          TileLayer(
                            maxZoom: 19,
                            urlTemplate: 'https://api.mapbox.com/styles/v1/{style_id}/tiles/{z}/{x}/{y}?access_token={access_token}',
                            additionalOptions: const {
                              'style_id': 'bonithan/cloh3lx0f000d01qoh3okhz10',
                              'access_token': MAPBOX_ACCESS_TOKEN,
                            },
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: latlong.LatLng(userPosition.latitude, userPosition.longitude),
                                builder: (_) {
                                  return const _MyLocationMarker();
                                },
                              ),
                            ],
                          ),
                          MarkerClusterLayerWidget(
                            options: MarkerClusterLayerOptions(
                              onClusterTap: (MarkerClusterNode node) {
                              },
                              maxClusterRadius: 25,
                              size: const Size(30, 30),
                              fitBoundsOptions: const FitBoundsOptions(
                                padding: EdgeInsets.all(50),
                                maxZoom: 15,
                              ),
                              markers: _buildMarkersWithFilter(filteredMapMarkers),
                              builder: (context, markers) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(130),
                                    color: MyApp.blueMain,
                                  ),
                                  child: Center(
                                    child: Text(
                                      markers.length.toString(),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                          : const CircularProgressIndicator();
                    }
                    return const CircularProgressIndicator();
                  },
                );
              }
              return const CircularProgressIndicator();
              },
            ),

          Container(
            height: MediaQuery.of(context).size.height * 0.18,
            color: MyApp.blueMain,
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.07,
            left: MediaQuery.of(context).size.width * 0.08,
            right: MediaQuery.of(context).size.width * 0.1,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.08,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/cliqueConnect.png"),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.3,
            child: Visibility(
              visible: isCardVisible && filteredMapMarkers.isNotEmpty,
              child: PageView.builder(
                controller: _pageController,
                itemCount: filteredMapMarkers.length,
                itemBuilder: (context, index) {
                  final originalIndex = _markers.indexOf(filteredMapMarkers[index]);
                  final item = filteredMapMarkers[index];
                  return _MapItemDetails(
                    mapMarker: item,
                    currentIndex: index,
                    pageController: _pageController,
                    onCardSwiped: (int index) {
                      final item = filteredMapMarkers[index];
                      setState(() {
                        _animateCameraToMarker(item);
                        selectedCardIndex = index; // Update the selected card index
                      });
                    },
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 160,
            left: 10,
            right: 10,
            child: Opacity(
              opacity: 0.7,
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
                                    isCardVisible = false;
                                  } else {
                                    filtersCategory.remove(category);
                                    isCardVisible = false;
                                  }
                                  _updateFilteredMarkers(); // Update filtered markers when filters change
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
        ],
      ),
    );
  }

  void _updateFilteredMarkers() {
    setState(() {
      filteredMapMarkers = _markers.where((marker) {
        return filtersCategory.isEmpty || filtersCategory.contains(marker.category);
      }).toList();

      // Update selectedCardIndex to match the selected card in the filtered list
      if (selectedCardIndex >= filteredMapMarkers.length) {
        selectedCardIndex = 0; // Reset selected card index if it's out of bounds
      }
    });
  }


  void _animateCameraToMarker(MapMarker marker) {
    final destLocation = marker.location;
    final destZoom = 18.0;

    final latTween =
    Tween<double>(begin: mapController.center.latitude, end: destLocation.latitude);
    final lngTween =
    Tween<double>(begin: mapController.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: mapController.zoom, end: destZoom);

    final controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this, // Use the TickerProvider from the current state
    );

    final Animation<double> animation =
    CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      mapController.move(
        latlong.LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
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
}

class _MapItemDetails extends StatefulWidget {
  const _MapItemDetails({
    Key? key,
    required this.mapMarker,
    required this.currentIndex,
    required this.pageController,
    required this.onCardSwiped,
  }) : super(key: key);

  final MapMarker mapMarker;
  final int currentIndex;
  final PageController pageController;
  final ValueChanged<int> onCardSwiped;

  @override
  _MapItemDetailsState createState() => _MapItemDetailsState();
}

class _MapItemDetailsState extends State<_MapItemDetails> {
  double _dragStartX = 0.0;
  double _currentX = 0.0;
  double _offset = 0.0;
  final double _threshold = 50.0;

  String? _getMonthNames(Set<int>? monthNumbers) {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    final List<String>? selectedMonthNames = monthNumbers?.map((monthNumber) {
      if (monthNumber >= 1 && monthNumber <= 12) {
        return monthNames[monthNumber - 1];
      } else {
        return 'Unknown';
      }
    }).toList();

    return selectedMonthNames?.join('');
  }


  @override
  Widget build(BuildContext context) {
    DateTime startDate = widget.mapMarker.start.toDate();
    String formattedStartDate = DateFormat.yMMMMd().add_jm().format(startDate);
    return GestureDetector(
      onHorizontalDragStart: (details) {
        _dragStartX = details.localPosition.dx;
      },
      onHorizontalDragUpdate: (details) {
        _currentX = details.localPosition.dx;
        final delta = _currentX - _dragStartX;
        setState(() {
          _offset = delta;
        });
      },
      onHorizontalDragEnd: (details) {
        if (_offset.abs() > _threshold) {
          if (_offset > 0 && widget.currentIndex > 0) {
            // Swiped right
            final newIndex = widget.currentIndex - 1;
            widget.pageController.previousPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.ease,
            );
            widget.onCardSwiped(newIndex); // Notify the parent about the swipe
          } else if (_offset < 0 &&
              widget.currentIndex < filteredMapMarkers.length - 1) {
            // Swiped left
            final newIndex = widget.currentIndex + 1;
            widget.pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.ease,
            );
            widget.onCardSwiped(newIndex); // Notify the parent about the swipe
          }
          setState(() {
            _offset = 0.0;
          });
        } else {
          setState(() {
            _offset = 0.0;
          });
        }
      },
      child: Stack(
        children: [
          // Positioned widget for the Card
          Positioned(
            child: Card(
              color: Colors.white,
              margin: const EdgeInsets.all(50.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    0.0), // Set the radius to 0 for sharp corners
              ),
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30.0, 15.0, 15.0, 10.0),
                  // Add left padding of 10
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.mapMarker.title,
                          overflow: TextOverflow.visible,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 20, // Adjust the font size as needed
                            fontWeight: FontWeight
                                .bold, // You can adjust the font weight as well
                          ),
                        // Adjust the number of lines to show
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          "",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 20, // Adjust the font size as needed
                          ),
                          // Adjust the number of lines to show
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "Description: ${ widget.mapMarker.description}",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1, // Adjust the number of lines to show
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "Address: ${widget.mapMarker.address}",
                          overflow: TextOverflow.visible,
                          style: const TextStyle(
                              fontSize: 12,
                            // You can adjust the font weight as well
                          ),
                          // Remove the maxLines property to allow the text to expand vertically
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          "",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 20, // Adjust the font size as needed
                          ),
                          // Adjust the number of lines to show
                        ),
                      ),
                      Expanded(
                        child: Text(
                        "${widget.mapMarker.rule?.byWeekDays != null ? 'When: ${widget.mapMarker.rule?.frequency} at ${widget.mapMarker.rule?.byWeekDays}' : "When: $formattedStartDate"}${widget.mapMarker.rule?.byMonths != null ? ' in ${_getMonthNames(widget.mapMarker.rule!.byMonths)}' : ''}",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        ),
                      ),
                    ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomRight, // Adjust the alignment as needed
                          child: GestureDetector(
                            onTap: () {
                              // Handle the tap on the "Read More" text
                              debugPrint('Read More tapped');
                              // Navigate to the EventPage
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Event(
                                    eventName: widget.mapMarker.title,
                                    eventCategory: widget.mapMarker.category,
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Read More...',
                              style: TextStyle(
                                color: MyApp.blueMain,
                                overflow: TextOverflow.clip,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Positioned widget for the image in the foreground
          Positioned(
            top: 18, // Adjust the top position as needed
            left: 18, // Adjust the left position as needed
            child: Image.asset(
              widget.mapMarker.image,
              width: 60,
              height: 60,
            ),
          ),
        ],
      ),
    );
  }
}

class _MyLocationMarker extends StatefulWidget {
  const _MyLocationMarker({Key? key}) : super(key: key);

  @override
  _MyLocationMarkerState createState() => _MyLocationMarkerState();
}

class _MyLocationMarkerState extends State<_MyLocationMarker> {
  bool _isVisible = true;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _isVisible = !_isVisible;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 50,
          width: 50,
          decoration: const BoxDecoration(
            color: Color(0xffb4a8e5),
            shape: BoxShape.circle,
          ),
        ),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: _isVisible ? 1.0 : 0.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Container(
                height: 70,
                width: 70,
                decoration: const BoxDecoration(
                  color: Color(0xff26168C),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }
}

void main() {
  runApp(const MaterialApp(
    home: AnimatedMarkersMap_NEW(),
  ));
}

class YourCustomMarkerWidget extends StatelessWidget {
  final MapMarker marker;
  final bool selected;
  final void Function() onTap;
  final category;

  const YourCustomMarkerWidget({
    Key? key,
    required this.marker,
    required this.selected,
    required this.onTap,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = selected ? MARKER_SIZE_EXPAND : MARKER_SIZE_SHRINK;
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Center(
        child: AnimatedContainer(
          height: size,
          width: size,
          duration: const Duration(milliseconds: 400),
          child: Image.asset(_getMarkers(category)),
        ),
      ),
    );
  }

  String _getMarkers(String category){
    switch (category) {
      case 'Creative':
        return "assets/Marker_creative_noStory.png";
      case 'Sports':
        return"assets/Marker_sports_noStory.png";
      case 'Games':
        return "assets/Marker_gaming_noStory.png";
      case 'Education':
        return "assets/Marker_education_noStory.png";
      case 'Nightlife':
        return "assets/Marker_nightLife_noStory.png";
      case 'Culinary':
        return "assets/Marker_culinary_noStory.png";
      case 'Off Topic':
        return "assets/Marker_offTopic_noStory.png";
      case 'Archives':
        return "assets/Marker_archive_noStory.png";
      default:
        return "assets/Marker_offTopic_noStory.png";
    }
  }
}
