import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

class MapSreenWithCurrentLocation extends StatefulWidget {
  const MapSreenWithCurrentLocation({Key? key}) : super(key: key);

  @override
  State<MapSreenWithCurrentLocation> createState() => _LocationPageState();
}

class _LocationPageState extends State<MapSreenWithCurrentLocation> {
  String? _currentAddress;
  Position? _currentPosition;
  late MapboxMapController mapController;
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
        _getAddressFromLatLng(_currentPosition!);
        _onStyleLoaded(); // Initialize the map once the position is available
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

  void _onStyleLoaded() {
    addImageFromAsset("assetImage", "assets/Marker.png");
  }

  Future<void> addImageFromAsset(String name, String assetName) async {
    final ByteData bytes = await rootBundle.load(assetName);
    final Uint8List list = bytes.buffer.asUint8List();
    mapController.addSymbol(_getSymbolOptions('assets/Marker.png', iconSize));
    return mapController.addImage(name, list);
  }

  SymbolOptions _getSymbolOptions(String iconImage, double size) {
    LatLng geometry = LatLng(
      _currentPosition?.latitude ?? 0,
      _currentPosition?.longitude ?? 0,
    );
    return SymbolOptions(
      geometry: geometry,
      iconImage: iconImage,
      iconSize: size,
    );
  }

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Location Page")),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _currentPosition != null
                  ? MapboxMap(
                onStyleLoadedCallback: _onStyleLoaded,
                accessToken: 'sk.eyJ1IjoiYm9uaXRoYW4iLCJhIjoiY2xvaGFydjR1MGV5bDJqbnZ6cWg0dXh4cyJ9.m3uRWclpqOdSgYfUegOlTg',
                styleString: 'mapbox://styles/bonithan/cloh3lx0f000d01qoh3okhz10',
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  zoom: 15.0,
                ),
                onMapCreated: (controller) {
                  mapController = controller;
                },
                onCameraIdle: () {
                  double? zoom = mapController.cameraPosition?.zoom;
                  if (zoom! >= 12.0) {
                    setState(() {
                      iconSize = 0.5;
                    });
                  } else {
                    setState(() {
                      iconSize = 0.3;
                    });
                  }
                  mapController.removeSymbol('assets/Marker.png' as Symbol);
                  // Add the updated symbol
                  addImageFromAsset('assetImage', 'assets/Marker.png');
                },
              )
                  : Center(child: CircularProgressIndicator()), // Show loading indicator while _currentPosition is null
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LAT: ${_currentPosition?.latitude ?? ""}'),
                  Text('LNG: ${_currentPosition?.longitude ?? ""}'),
                  Text('ADDRESS: ${_currentAddress ?? ""}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
