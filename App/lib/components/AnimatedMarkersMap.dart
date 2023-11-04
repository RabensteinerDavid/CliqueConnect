import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/services.dart';

import 'package:latlong2/latlong.dart' as latlong;

import '../shema/MapMarker.dart';

var myCurrentLocation = latlong.LatLng(0, 0);

const MAPBOX_ACCESS_TOKEN = 'sk.eyJ1IjoiYm9uaXRoYW4iLCJhIjoiY2xvaGFydjR1MGV5bDJqbnZ6cWg0dXh4cyJ9.m3uRWclpqOdSgYfUegOlTg';
const MAPBOX_STYLE = 'mapbox://styles/bonithan/cloh3lx0f000d01qoh3okhz10';
const MARKER_COLOR = Color (0xFF3DC5A7);
const MARKER_SIZE_EXPAND = 55.0;
const MARKER_SIZE_SHRINK = 30.0;

class AnimatedMarkersMap extends StatefulWidget {
  const AnimatedMarkersMap({Key? key}) : super(key: key);

  @override
  State<AnimatedMarkersMap> createState() => _LocationPageState();
}

class _LocationPageState extends State<AnimatedMarkersMap> {
  String? _currentAddress;
  Position? _currentPosition;
  MapboxMapController? mapController;
  double iconSize = 0.3;
  int _markerIndex = 0;

  final PageController _pageController = PageController(initialPage: 0);

  bool isCardVisible = false;



  User? user = FirebaseAuth.instance.currentUser;
  final firestore = FirebaseFirestore.instance;

  List<MapMarker> mapMarkers = [
    MapMarker(
      image: 'assets/Marker.png',
      title: 'Your Position',
      address: 'Your adress',
      location: myCurrentLocation, start: Timestamp.now(), end: Timestamp.now(), description: "he",
    ),
    /*  MapMarker(
      image: 'assets/Marker.png',
      title: 'Paavo',
      address: 'Address Paavo 123',
      location: myLocation2,
    ),*/
  ];

  void getPositionActivity() async {
    var userID = user?.uid;

    if (userID != null) {
      Timestamp now = Timestamp.now();
      final activitiesCollectionRef = firestore.collection("activities");

      activitiesCollectionRef.get().then((querySnapshot) {
        querySnapshot.docs.forEach((activityDoc) {
          final activityName = activityDoc.id;

          if(activityName == "volleyball"){
            final locationsCollectionRef = activityDoc.reference.collection("location");

            locationsCollectionRef.get().then((locationQuerySnapshot) {
              locationQuerySnapshot.docs.forEach((doc) {
                final data = doc.data();
                if (data != null) {
                  final description = data["description"];
                  final nameActivity = data["name_activity"];
                  GeoPoint location = data["position"];

                  mapMarkers.add(MapMarker(
                    image: 'assets/Marker.png',
                    title: nameActivity,
                    address: 'Address Paavo 123',
                    location: latlong.LatLng(location.latitude,location.longitude), start: now, end: now, description: description,
                  ));

                } else {
                  print("Field not found in data.");
                }
                print("Aktivität: $activityName, Standortdaten: $data");
              });
            });
          }
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

      markerList.add(
        Marker(
          height: MARKER_SIZE_EXPAND,
          width: MARKER_SIZE_EXPAND,
          point: mapItem.location,
          builder: (_) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  isCardVisible = true; // Show the card section
                  _markerIndex = i;
                });
                print('Selected: ${mapItem.title}');
                if (_pageController.hasClients){
                  _pageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.ease,
                  );
                }
              },
              child: _LocationMarker(selected: _markerIndex == i),
            );
          },
        ),
      );
    }
    return markerList;
  }

  @override
  void initState() {
    super.initState();
    // Fetch initial data
    getPositionActivity();
    _getCurrentPosition();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void onClick(){

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AnimatedMarker"),
        actions: [
          IconButton(onPressed: () => null, icon: Icon(Icons.filter_alt_outlined))
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            child: _currentPosition != null
                ? FlutterMap(
              options: MapOptions(
                onTap: (tapPosition, point){
                  if(tapPosition != Marker){
                    setState(() {
                      isCardVisible = false; // Hide the card section
                    });
                  }
              },
                minZoom: 1,
                maxZoom: 19,
                zoom: 19,
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
                  markers: _buildMarkers(),
                ),
              ],
            ) : const Center(child: CircularProgressIndicator()),
          ),

          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.3,
            child: Visibility(
              visible: isCardVisible,
              child: PageView.builder(
                controller: _pageController,
                itemCount: mapMarkers.length,
                itemBuilder: (context, index) {
                  final item = mapMarkers[index];
                  return _MapItemDetails(
                    mapMarker: item,
                  );
                },
              )
            ),
          )
        ],
      ),
    );
  }
}



class _MapItemDetails extends StatelessWidget {
   const _MapItemDetails( {
    Key? key,
    required this.mapMarker,
  }) : super(key: key);

  final MapMarker mapMarker;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(16.0),
      child: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                mapMarker.image,
                width: 100, // Adjust the width to your needs
                height: 100, // Adjust the height to your needs
              ),
              Text(mapMarker.title),
              Text(mapMarker.description),
              Text(mapMarker.address),
            ],
          ),
        ),
      ),
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
        height: size, width: size,
        duration: const Duration(milliseconds: 400),
        child: Image.asset('assets/Marker.png'),
      ),
      // AnimatedContainer
    );
  }
}