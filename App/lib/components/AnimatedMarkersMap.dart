import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/services.dart';

import 'package:latlong2/latlong.dart' as latlong;

import '../shema/MapMarker.dart';

var myCurrentLocation = const latlong.LatLng(48.36664, 14.516467);
const myLocation = latlong.LatLng(48.36664, 14.516467);

const myLocation2 = latlong.LatLng(48.36663, 14.516300);

final List<MapMarker> mapMarkers = [
  MapMarker(
    image: 'assets/Marker.png',
    title: 'Marcos',
    address: 'Address Marcos 123',
    location: myCurrentLocation,
  ),
  MapMarker(
    image: 'assets/Marker.png',
    title: 'Paavo',
    address: 'Address Paavo 123',
    location: myLocation2,
  ),
];


const MAPBOX_ACCESS_TOKEN = 'sk.eyJ1IjoiYm9uaXRoYW4iLCJhIjoiY2xvaGFydjR1MGV5bDJqbnZ6cWg0dXh4cyJ9.m3uRWclpqOdSgYfUegOlTg';
const MAPBOX_STYLE = 'mapbox://styles/bonithan/cloh3lx0f000d01qoh3okhz10';
const MARKER_COLOR = Color (0xFF3DC5A7);

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
          point: mapItem.location,
          builder: (_) {
            return GestureDetector(
              onTap: () {
                print('Selected: ${mapItem.title}');
              },
              child: Image.asset("assets/Marker.png"),
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
    _getCurrentPosition();
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
          FlutterMap(
            options: MapOptions(
              minZoom: 5,
              maxZoom: 22,
              zoom: 18,
              center: myCurrentLocation,
            ),
            children: [
              TileLayer(
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
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(46.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LAT: ${_currentPosition?.latitude ?? ""}'),
                  Text('LNG: ${_currentPosition?.longitude ?? ""}'),
                  Text('ADDRESS: ${_currentAddress ?? ""}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}