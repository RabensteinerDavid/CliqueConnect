import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class MapScreen extends StatefulWidget {
  final Position? currentPosition;

  MapScreen({Key? key, this.currentPosition}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapboxMapController mapController;

  double iconSize = 0.3; // Initial icon size

  Future<void> addImageFromAsset(String name, String assetName) async {
    final ByteData bytes = await rootBundle.load(assetName);
    final Uint8List list = bytes.buffer.asUint8List();
    mapController.addSymbol(_getSymbolOptions('assets/Marker.png', iconSize));
    return mapController.addImage(name, list);
  }

  SymbolOptions _getSymbolOptions(String iconImage, double size) {
    LatLng geometry = LatLng(
      widget.currentPosition?.latitude ?? 0,
      widget.currentPosition?.longitude ?? 0,
    );
    return SymbolOptions(
      geometry: geometry,
      iconImage: iconImage,
      iconSize: size,
    );
  }

  void _onStyleLoaded() {
    addImageFromAsset("assetImage", "assets/Marker.png");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Screen'),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height * 2,
        width: MediaQuery.of(context).size.width,
        child: MapboxMap(
          onStyleLoadedCallback: _onStyleLoaded,
          accessToken: 'sk.eyJ1IjoiYm9uaXRoYW4iLCJhIjoiY2xvaGFydjR1MGV5bDJqbnZ6cWg0dXh4cyJ9.m3uRWclpqOdSgYfUegOlTg',
          styleString: 'mapbox://styles/bonithan/cloh3lx0f000d01qoh3okhz10',
          initialCameraPosition: CameraPosition(
            target: LatLng(
              widget.currentPosition?.latitude ?? 0,
              widget.currentPosition?.longitude ?? 0,
            ),
            zoom: 15.0,
          ),
          onMapCreated: (controller) {
            mapController = controller;
          },
          onCameraIdle: () {
            // Retrieve the current zoom level from CameraPosition
            double? zoom = mapController.cameraPosition?.zoom;

            // Adjust icon size based on the zoom level (customize as needed)
            if (zoom! >= 12.0) {
              setState(() {
                iconSize = 0.5; // Set a larger icon size for zoom level >= 12
              });
            } else {
              setState(() {
                iconSize = 0.3; // Set the default icon size for other zoom levels
              });
            }

            // Remove the old symbol
            mapController.removeSymbol('assets/Marker.png' as Symbol);

            // Add the updated symbol
            addImageFromAsset('assetImage', 'assets/Marker.png');
          },
        ),
      ),
    );
  }
}