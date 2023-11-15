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
import 'ProfileView.dart';

// Replace with your Mapbox access token
const MAPBOX_ACCESS_TOKEN = 'sk.eyJ1IjoiYm9uaXRoYW4iLCJhIjoiY2xvaGFydjR1MGV5bDJqbnZ6cWg0dXh4cyJ9.m3uRWclpqOdSgYfUegOlTg';
const MAPBOX_STYLE = 'mapbox://styles/bonithan/cloh3lx0f000d01qoh3okhz10';
const MARKER_COLOR = Color(0xFF3DC5A7);
const MARKER_SIZE_EXPAND = 55.0;
const MARKER_SIZE_SHRINK = 30.0;

final filters = <String>{};
late List<MapMarker> _markers = [];

class AnimatedMarkersMap_NEW extends StatefulWidget {
  const AnimatedMarkersMap_NEW({Key? key}) : super(key: key);

  @override
  State<AnimatedMarkersMap_NEW> createState() => _LocationPageState();
}

class _LocationPageState extends State<AnimatedMarkersMap_NEW> {
  MapController mapController = MapController();

  @override
  void initState() {
    super.initState();
    _updateMarkers();
  }

  void _updateMarkers() async {
    final markers = await getMarkersAsFuture();
    setState(() {
      _markers = markers;
    });
  }

  @override
  void dispose() {
    super.dispose();
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
    _markers.clear();
    final firestore = FirebaseFirestore.instance;
    final userID = user?.uid;

    if (userID != null) {
      final activitiesCollectionRef = firestore.collection("activities");

      final querySnapshot = await activitiesCollectionRef.get();
      final now = Timestamp.now();

      for (final activityDoc in querySnapshot.docs) {
        final activityName = activityDoc.id;
        final Map<String, dynamic> data = activityDoc.data();

        for (final key in data.keys) {
          List<dynamic> alldata = List.from(data[key]);

          final nameActivity = await alldata[0];
          final description = await alldata[1];
          final location = await alldata[4] as GeoPoint;

          var address = await _convertAddressToCoordinates(location);

          var imagePic = 'assets/Marker.png';
          if (nameActivity.toString().contains("Volleyball")) {
            imagePic = 'assets/Volleyball.png';
          }

          // Check if the activityName is in the selected filters
          if (filters.isEmpty || filters.contains(activityName)) {
            _markers.add(
              MapMarker(
                image: imagePic,
                title: nameActivity,
                address: address,
                location: latlong.LatLng(location.latitude, location.longitude),
                start: now,
                end: now,
                description: description,
              ),
            );
          }
        }
      }

      return _markers;
    } else {
      print("User ID is null. Make sure the user is authenticated.");
      return _markers; // Return an empty list if user ID is null
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<Position>(
            stream: Geolocator.getPositionStream(),
            builder: (context, positionSnapshot) {
              if (positionSnapshot.hasData) {
                final userPosition = positionSnapshot.data;
                return FutureBuilder<List<MapMarker>>(
                  future: getMarkersAsFuture(),
                  builder: (context, markersSnapshot) {
                    if (markersSnapshot.connectionState == ConnectionState.done) {
                      List<MapMarker> markers = markersSnapshot.data ?? [];
                      return FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
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
                              ..._markers.map((marker) {
                                return Marker(
                                  point: marker.location,
                                  builder: (BuildContext context) {
                                    return YourCustomMarkerWidget(marker);
                                  },
                                );
                              }).toList(),
                              Marker(
                                point: latlong.LatLng(userPosition.latitude, userPosition.longitude),
                                builder: (_) {
                                  return const _MyLocationMarker();
                                },
                              ),
                            ],
                          ),
                        ],
                      );
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
                  image: AssetImage('assets/cliqueConnect.png'),
                  fit: BoxFit.contain,
                ),
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
  }
}

class FilterChipExample extends StatefulWidget {
  const FilterChipExample({Key? key}) : super(key: key);

  @override
  State<FilterChipExample> createState() => _FilterChipExampleState();
}

class _FilterChipExampleState extends State<FilterChipExample> {
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
                      if (mounted && selected) {
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
    home: AnimatedMarkersMap_NEW(),
  ));
}

class YourCustomMarkerWidget extends StatelessWidget {
  final MapMarker marker;

  const YourCustomMarkerWidget(this.marker, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        height: 45,
        width: 45,
        duration: const Duration(milliseconds: 400),
        child: Image.asset('assets/Marker.png'),
      ),
    );
  }
}

