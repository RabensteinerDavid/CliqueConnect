import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;

import '../main.dart';
import '../shema/MapMarker.dart';

// Replace with your Mapbox access token
const MAPBOX_ACCESS_TOKEN = 'sk.eyJ1IjoiYm9uaXRoYW4iLCJhIjoiY2xvaGFydjR1MGV5bDJqbnZ6cWg0dXh4cyJ9.m3uRWclpqOdSgYfUegOlTg';
const MAPBOX_STYLE = 'mapbox://styles/bonithan/cloh3lx0f000d01qoh3okhz10';
const MARKER_COLOR = Color(0xFF3DC5A7);
const MARKER_SIZE_EXPAND = 55.0;
const MARKER_SIZE_SHRINK = 30.0;

List<MapMarker> mapMarkers = [];
final filters = <String>{};

latlong.LatLng myCurrentLocation = const latlong.LatLng(0, 0);

class AnimatedMarkersMap extends StatefulWidget {
  const AnimatedMarkersMap({Key? key}) : super(key: key);

  @override
  State<AnimatedMarkersMap> createState() => _LocationPageState();
}

class _LocationPageState extends State<AnimatedMarkersMap> {
  Position? _currentPosition;
  double iconSize = 0.3;
  int selectedCardIndex = 0;
  String? _currentAddress;

  final PageController _pageController = PageController(initialPage: 0, keepPage: true);

  bool isCardVisible = false;

  User? user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    getPositionActivity();
    _getCurrentPosition();
    mapMarkers = [];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
    mapMarkers = [];
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

  void getPositionActivity() async {
    final userID = user?.uid;

    if (userID != null) {
      final now = Timestamp.now();
      final activitiesCollectionRef = firestore.collection("activities");

      activitiesCollectionRef.get().then((querySnapshot) {
        querySnapshot.docs.forEach((activityDoc) {
          final activityName = activityDoc.id;

                Map<String, dynamic> data = activityDoc.data();

            data.forEach((key, value) async {
              List<dynamic> alldata = List.from(data[key]);

              final nameActivity = await alldata[0];
              final description = await alldata[1];
              final location = await alldata[4] as GeoPoint;
              final catergory = await alldata[5];

              var address = await _convertAddressToCoordinates(location);

              var imagePic = 'assets/Marker.png';
              if(nameActivity.toString().contains("Volleyball")){
                imagePic = 'assets/Volleyball.png';
              }

              if (filters.contains(activityName)) {
                setState(() {
             /*     mapMarkers.add(
                    MapMarker(
                      image: imagePic,
                      title: nameActivity,
                      address: address,
                      location: latlong.LatLng(
                          location.latitude, location.longitude),
                      start: now,
                      end: now,
                      description: description,
                      category: catergory,
                    ),
                  );*/
                });
              }
            });

        });
      });
    } else {
      print("User ID is null. Make sure the user is authenticated.");
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
        myCurrentLocation = latlong.LatLng(position.latitude, position.longitude);
        _getAddressFromLatLng(_currentPosition!);
      });
    }).catchError((e) {
      debugPrint(e.toString());
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
        _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
        '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
      });
    }).catchError((e) {
      debugPrint(e.toString());
    });
  }


  List<Marker> _buildMarkers() {
    final List<Marker> markerList = [];

    for (int i = 0; i < mapMarkers.length; i++) {
      final mapItem = mapMarkers[i];
      final markerSize = i == selectedCardIndex ? MARKER_SIZE_EXPAND : MARKER_SIZE_SHRINK;

      markerList.add(
        Marker(
          height: markerSize,
          width: markerSize,
          point: mapItem.location,
          builder: (_) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  isCardVisible = true;
                  selectedCardIndex = i; // Update the selected card index
                });
                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.ease,
                  );
                }
              },
              child: _LocationMarker(selected: i == selectedCardIndex),
            );
          },
        ),
      );
    }
    return markerList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            child: _currentPosition != null
                ? FlutterMap(
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
                center: myCurrentLocation,
              ),
              children: [
                TileLayer(
                  maxZoom: 19,
                  urlTemplate:
                  'https://api.mapbox.com/styles/v1/{style_id}/tiles/{z}/{x}/{y}?access_token={access_token}',
                  additionalOptions: const {
                    'style_id': 'bonithan/cloh3lx0f000d01qoh3okhz10',
                    'access_token': MAPBOX_ACCESS_TOKEN,
                  },
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: latlong.LatLng(_currentPosition!.latitude,
                          _currentPosition!.longitude),
                      builder: (_) {
                        return const _MyLocationMarker();
                      },
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: _buildMarkers(),
                ),
              ],
            )
                : const Center(child: CircularProgressIndicator()),
          ),

          // New Header Design
          Container(
            height: MediaQuery
                .of(context)
                .size
                .height * 0.18,
            color: MyApp.blueMain,
          ),
          Positioned(
            top: MediaQuery
                .of(context)
                .size
                .height * 0.07,
            left: MediaQuery
                .of(context)
                .size
                .width * 0.08,
            right: MediaQuery
                .of(context)
                .size
                .width * 0.1,
            child: Container(
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.08,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/cliqueConnect.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            height: MediaQuery
                .of(context)
                .size
                .height * 0.3,
            child: Visibility(
              visible: isCardVisible,
              child: PageView.builder(
                controller: _pageController,
                itemCount: mapMarkers.length,
                itemBuilder: (context, index) {
                  final item = mapMarkers[index];
                  return _MapItemDetails(
                    mapMarker: item,
                    currentIndex: index,
                    pageController: _pageController,
                    onCardSwiped: (int index) {
                      setState(() {
                        selectedCardIndex =
                            index; // Update the selected card index
                      });
                    },
                  );
                },
              ),
            ),
          ),

          const Positioned(
            top: 160,
            left: 10,
            right: 10,
            child: Opacity(
              opacity: 0.7,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: FilterChipExample(),
              ),
            ),
          ),
        ],
      ),
    );
  }}

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

  @override
  Widget build(BuildContext context) {
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
          } else if (_offset < 0 && widget.currentIndex < mapMarkers.length - 1) {
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

      child:
      Stack(
        children: [
          // Positioned widget for the Card
          Positioned(
            child: Card(
              color: Colors.white,
              margin: const EdgeInsets.all(50.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0.0), // Set the radius to 0 for sharp corners
              ),
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(35.0, 20.0, 10.0, 20.0), // Add left padding of 10
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.mapMarker.title,
                        style: const TextStyle(
                          fontSize: 34, // Adjust the font size as needed
                          fontWeight: FontWeight.bold, // You can adjust the font weight as well
                        ),
                      ),
                      Text(widget.mapMarker.description),
                      Text("Address: ${widget.mapMarker.address}"),
                     /* Text('Current Index: ${widget.currentIndex}'),*/
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
              width: 70,
              height: 70,
            ),
          ),
        ],
      )
    );
  }
}

class _LocationMarker extends StatelessWidget {
  const _LocationMarker({Key? key, this.selected = false}) : super(key: key);
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final size = selected ? MARKER_SIZE_EXPAND : MARKER_SIZE_SHRINK;
    return Center(
      child: AnimatedContainer(
        height: size,
        width: size,
        duration: const Duration(milliseconds: 400),
        child: Image.asset('assets/Marker.png'),
      ),
    );
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
                const SizedBox(width: 4.0), // Add the desired spacing here
              ],
            );
          }).toList(),
        );
      },
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
    home: AnimatedMarkersMap(),
  ));
}